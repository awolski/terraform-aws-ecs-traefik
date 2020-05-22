# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "lets_encrypt_acme_email" {
  description = "The email address to use for automatic certificates with Let's Encrypt"
  type        = string
}

variable "traefik_domain" {
  description = "The domain at which the traefik dashboard will be hosted, e.g. traefik.example.com"
  type        = string
}

variable "traefik_dashboard_username" {
  description = "The traefik dashboard username."
  type        = string
}

variable "traefik_dashboard_password" {
  description = "The traefik dashboard password"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of an EC2 Key Pair that can be used to SSH to the EC2 Instances in this cluster. Set to an empty string to not associate a Key Pair."
  type        = string
  default     = null
}
