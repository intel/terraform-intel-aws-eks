variable "instance_types" {
  type = list(string)
  description = "give some description"
  default = ["m6i.large","c6i.large"]
}

variable "instance_types1" {
  type = list(string)
  description = "give some description"
  default = ["r6i.large","c6i.2xlarge"]
}

variable "instance_types2" {
  type = list(string)
  description = "give some description"
  default = ["i4i.large","m6i.2xlarge"]
}