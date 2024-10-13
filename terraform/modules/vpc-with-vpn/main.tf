resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-vpc"
  })
}

# See if we can do this with a cert without domain validation
resource "aws_acm_certificate" "vpn" {
  domain_name       = "aws-vpn-testing.rak.gg"
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-acm-host"
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
  client_cidr_block      = var.vpn_client_cidr
  split_tunnel           = true
  server_certificate_arn = aws_acm_certificate_validation.vpn.certificate_arn

  # Pre configured applications in IAM, following
  # https://aws.amazon.com/blogs/security/authenticate-aws-client-vpn-users-with-aws-single-sign-on/
  authentication_options {
    type                           = "federated-authentication"
    saml_provider_arn              = var.vpn_client_provider_arn
    self_service_saml_provider_arn = var.vpn_selfserve_provider_arn
  }

  connection_log_options {
    enabled = false
  }

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-client-vpn"
  })
}

# client vpn subnet
resource "aws_subnet" "vpn" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = var.vpn_subnet_cidr

  tags = merge(var.tags, {
    Name = "${var.tags.Name}-client-vpn-subnet"
  })
}

# associated client vpn subnet and endpoint
resource "aws_ec2_client_vpn_network_association" "vpn" {
  subnet_id              = aws_subnet.vpn.id
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id

  lifecycle {
    ignore_changes = [subnet_id]
  }
}

# Allow vpn access to whole network
resource "aws_ec2_client_vpn_authorization_rule" "vpn" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr    = aws_vpc.vpc.cidr_block
  authorize_all_groups   = true
}
