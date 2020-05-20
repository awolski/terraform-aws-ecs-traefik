# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "service_name" {
  description = "The name of the service (e.g. traefik-stage). This variable is used to namespace all resources created by this module."
  type        = string
}

variable "ecs_cluster" {
  description = "The name of the ECS cluster to logically associate resources."
}

variable "ami_id" {
  description = "The ID of the AMI to run in the ECS cluster. Should be an AMI that has the Amazon ECS container agent installed."
  type        = string
}

variable "instance_type" {
  description = "The type of the EC2 Instance to run for the traefik service (e.g. t2.micro)."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC in which to deploy the traefik service."
  type        = string
}

# ---------------------------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ---------------------------------------------------------------------------------------------------------------------

variable "subnet_ids" {
  description = "The subnet IDs into which the EC2 Instances should be deployed."
  type        = list(string)
  default     = []
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow SSH connections"
  type        = list(string)
  default     = []
}

variable "ssh_port" {
  description = "The port used for SSH connections"
  type        = number
  default     = 22
}

variable "security_groups" {
  description = "Additional security groups to attach to the EC2 instance"
  type        = list(string)
  default     = []
}

variable "instance_profile_path" {
  description = "Path in which to create the IAM instance profile."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "List of extra tag blocks added to the autoscaling group configuration. Each element in the list is a map containing keys 'key', 'value', and 'propagate_at_launch' mapped to the respective values."
  type = list(object({
    key                 = string
    value               = string
    propagate_at_launch = bool
  }))
  default = []
}

variable "socket_proxy_image" {
  description = "The Docker socket-proxy image to use, in the form [registry]/repository/image:tag. E.g. tecnativa/docker-socket-proxy:latest"
  type        = string
}

variable "socket_proxy_memory" {
  description = "The amount of memory to allocate in the socket-proxy container definition"
  type        = number
  default     = 64
}

variable "traefik_image" {
  description = "The traefik docker image to use, in the form [registry]/repository/image:tag. E.g. traefik:v2.1"
  type        = string
}

variable "traefik_memory" {
  description = "The amount of memory to allocate in the traefik container definition"
  type        = number
  default     = 128
}

variable "lets_encrypt_acme_email" {
  description = "The email address to use for automatic certificates with Let's Encrypt"
  type        = string
}

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the ECS instance will allow connections to Traefik"
  type        = list(string)
}

variable "traefik_domain" {
  description = "The email address to use for automatic certificates with Let's Encrypt"
  type        = string
}

variable "traefik_dashboard_username" {
  description = "The traefik dashboard username"
  type        = string
}

variable "traefik_dashboard_password" {
  description = "The traefik dashboard password"
  type        = string
}
