# Test environment configuration

module "test" {
  source = "../.."
  
  environment = "test"
  owner       = "DevOps Team"
  managed_by  = "Terraform"
  version     = "v1"
}
