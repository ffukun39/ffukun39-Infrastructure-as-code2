# AWS設定
provider "aws" {
  region   = var.aws["region"]
  access_key = ""
  secret_key = ""
}



# VPC
resource "aws_vpc" "of_terraform_handson_on_docker" {
  cidr_block = var.vpc_cider
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = var.vpc_name
  }
}

# パブリックサブネット1aの定義
resource "aws_subnet" "of_public_1a" {
  cidr_block = "10.0.20.0/24"
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  availability_zone = var.az_names["1a"]
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_1a_name
  }
  timeouts {
    delete =  "5m"
  }
}

# パブリックサブネット1cの定義
resource "aws_subnet" "of_public_1c" {
  cidr_block = "10.0.0.0/24"
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  availability_zone = var.az_names["1c"]
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_1c_name
  }
  timeouts {
    delete =  "5m"
  }
}

# プライベートサブネット1cの定義
resource "aws_subnet" "of_praivate_1c" {
  cidr_block = "10.0.10.0/24"
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  availability_zone = var.az_names["1c"]
  map_public_ip_on_launch = true
  tags = {
    Name = var.praivate_subnet_1c_name
  }
  timeouts {
    delete =  "5m"
  }
}
# インターネットゲートウェイの定義
resource "aws_internet_gateway" "of_public" {
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  tags = {
    Name = var.igw_name
  }
}

# ルートテーブルの定義
resource "aws_route_table" "of_public" {
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.of_public.id
  }
  tags = {
    Name = var.route_table_name
  }
}

# ルートテーブルとサブネットの紐付け
resource "aws_route_table_association" "of_public_1a" {
  route_table_id = aws_route_table.of_public.id
  subnet_id = aws_subnet.of_public_1a.id
}


# EC2インスタンスの作成
resource "aws_instance" "of_public" {
  ami = var.instance_ami_id
  instance_type = var.instance_type
  key_name = var.key_pair
  subnet_id = aws_subnet.of_public_1a.id
  vpc_security_group_ids = [
    aws_security_group.of_terraform_handson_on_docker.id
  ]
  associate_public_ip_address = "true"
  root_block_device {
    volume_type =  var.root_volume_type
    volume_size = "20" # root_block内なので、一旦20で固定
  }
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = var.root_volume_type
    volume_size = var.root_volume_size
  }
  tags = {
    Name = var.instance_name
  }
}


#S3バケットの作成
resource "aws_s3_bucket" "b" {
  bucket = "happy-my-tf-test-bucket"
  acl    = "private"

  tags = {
    Name        = "Teraa_form_sample"
    Environment = "Dev"
  }
}
#RDSの作成

resource "aws_db_subnet_group" "main" {
  name        = "tf_dbsubnet"
  description = "It is a DB subnet group on tf_vpc."
  subnet_ids = [aws_subnet.of_praivate_1c.id,aws_subnet.of_public_1a.id,]
  tags = {
    Name = "tff_dbsubnet"
  }
}


resource "aws_db_instance" "db" {
  allocated_storage       = 5
  engine                  = "postgres"
  engine_version          = "11.5"
  instance_class          = "db.t2.micro"
  storage_type            = "gp2"
  username                = var.aws_db_username
  password                = var.aws_db_password
  backup_retention_period = 1
  vpc_security_group_ids  = [aws_security_group.db.id]
  db_subnet_group_name    = aws_db_subnet_group.main.name
}

resource "aws_security_group" "db" {
  name        = "db_server"
  description = "It is a security group on db of tf_vpc."
  vpc_id      = aws_vpc.of_terraform_handson_on_docker.id
  tags = {
    Name = "tf_db"
  }
}


# セキュリティグループの定義
resource "aws_security_group" "of_terraform_handson_on_docker" {
  name = var.sg_name
  vpc_id = aws_vpc.of_terraform_handson_on_docker.id
  description = "Define of SG for public"
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = var.cidr_blocks
  }
  tags = {
    Name = var.sg_name
  }
}

# セキュリティグループルール(SSHのインバウンド)の定義
resource "aws_security_group_rule" "of_ssh_ingress" {
  type = "ingress"
  from_port = var.ssh_port
  protocol = "tcp"
  security_group_id = aws_security_group.of_terraform_handson_on_docker.id
  to_port = var.ssh_port
  cidr_blocks = var.cidr_blocks
  description = "ssh inbound of SG for public"
}

# セキュリティグループルール(HTTPのインバウンド)の定義
resource "aws_security_group_rule" "of_http_ingress" {
  type = "ingress"
  from_port = 80
  protocol = "tcp"
  security_group_id = aws_security_group.of_terraform_handson_on_docker.id
  to_port = 80
  cidr_blocks = var.cidr_blocks
  description = "ssh inbound of SG for public"
}
# セキュリティグループルールRDSの定義
resource "aws_security_group_rule" "db" {
  type = "ingress"
  from_port = 5432
  to_port = 5432
  protocol = "tcp"
  source_security_group_id = aws_security_group.of_terraform_handson_on_docker.id
  security_group_id = aws_security_group.db.id
}


resource "aws_eip" "web" {
  instance = aws_instance.of_public.id
  vpc      = true
}

output "elastic_ip_of_web" {
  value = aws_eip.web.public_ip
}