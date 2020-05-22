# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# LOCAL VARIABLES USED IN MULTIPLE PLACES
# ---------------------------------------------------------------------------------------------------------------------

locals {
  ecs_cluster = var.ecs_cluster == null ? "default" : var.ecs_cluster
}


# ---------------------------------------------------------------------------------------------------------------------
# AUTOMATICALLY LOOK UP THE LATEST ECS OPTIMISED AMI
# ---------------------------------------------------------------------------------------------------------------------

data "aws_ami" "ecs_optimised" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "is-public"
    values = ["true"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN AUTO SCALING GROUP (ASG) IN WHICH TO RUN ECS CONTAINER INSTANCES
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "autoscaling_group" {
  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  name_prefix         = "${var.service_name}-"
  vpc_zone_identifier = data.aws_subnet_ids.default.ids

  # We only want one instance of the Traefik EC2 Container Instance in operation
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  tag {
    key                 = "Name"
    value               = var.service_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.value["key"]
      value               = tag.value["value"]
      propagate_at_launch = tag.value["propagate_at_launch"]
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE LAUNCH CONFIGURATION TO DEFINE WHAT RUNS ON EACH INSTANCE IN THE ASG
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_launch_template" "launch_template" {
  name_prefix = "${var.service_name}-"

  image_id      = var.ami_id == null ? data.aws_ami.ecs_optimised.image_id : var.ami_id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name
  ebs_optimized = false

  vpc_security_group_ids = concat(
    [aws_security_group.lc_security_group.id],
    var.security_groups
  )

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  # Associate the instance with ECS cluster, assign the Elastic IP with the new instance
  # and create a directory to store lets encrypt certificates
  user_data = base64encode(
    templatefile("${path.module}/user_data.sh.tmpl", { ecs_cluster = local.ecs_cluster, eip_allocation_id = aws_eip.elastic_ip.id })
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE A SECURITY GROUP TO CONTROL WHAT REQUESTS CAN GO IN AND OUT OF THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group" "lc_security_group" {
  name_prefix = "${var.service_name}-"
  description = "Security group for the ${var.service_name} launch configuration"
  vpc_id      = var.vpc_id
}

# ---------------------------------------------------------------------------------------------------------------------
# ALLOW INBOUND TRAFFIC on 443
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_security_group_rule" "allow_https_inbound" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.allowed_inbound_cidr_blocks

  security_group_id = aws_security_group.lc_security_group.id
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count = length(var.allowed_ssh_cidr_blocks) > 0 ? 1 : 0

  type        = "ingress"
  from_port   = var.ssh_port
  to_port     = var.ssh_port
  protocol    = "tcp"
  cidr_blocks = var.allowed_ssh_cidr_blocks

  security_group_id = aws_security_group.lc_security_group.id
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lc_security_group.id
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM ROLE TO EACH EC2 INSTANCE
# Use an IAM role to grant the instance IAM permissions so we can use the AWS CLI without having to figure out
# how to get our secret AWS access keys onto the box.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.service_name}-"
  path        = var.instance_profile_path
  role        = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.service_name}-"
  assume_role_policy = data.aws_iam_policy_document.instance_role.json
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "instance_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:AssociateAddress"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "instance_policy" {
  policy = data.aws_iam_policy_document.instance_policy.json
}

resource "aws_iam_role_policy_attachment" "instance_policy" {
  role       = aws_iam_role.instance_role.name
  policy_arn = aws_iam_policy.instance_policy.arn
}

data "aws_iam_policy" "ecs" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.instance_role.name
  policy_arn = data.aws_iam_policy.ecs.arn
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE AN ELASTIC IP TO ASSOCIATE WITH THE EC2 INSTANCE
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_eip" "elastic_ip" {
  vpc = true
}

# ---------------------------------------------------------------------------------------------------------------------
# ATTACH AN IAM ROLE TO THE TRAEFIK ECS TASK
# Use an IAM role to grant the task IAM permissions so we can use the AWS CLI without having to figure out
# how to get our secret AWS access keys onto the container.
# ---------------------------------------------------------------------------------------------------------------------

resource "aws_iam_role" "task_role" {
  name_prefix        = var.service_name
  assume_role_policy = data.aws_iam_policy_document.task_role.json
}

data "aws_iam_policy_document" "task_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy" "ecs_task_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.task_role.name
  policy_arn = data.aws_iam_policy.ecs_task_execution.arn
}

resource "aws_ecs_task_definition" "traefik" {
  family             = "traefik"
  execution_role_arn = aws_iam_role.task_role.arn

  volume {
    name      = "docker-daemon"
    host_path = "/var/run/docker.sock"
  }

  volume {
    name      = "letsencrypt"
    host_path = "/letsencrypt"
  }

  container_definitions = <<EOF
    [
      {
        "name": "socket-proxy",
        "image": "${var.socket_proxy_image}",
        "cpu": 0,
        "memory": ${var.socket_proxy_memory},
        "portMappings": [],

        "essential": true,
        "environment": [
          {
            "name": "CONTAINERS",
            "value": "1"
          }
        ],
        "mountPoints": [
          {
            "sourceVolume": "docker-daemon",
            "containerPath": "/var/run/docker.sock",
            "readOnly": true
          }
        ],
        "volumesFrom": [],
        "privileged": true
      },
      {
        "name": "traefik",
        "image": "${var.traefik_image}",
        "cpu": 0,
        "memory": ${var.traefik_memory},
        "links": [
          "socket-proxy:socket-proxy"
        ],
        "portMappings": [
          {
            "containerPort": 443,
            "hostPort": 443,
            "protocol": "tcp"
          }
        ],
        "essential": true,
        "command": [
          "--api.dashboard=true",
          "--providers.docker.endpoint=tcp://socket-proxy:2375",
          "--providers.docker.watch=true",
          "--providers.docker.exposedByDefault=false",
          "--entryPoints.websecure.address=:443",
          "--certificatesresolvers.myresolver.acme.tlschallenge=true",
          "--certificatesresolvers.myresolver.acme.email=${var.lets_encrypt_acme_email}",
          "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
        ],
        "environment": [],
        "mountPoints": [
          {
            "sourceVolume": "letsencrypt",
            "containerPath": "/letsencrypt",
            "readOnly": false
          }
        ],
        "volumesFrom": [],
        "dependsOn": [
          {
            "containerName": "socket-proxy",
            "condition": "START"
          }
        ],
        "dockerLabels": {
          "traefik.enable": "true",
          "traefik.http.middlewares.auth.basicauth.users": "${var.traefik_dashboard_username}:${var.traefik_dashboard_password}",
          "traefik.http.routers.api.entrypoints": "websecure",
          "traefik.http.routers.api.middlewares": "auth",
          "traefik.http.routers.api.rule": "Host(`${var.traefik_domain}`)",
          "traefik.http.routers.api.service": "api@internal",
          "traefik.http.routers.api.tls.certresolver": "myresolver"
        }
      }
    ]
EOF
}

resource "aws_ecs_service" "traefik" {
  name            = var.service_name
  cluster         = local.ecs_cluster
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.traefik.arn
  desired_count   = 1
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY IN THE DEFAULT VPC AND SUBNETS
# Using the default VPC and subnets makes this example easy to run and test, but it means Consul is accessible from the
# public Internet. For a production deployment, we strongly recommend deploying into a custom VPC with private subnets.
# ---------------------------------------------------------------------------------------------------------------------

data "aws_vpc" "default" {
  default = var.vpc_id == null ? true : false
  id      = var.vpc_id
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

data "aws_region" "current" {
}
