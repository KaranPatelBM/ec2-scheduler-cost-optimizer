data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "dev_ec2" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  root_block_device {
    volume_size           = var.volume_size
    //delete_on_termination = false  # Keeps the EBS volume even if instance is terminated
  }

  tags = {
    Name                    = "dev-instance"
    "${var.managed_tag_key}" = var.managed_tag_value
  }
}
