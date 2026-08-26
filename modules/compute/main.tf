resource "aws_key_pair" "deployer" {
  key_name   = "terraform-project-key"
  public_key = file(var.public_key_path)

  tags = {
    Project     = var.project_tag
    Environment = var.environment
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = aws_key_pair.deployer.key_name

  tags = {
    Name        = "terraform-project-instance"
    Project     = var.project_tag
    Environment = var.environment
  }
}
