packer {
  required_plugins {
    azure = { source = "github.com/hashicorp/azure", version = ">= 1.0.0" }
    vsphere = { source = "github.com/hashicorp/vsphere", version = ">= 1.0.0" }
    amazon = { source = "github.com/hashicorp/amazon", version = ">= 1.0.0" }
    xenorchestra = { source = "github.com/ddelnano/xenserver", version = ">= 0.7.0" }
  }
}
