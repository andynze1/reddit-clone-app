output "build_server_ip" {
  description = "The IP of the Build Server."
  value = aws_instance.web.public_ip
}