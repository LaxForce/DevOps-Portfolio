terraform {
  backend "s3" {
    bucket         = "leon-phonebook-app-tf-state"
    key            = "phonebook/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}