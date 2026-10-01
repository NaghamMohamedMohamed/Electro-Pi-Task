# For comon tags/namming 
locals {
  name = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Application = "three-tier"
  }

  frontend_repository_name = "${local.name}-frontend"
  backend_repository_name  = "${local.name}-backend"

  frontend_image = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_version}"
  backend_image  = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_version}"
}
