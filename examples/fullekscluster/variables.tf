########################
####     Intel      ####
########################

########################
####    Required    ####
########################
variable "instance_type"{}
variable "subnets"{
    default = ["subnet-049df61146f12", "subnet-049df61146f13", "subnet-049df61146f14"]
}
########################
####     Other      ####
########################
variable "version"{
    type = number
    default= "19.7.0"
}