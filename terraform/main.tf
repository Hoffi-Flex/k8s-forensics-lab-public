terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.44.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4"
    }
  }
  backend "s3" {
    bucket                      = "<Bucket name>"
    key                         = "terraform.tfstate"
    region                      = "auto"
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    # access_key                  = var.cloudflare_access_key
    # secret_key                  = var.cloudflare_secret_key
    endpoints                   = { s3 = "<S3URL>" }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "cloudflare" {
  # token pulled from $CLOUDFLARE_API_TOKEN
}

# Define variables for sensitive information
variable "cloudflare_access_key" {
  description = "Cloudflare R2 access key"
  type        = string
}

variable "cloudflare_secret_key" {
  description = "Cloudflare R2 secret key"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID for R2"
  type        = string
  default = "<AccountID>"
}

variable "do_token" {
  description = "DigitalOcean API Token"
  type        = string
}