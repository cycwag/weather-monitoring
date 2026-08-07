variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-3"
}

variable "cluster_name" {
  description = "EKS cluster"
  type        = string
  default     = "weather-monitoring"
}

variable "node_instance_type" {
  description = "EKS Instance Type"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "jumlah"
  type        = number
  default     = 1
}