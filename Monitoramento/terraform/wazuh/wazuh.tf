resource "aws_security_group" "aws_sg_wazuh" {
name = "security group wazuh"

ingress {
description = "SSH from the MyIP"
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

ingress {
description = "HTTPS from the internet"
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description = "Wazuh Agent"
from_port = 1514
to_port = 1514
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

ingress {
description = "Wazuh Agent"
from_port = 1515
to_port = 1515
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

resource "aws_instance" "wazuh" {

ami = "ami-0fec2c2e2017f4e7b"
instance_type = "t2.medium"
vpc_security_group_ids = [aws_security_group.aws_sg_wazuh.id]
associate_public_ip_address = true
key_name = "INFORM YOUR KEY"

# Login to the ec2-user with the aws key.
connection {
type        = "ssh"
user        = "admin"
private_key = file("INFORM THE PATH OF THE FILE .PEM") #EXAMPLE file("/home/user/key.pem")
host        = aws_instance.wazuh.public_dns 
}

tags = {
Name = "Wazuh"
}

}

output "instance_ip_wazuh" {
value = aws_instance.wazuh.public_ip
}

output "instance_public_dns_wazuh" {
value = aws_instance.wazuh.public_dns
}
