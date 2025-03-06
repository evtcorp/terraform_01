# modules/compute/ec2-instance/main.tf

resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  key_name               = var.key_name
  
  iam_instance_profile   = var.create_iam_profile ? aws_iam_instance_profile.this[0].name : var.iam_instance_profile

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    delete_on_termination = var.root_volume_delete_on_termination
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
  }

  user_data = var.user_data

  tags = merge(
    {
      Name = var.name
    },
    var.tags
  )

  volume_tags = merge(
    {
      Name = var.name
    },
    var.volume_tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "this" {
  count    = var.create_eip ? 1 : 0
  instance = aws_instance.this.id
  domain   = "vpc"
  
  tags = merge(
    {
      Name = "${var.name}-eip"
    },
    var.tags
  )
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_profile ? 1 : 0
  name  = "${var.name}-instance-profile"
  role  = aws_iam_role.this[0].name
}

resource "aws_iam_role" "this" {
  count = var.create_iam_profile ? 1 : 0
  name  = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.name}-role"
    },
    var.tags
  )
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_iam_profile && var.enable_ssm ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Monitoring setup
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  count               = var.enable_monitoring ? 1 : 0
  alarm_name          = "${var.name}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This metric monitors ec2 status checks"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  dimensions = {
    InstanceId = aws_instance.this.id
  }
}

# modules/compute/ec2-instance/variables.tf

variable "name" {
  description = "Name to be used on EC2 instance created"
  type        = string
}

variable "ami" {
  description = "ID of AMI to use for the instance"
  type        = string
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "The VPC Subnet ID to launch in"
  type        = string
}

variable "security_group_ids" {
  description = "A list of security group IDs to associate with"
  type        = list(string)
  default     = []
}

variable "key_name" {
  description = "Key name of the Key Pair to use for the instance"
  type        = string
  default     = null
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = null
}

variable "root_volume_type" {
  description = "Type of root volume. Can be standard, gp2, gp3, io1, io2, sc1 or st1"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Size of the root volume in gigabytes"
  type        = number
  default     = 20
}

variable "root_volume_encrypted" {
  description = "Whether to encrypt the root volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "Amazon Resource Name (ARN) of the KMS Key to use when encrypting the volume"
  type        = string
  default     = null
}

variable "root_volume_delete_on_termination" {
  description = "Whether the volume should be destroyed on instance termination"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "volume_tags" {
  description = "A mapping of tags to assign to the volumes"
  type        = map(string)
  default     = {}
}

variable "create_eip" {
  description = "Whether to create an Elastic IP for the instance"
  type        = bool
  default     = false
}

variable "create_iam_profile" {
  description = "Whether to create an IAM profile for the instance"
  type        = bool
  default     = false
}

variable "iam_instance_profile" {
  description = "IAM Instance Profile to launch the instance with"
  type        = string
  default     = null
}

variable "enable_ssm" {
  description = "Whether to enable SSM for the instance"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Whether to enable detailed monitoring and CloudWatch alarms"
  type        = bool
  default     = false
}

variable "cpu_high_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm state changes (e.g. SNS topics)"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm state returns to OK"
  type        = list(string)
  default     = []
}

# modules/compute/ec2-instance/outputs.tf

output "id" {
  description = "The ID of the instance"
  value       = aws_instance.this.id
}

output "arn" {
  description = "The ARN of the instance"
  value       = aws_instance.this.arn
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "The private IP address assigned to the instance"
  value       = aws_instance.this.private_ip
}

output "elastic_ip" {
  description = "The Elastic IP address assigned to the instance, if created"
  value       = var.create_eip ? aws_eip.this[0].public_ip : null
}

output "instance_state" {
  description = "The state of the instance"
  value       = aws_instance.this.instance_state
}

output "iam_role_name" {
  description = "The name of the IAM role attached to the instance"
  value       = var.create_iam_profile ? aws_iam_role.this[0].name : null
}

output "iam_role_arn" {
  description = "The ARN of the IAM role attached to the instance"
  value       = var.create_iam_profile ? aws_iam_role.this[0].arn : null
}

output "security_groups" {
  description = "List of security groups associated with the instance"
  value       = aws_instance.this.security_groups
}

# modules/compute/ec2-instance/versions.tf

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}
