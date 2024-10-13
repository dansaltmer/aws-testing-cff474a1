# subnet for the document db to sit in
resource "aws_subnet" "subnet1" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = var.subnet_cidrs[0]

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-document-db-1"
  })
}

resource "aws_subnet" "subnet2" {
  vpc_id            = var.vpc_id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = var.subnet_cidrs[1]

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-document-db-2"
  })
}

resource "random_uuid" "password" {}

resource "aws_docdbelastic_cluster" "db" {
  name           = "${var.tags.Name}-document-db"
  subnet_ids     = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  shard_count    = 2
  shard_capacity = 2

  auth_type = "PLAIN_TEXT"


  admin_user_name     = "docdbadmin"
  admin_user_password = random_uuid.password.result

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-document-db"
  })
}
