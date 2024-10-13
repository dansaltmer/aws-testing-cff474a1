module "vpc-with-vpn" {
  source = "./modules/vpc-with-vpn"

  vpc_cidr        = "10.120.0.0/16"
  vpn_subnet_cidr = "10.120.248.0/24"
  vpn_client_cidr = "10.121.0.0/22"

  vpn_client_provider_arn    = "arn:aws:iam::418272777215:saml-provider/vpn-client"
  vpn_selfserve_provider_arn = "arn:aws:iam::418272777215:saml-provider/vpn-self-service"

  tags = {
    Name    = "aws-testing-cff474a1"
    Project = "aws-testing-cff474a1"
  }
}

module "private_document_db" {
  source = "./modules/private-document-db"

  vpc_id       = module.vpc-with-vpn.vpc_id
  subnet_cidrs = ["10.120.100.0/24", "10.120.101.0/24"]

  tags = {
    Name    = "aws-testing-cff474a1"
    Project = "aws-testing-cff474a1"
  }
}

