resource "aws_security_group" "aws_sg_webapp" {
name = "security group webapp"

ingress {
description = "SSH from the internet"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description = "HTTP from the internet"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}

}

resource "aws_instance" "webapp" {

ami = "ami-0fec2c2e2017f4e7b"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.aws_sg_webapp.id]
associate_public_ip_address = true
key_name = "INFORM YOUR KEY"

# Login to the ec2-user with the aws key.
connection {
type        = "ssh"
user        = "admin"
private_key = file("INFORM THE PTH OF THE FILE .PEM") #EXAMPLE file("/home/user/key.pem")
host        = aws_instance.webapp.public_dns
}

# Copy in the bash script we want to execute.
provisioner "file" {
source      = "create_ansible_user.sh"
destination = "/tmp/create_ansible_user.sh"
}

# Change permissions on bash script and execute from ec2-user.
provisioner "remote-exec" {
inline = [
"chmod +x /tmp/create_ansible_user.sh",
"sudo /tmp/create_ansible_user.sh",
    ]
}

tags = {
Name = "Web Server"
}

}

output "instance_ip_webapp" {
value = aws_instance.webapp.public_ip
}

output "instance_public_dns_webapp" {
value = aws_instance.webapp.public_dns
}
