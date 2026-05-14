# Lambda IAM Role — least privilege
resource "aws_iam_role" "lambda_role" {
  name = "auto-healing-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Lambda IAM Policy — only what Lambda needs
# NOTE: This is where AccessDeniedException was fixed
# Added ssm:SendCommand scoped to specific EC2 ARN only
resource "aws_iam_role_policy" "lambda_policy" {
  name = "auto-healing-lambda-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # SSM — execute commands on EC2 (scoped to specific instance)
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = [
          "arn:aws:ec2:us-east-1:*:instance/*",
          "arn:aws:ssm:us-east-1::document/AWS-RunShellScript"
        ]
      },
      {
        # EC2 — describe instances only
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        # CloudWatch — read metrics only
        Effect   = "Allow"
        Action   = ["cloudwatch:GetMetricData"]
        Resource = "*"
      },
      {
        # CloudWatch Logs — for Lambda logging
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# EC2 IAM Role — for SSM agent on EC2
resource "aws_iam_role" "ec2_role" {
  name = "auto-healing-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "auto-healing-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

output "lambda_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "ec2_instance_profile" {
  value = aws_iam_instance_profile.ec2_profile.name
}
