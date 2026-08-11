# setup-cluster.ps1
# Jalankan SETELAH "terraform apply" selesai, dari folder root project.
# Script ini otomatisasi: connect kubectl + install Load Balancer Controller.
# TIDAK apply manifest aplikasi (secret, postgres, dst) -- itu tugas Argo CD.

Write-Host "=== 1. Menyambungkan kubectl ke cluster ===" -ForegroundColor Cyan
aws eks update-kubeconfig --region ap-southeast-3 --name weather-monitoring

Write-Host "=== 2. Mengambil VPC ID dan ARN dari Terraform ===" -ForegroundColor Cyan
Push-Location terraform
$VPC_ID = terraform output -raw vpc_id
$LBC_ROLE_ARN = terraform output -raw lbc_role_arn
Pop-Location

Write-Host "VPC ID: $VPC_ID" -ForegroundColor Yellow
Write-Host "LBC Role ARN: $LBC_ROLE_ARN" -ForegroundColor Yellow

Write-Host "=== 3. Update ARN di lbc-service-account.yaml ===" -ForegroundColor Cyan
(Get-Content k8s/lbc-service-account.yaml) `
  -replace 'eks\.amazonaws\.com/role-arn:.*', "eks.amazonaws.com/role-arn: $LBC_ROLE_ARN" |
  Set-Content k8s/lbc-service-account.yaml

Write-Host "=== 4. Apply ServiceAccount Load Balancer Controller ===" -ForegroundColor Cyan
kubectl apply -f k8s/lbc-service-account.yaml

Write-Host "=== 5. Install AWS Load Balancer Controller (Helm) ===" -ForegroundColor Cyan
helm repo add eks https://aws.github.io/eks-charts 2>$null
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller `
  --namespace kube-system `
  --set clusterName=weather-monitoring `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller `
  --set region=ap-southeast-3 `
  --set vpcId=$VPC_ID

Write-Host "=== 6. Menunggu Load Balancer Controller siap (30 detik) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 30
kubectl get pods -n kube-system | Select-String "aws-load-balancer"

Write-Host "=== SELESAI. Cluster + Load Balancer Controller siap. ===" -ForegroundColor Green
Write-Host "Selanjutnya jalankan: .\scripts\setup-argocd.ps1" -ForegroundColor Yellow
Write-Host "Argo CD yang akan deploy semua manifest aplikasi secara OTOMATIS." -ForegroundColor Yellow