terraform {
  backend "s3" {
    bucket         = "weather-monitoring-tfstate-project"
    key            = "weather-monitoring/terraform.tfstate"
    region         = "ap-southeast-3"
    dynamodb_table = "weather-monitoring-tfstate-lock"
    encrypt        = true
  }
}