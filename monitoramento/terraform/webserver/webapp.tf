resource "aws_security_group" "aws_sg_webapp" {
name = "security group webapp"

ingress {
description = "SSH from the internet"
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["170.83.152.200/32"]
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

ami = "ami-07d02ee1eeb0c996c"
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.aws_sg_webapp.id]
associate_public_ip_address = true
key_name = "alexos"


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
