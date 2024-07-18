resource "aws_instance" "web" {
  ami                    = "ami-0e001c9271cf7f3b9"
  instance_type          = "t2.large"
  key_name               = aws_key_pair.linux-keypair.key_name
  vpc_security_group_ids = [aws_security_group.Jenkins-VM-SG.id]
  user_data              = templatefile("./install.sh", {})

  tags = {
    Name = "Jenkins-SonarQube"
  }
  root_block_device {
    volume_size = 40
  }
}

resource "aws_security_group" "Jenkins-VM-SG" {
  name        = "Jenkins-VM-SG"
  description = "Allow TLS inbound traffic"

  ingress = [
    for port in [22, 80, 443, 3000, 9000, 8080, 8081] : {
      description      = "inbound rules"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Jenkins-VM-SG"
  }
}
# Create SSH RSA key of size 4096 bits
resource "tls_private_key" "linux-keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair using the public key
resource "aws_key_pair" "linux-keypair" {
  key_name   = "linux-keypair"
  public_key = tls_private_key.linux-keypair.public_key_openssh
}

# Copy ssh key to local
resource "local_file" "linux-pem-key" {
  content         = tls_private_key.linux-keypair.private_key_pem
  filename        = "linux-keypair.pem"
  file_permission = "0400"
  depends_on      = [tls_private_key.linux-keypair]
}
