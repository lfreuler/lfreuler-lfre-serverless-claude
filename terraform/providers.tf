# Provider configuration

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      lfre_owner       = var.owner
      lfre_managedby   = var.managed_by
      lfre_environment = var.environment
    }
  }
}
