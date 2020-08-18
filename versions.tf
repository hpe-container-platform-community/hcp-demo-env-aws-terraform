terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.59"
    }
    local = {
      version = "~> 1.4.0"
      source = "hashicorp/local"
    }
    null = {
      version = "~> 2.1.2"
      source = "hashicorp/null"
    }
    random = {
      version = "~> 2.3.0"
      source = "hashicorp/random"
    }
    template = {
      version = "~> 2.1.2"
      source = "hashicorp/template"
    }
  }
}
