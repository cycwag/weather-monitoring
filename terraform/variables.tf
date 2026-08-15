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
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "jumlah"
  type        = number
  default     = 2
}

variable "allowed_ip" {
  description = "IP publik kamu, untuk akses ke EKS API endpoint"
  type        = string
  # GANTI dengan IP kamu dari langkah 'curl https://api.ipify.org', tambahkan /32 di akhir
  default     = "103.3.221.229/32"
}