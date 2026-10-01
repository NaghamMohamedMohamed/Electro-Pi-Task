terraform {
  backend "s3" {
    bucket       = "electro-pi-three-tier-terraform-state-bucket"
    key          = "three-tier/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}