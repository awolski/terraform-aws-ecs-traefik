# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY TRAEFIK in ECS USING CLOUDFLARE FOR DNS
# These templates show an example of how to use the ecs-traefik module to deploy Traefik in ECS. We deploy a single
# Auto Scaling Group. Note that these templates assume that the AMI you provide via the ami_id input variable is built from
# the examples/example-with-encryption/packer/consul-with-certs.json Packer template.
# ---------------------------------------------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER

# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# DEPLOY THE TRAEFIK ECS MODULE
# ---------------------------------------------------------------------------------------------------------------------



module "traefik" {
  source = "../../"

  ssh_key_name               = var.ssh_key_name
  lets_encrypt_acme_email    = var.lets_encrypt_acme_email
  traefik_domain             = var.traefik_domain
  traefik_dashboard_username = var.lets_encrypt_acme_email
  traefik_dashboard_password = var.traefik_dashboard_password
}