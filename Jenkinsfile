def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
    'UNSTABLE': 'warning',
    'ABORTED': '#808080'
    ]

pipeline {
    agent any
    tools {
        jdk 'jdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "reddit-clone-app"
        RELEASE = "1.0.0"
        DOCKER_USER = "andynze4"
        DOCKER_PASS = 'dockerhub'
        IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
//        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
    }
    stages {
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'master', url: 'https://github.com/andynze1/reddit-clone-resources.git'
            }
        }
        stage("Sonarqube Analysis") {
            steps {
                withSonarQubeEnv('SonarQube-Server') {
                    sh '''
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=Reddit-Clone-CI \
                    -Dsonar.projectKey=Reddit-Clone-CI
                    '''
                }
            }
        }
        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonartoken'
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                sh "npm install"
            }
        }
        stage('TRIVY FS Scan') {
            steps {
                sh "trivy fs . > trivyfs.txt"
            }
        }
        stage("Build & Push Docker Image") {
            steps {
                script {
                    docker.withRegistry('',DOCKER_PASS) {
                         docker_image = docker.build "${IMAGE_NAME}"
                     }
                     docker.withRegistry('',DOCKER_PASS) {
                         docker_image.push("${IMAGE_TAG}")
                         docker_image.push('latest')
                    }
                }
            }
        }
        stage("Trivy Image Scan") {
            steps {
                sh '''
                docker run -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image \
                ${IMAGE_NAME}:latest --no-progress --scanners vuln --exit-code 0 \
                --severity HIGH,CRITICAL --format table > trivyimage.txt
                '''
            }
        }
        stage ('Cleanup Artifacts') {
            steps {
                sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker rmi ${IMAGE_NAME}:latest"
            }
        }
        // Uncomment and configure the following stage if needed

        // stage("Trigger CD Pipeline") {
        //     steps {
        //         sh "curl -v -k --user admin:${JENKINS_API_TOKEN} -X POST -H 'cache-control: no-cache' -H 'content-type: application/x-www-form-urlencoded' --data 'IMAGE_TAG=${IMAGE_TAG}' 'ec2-34-234-74-159.compute-1.amazonaws.com:8080/job/Reddit-Clone-CD/buildWithParameters?token=gitops-token'"
        //     }
        // }

    }
    post {
        always {
            script {
                def color = COLOR_MAP.get(currentBuild.currentResult, '#808080') // Default to gray if result not in map
                echo 'Slack Notification.'
                slackSend (
                    channel: '#jenkinscicd',
                    color: color,
                    message: "*${currentBuild.currentResult}:* Job ${env.JOB_NAME} build ${env.BUILD_NUMBER} \nMore info at: ${env.BUILD_URL}"
                )
            }
            // emailext attachLog: true,
            //    subject: "'${currentBuild.result}'",
            //    body: "Project: ${env.JOB_NAME}<br/>" +
            //        "Build Number: ${env.BUILD_NUMBER}<br/>" +
            //        "URL: ${env.BUILD_URL}<br/>",
            //    to: 'andy.nze3@gmail.com',                              
            //    attachmentsPattern: 'trivyfs.txt,trivyimage.txt'
        }
    }
}  
