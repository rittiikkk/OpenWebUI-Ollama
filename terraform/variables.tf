variable "region" { default = "us-west-1" }
variable "aws_profile" { default = "<YOUR_AWS_PROFILE>" }
variable "my_ip" { 
    description = "your SSH CIDR" 
    default = "1.2.3.4/32" 
}
variable "ollama_instance_type" { default = "t3.large" } # adjust; GPU instance if using larger models
