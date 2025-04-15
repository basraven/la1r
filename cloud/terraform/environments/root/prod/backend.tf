terraform {
  backend "s3" {
    bucket         = "la1r-terraform-state" # Created manually by Seb!
    key            = "env/root/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}