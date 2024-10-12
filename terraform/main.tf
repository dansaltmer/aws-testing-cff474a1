module "vpc-with-vpn" {
  source = "./modules/vpc-with-vpn"

  vpc-cidr = "10.120.0.0/16"
  vpn-subnet-cidr = "10.120.248.0/24"
  vpn-client-cidr = "10.121.0.0/22"

  vpn-client-provider-arn = "arn:aws:iam::418272777215:saml-provider/vpn-client"
  vpn-selfserve-provider-arn = "arn:aws:iam::418272777215:saml-provider/vpn-self-service"

  tags = {
    Name = "aws-testing-cff474a1"
    Project = "aws-testing-cff474a1"
  }
}
