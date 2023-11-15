# Variable to add ingress rules to the security group. Replace the default values with the required ports and CIDR ranges.
variable "ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = string
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"

    },
    {
      from_port   = 30010
      to_port     = 30010
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"

    }
  ]
}