# Production environment configuration

module "prod" {
  source = "../.."
  
  environment = "prod"
  owner       = "DevOps Team"
  managed_by  = "Terraform"
  version     = "v1"
}
