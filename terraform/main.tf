module "vpc-with-vpn" {
  source = "./modules/vpc-with-vpn"

  vpc_cidr        = "10.120.0.0/16"
  vpn_subnet_cidr = "10.120.248.0/24"
  vpn_client_cidr = "10.121.0.0/22"

  vpn_client_provider_arn    = var.vpn_client_provider_arn
  vpn_selfserve_provider_arn = var.vpn_selfserve_provider_arn

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

module "private_document_db" {
  source = "./modules/private-document-db"

  vpc_id       = module.vpc-with-vpn.vpc_id
  subnet_cidrs = ["10.120.100.0/24", "10.120.101.0/24"]

  tags = {
    Name    = var.project_name
    Project = var.project_name
  }
}

# subnets for the lambda functions to use
resource "aws_subnet" "subnet1" {
  vpc_id            = module.vpc-with-vpn.vpc_id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.120.50.0/24"

  tags = {
    Name    = "${var.project_name}-lambda-1"
    Project = var.project_name
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id            = module.vpc-with-vpn.vpc_id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.120.51.0/24"

  tags = {
    Name    = "${var.project_name}-lambda-2"
    Project = var.project_name
  }
}

resource "aws_security_group" "lambda" {
  name   = "lambda-access-sg"
  vpc_id = module.vpc-with-vpn.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "7.14.0"

  function_name = "${var.project_name}-api-search"
  handler       = "Search"
  description   = "Search API Lambda Host"
  runtime       = "dotnet8"
  publish       = true
  architectures = ["arm64"]

  vpc_subnet_ids         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  vpc_security_group_ids = [aws_security_group.lambda.id]

  # build the dotnet function
  source_path = [{
    path = "../functions/Search/src/Search/publish",
    commands = [
      "cd ..",
      "dotnet restore",
      "dotnet publish -c Release -r linux-arm64 -o publish",
      "cd ./publish",
      ":zip"
    ]
  }]

  # Policies
  attach_policy            = true
  policy                   = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  attach_policy_statements = true
  policy_statements = {
    cloud_watch = {
      effect    = "Allow",
      actions   = ["cloudwatch:PutMetricData"],
      resources = ["*"]
    }
  }

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.api_execution_arn}/*/*"
    }
  }

  tags = {
    Name    = "${var.project_name}-api-search"
    Project = var.project_name
  }
}

resource "aws_subnet" "public1" {
  vpc_id            = module.vpc-with-vpn.vpc_id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = "10.120.10.0/24"

  tags = {
    Name    = "${var.project_name}-api-gatway-1"
    Project = var.project_name
  }
}

resource "aws_subnet" "public2" {
  vpc_id            = module.vpc-with-vpn.vpc_id
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block        = "10.120.11.0/24"

  tags = {
    Name    = "${var.project_name}-api-gatway-2"
    Project = var.project_name
  }
}

resource "aws_security_group" "api_gateway" {
  name   = "api-gateway-sg"
  vpc_id = module.vpc-with-vpn.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      aws_subnet.subnet1.cidr_block,
      aws_subnet.subnet2.cidr_block
    ]
  }
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.project_name}-api"
  description   = "gateway to expose the lambdas"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  hosted_zone_name = var.domain_zone_name
  domain_name      = var.domain_name

  vpc_links = {
    internal-vnet = {
      name               = "${var.project_name}-api-gateway-link"
      security_group_ids = [aws_security_group.api_gateway.id]
      subnet_ids         = [aws_subnet.public1.id, aws_subnet.public2.id]
    }
  }

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 7
    format = jsonencode({
      context = {
        domainName              = "$context.domainName"
        integrationErrorMessage = "$context.integrationErrorMessage"
        protocol                = "$context.protocol"
        requestId               = "$context.requestId"
        requestTime             = "$context.requestTime"
        responseLength          = "$context.responseLength"
        routeKey                = "$context.routeKey"
        stage                   = "$context.stage"
        status                  = "$context.status"
        error = {
          message      = "$context.error.message"
          responseType = "$context.error.responseType"
        }
        identity = {
          sourceIP = "$context.identity.sourceIp"
        }
        integration = {
          error             = "$context.integration.error"
          integrationStatus = "$context.integration.integrationStatus"
        }
      }
    })
  }

  routes = {
    "$default" = {
      integration = {
        uri = "${module.lambda.lambda_function_arn}"
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-api"
    Project = var.project_name
  }
}
