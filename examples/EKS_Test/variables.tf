variable "instance_type"{
    type = string
    default = "m6i.large"
}

variable "instance_types"{
    type = list(string)
    default = ["c6in.large", "c6in.xlarge", "c6in.2xlarge", "c6in.4xlarge"]
}

variable "instance_type1"{
    type = string
    default = "r6in.large"
}

variable "instance_type2"{
    type = string
    default = "ri4i.large"
}