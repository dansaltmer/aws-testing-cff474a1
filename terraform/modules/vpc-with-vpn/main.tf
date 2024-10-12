resource "random_uuid" "default_name" {}

locals {
  name = coalesce(var.tags.Name, "${random_uuid.default_name.result}")
}

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc-cidr

  tags = merge(var.tags, {
    Name = "${local.name}-vpc"
  })
}

# Need a validated cert for the server
resource "aws_acm_certificate" "vpn" {
  domain_name       = "aws-vpn-testing.rak.gg"
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${local.name}-acm-host"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "vpn" {
  certificate_arn = aws_acm_certificate.vpn.arn

  timeouts {
    create = "1m"
  }
}

# Create the endpoint itself
resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description            = "test vpn client endpoint"
  client_cidr_block      = var.vpn-client-cidr
  split_tunnel           = true
  server_certificate_arn = aws_acm_certificate_validation.vpn.certificate_arn

  # Pre configured applications in IAM, following
  # https://aws.amazon.com/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/
  authentication_options {
    type                           = "federated-authentication"
    saml_provider_arn              = var.vpn-client-provider-arn
    self_service_saml_provider_arn = var.vpn-selfserve-provider-arn
  }

  connection_log_options {
    enabled = false
  }

  tags = merge(var.tags, {
    Name = "${local.name}-client-vpn"
  })
}

# client vpn subnet
resource "aws_subnet" "client-vpn" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = var.vpn-subnet-cidr

  tags = merge(var.tags, {
    Name = "${local.name}-client-vpn-subnet"
  })
}

# associated client vpn subnet and endpoint
resource "aws_ec2_client_vpn_network_association" "vpn-subnets" {
  subnet_id              = aws_subnet.client-vpn.id
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

# Allow vpn access to whole network
resource "aws_ec2_client_vpn_authorization_rule" "vpn-auth-rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = aws_vpc.vpc.cidr_block
  authorize_all_groups   = true
}
