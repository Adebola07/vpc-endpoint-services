variable "provider-cidr" {
   default = "10.0.0.0/16"
}

variable "consumer-cidr" {
   default = "20.0.0.0/16"
}


module "provider-vpc" {
    source = "./vpc" 
    vpc-cidr = var.provider-cidr
    vpc-tag = "provider-vpc"
    priv-sub-tag = "prov-priv-sub"
    pub-sub-tag = "prov-pub-sub"
    lb-sub-tag = "prov-lb-sub"
  
}

module "consumer-vpc" {
    source = "./vpc"
    vpc-cidr = var.consumer-cidr
    vpc-tag = "consumer-vpc"
    priv-sub-tag = "cons-priv-sub"
    pub-sub-tag = "cons-pub-sub"
    lb-sub-tag = "cons-lb-sub"

  
}
