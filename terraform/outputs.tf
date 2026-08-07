output "cluster_name" {
  description = "Nama EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint API server EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Data sertifikat CA untuk autentikasi ke cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "configure_kubectl" {
  description = "Command untuk menghubungkan kubectl ke cluster ini"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.main.name}"
}

output "vpc_id" {
  description = "ID VPC yang dibuat"
  value       = aws_vpc.main.id
}
