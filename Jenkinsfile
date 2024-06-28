def COLOR_MAP = [
    'SUCCESS': 'good',
    'FAILURE': 'danger',
    'UNSTABLE': 'warning',
    'ABORTED': '#808080'
    ]

pipeline {
    agent any
    tools {
        jdk 'openjdk17'
        nodejs 'node16'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "reddit-clone-pipeline"
        RELEASE = "1.0.0"
        DOCKER_USER = "andynze4"
        DOCKER_PASS = 'dockerhub'
        IMAGE_NAME = "${DOCKER_USER}/${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
//        JENKINS_API_TOKEN = credentials("JENKINS_API_TOKEN")
        RELEASE_REPO = 'reddit-clone-release'
        CENTRAL_REPO = 'reddit-clone-maven-central'
        NEXUSIP = '172.16.226.100'
        NEXUSPORT = '8081'
        NEXUS_GRP_REPO = 'reddit-clone-maven-group'
        NEXUS_LOGIN = 'nexuslogin'
        NEXUS_PROTOCOL = 'http'
        NEXUS_URL = 'http://172.16.226.100:8081'
        NEXUS_REPOGRP_ID = 'QA'
        NEXUS_VERSION = 'nexus3'
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
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-jenkins-token'
                }
            }
        }
        stage ('Publish to Nexus Repository Manager') {
            steps {
                nexusArtifactUploader (
                    nexusVersion: "${NEXUS_VERSION}",
                    protocol: "${NEXUS_PROTOCOL}",
                    nexusUrl: "${NEXUSIP}:${NEXUSPORT}",
                    groupId: "${NEXUS_REPOGRP_ID}",
                    version: "${env.BUILD_ID}-${env.BUILD_TIMESTAMP}",
                    repository: "${RELEASE_REPO}",
                    credentialsId: "${NEXUS_LOGIN}",
                    artifacts: [
                        [
                            artifactId: 'webapp',
                            classifier: '',
                            file: 'target/webapp.war',
                            type: 'war'
                        ]
                    ]
                )
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
                    docker.withRegistry('', DOCKER_PASS) {
                        def docker_image = docker.build("${IMAGE_NAME}")
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
                sh '''
                docker rmi ${IMAGE_NAME}:${IMAGE_TAG}
                docker rmi ${IMAGE_NAME}:latest
                '''
            }
        }
        // Uncomment and configure the following stage if needed
        /*
        stage("Trigger CD Pipeline") {
            steps {
                sh '''
                curl -v -k --user clouduser:${JENKINS_API_TOKEN} -X POST \
                -H 'cache-control: no-cache' -H 'content-type: application/x-www-form-urlencoded' \
                --data 'IMAGE_TAG=${IMAGE_TAG}' \
                'ec2-65-2-187-142.ap-south-1.compute.amazonaws.com:8080/job/Reddit-Clone-CD/buildWithParameters?token=gitops-token'
                '''
            }
        }
        */
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
        }
    }
}
