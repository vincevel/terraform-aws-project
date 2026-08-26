terraform {
  backend "s3" {
    bucket         = "vince-tf-state-20260826"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "vince-tf-lock-20260826"
    encrypt        = true
  }
}
