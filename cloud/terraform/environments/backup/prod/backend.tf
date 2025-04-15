terraform {
  backend "s3" {
    bucket         = "la1r-terraform-state-backup" # Created manually by Seb!
    key            = "env/backup/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}