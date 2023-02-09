########################
####     Intel      ####
########################

variable "instance_type"{}

########################
####    Required    ####
########################

variable "subnets"{
    default = ["subnet-049df61146f12", "subnet-049df61146f13", "subnet-049df61146f14"]
}

variable "my_access_key"{
    default = "AKIAXI2GL3V4CVR6U2HJ"
}

variable "my_secret_key"{
    default = "7uW9fOiTe1jfLUFOmWs/m956sYb4c2+qzG4lg7Hi"
}

########################
####     Other      ####
########################
