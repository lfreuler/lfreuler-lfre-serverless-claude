# Development environment configuration

module "dev" {
  source = "../.."
  
  environment = "dev"
  owner       = "DevOps Team"
  managed_by  = "Terraform"
  version     = "v1"
}
