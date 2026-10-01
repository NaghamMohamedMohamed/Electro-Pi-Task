terraform {
  backend "s3" {
    bucket       = "three-tier-terraform-state"
    key          = "three-tier/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}