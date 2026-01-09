terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.0" }
    vsphere = { source = "hashicorp/vsphere", version = "~> 2.0" }
    aws     = { source = "hashicorp/aws",     version = "~> 5.0" }
    xcpng   = { source = "terra-farm/xenorchestra", version = "~> 0.3" }
  }
}

provider "azurerm" {
  features {}
}

provider "vsphere" {}

provider "aws" {}

provider "xcpng" {}
