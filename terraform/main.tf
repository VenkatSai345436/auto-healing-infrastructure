provider "aws" {
  region = var.aws_region
}

module "iam" {
  source = "./modules/iam"
}

module "sns" {
  source       = "./modules/sns"
  slack_webhook = var.slack_webhook_url
}

module "ec2" {
  source               = "./modules/ec2"
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = module.iam.ec2_instance_profile
}

module "cloudwatch" {
  source      = "./modules/cloudwatch"
  instance_id = module.ec2.instance_id
  sns_arn     = module.sns.topic_arn
}

module "lambda" {
  source         = "./modules/lambda"
  lambda_role_arn = module.iam.lambda_role_arn
  instance_id    = module.ec2.instance_id
  sns_arn        = module.sns.topic_arn
}
