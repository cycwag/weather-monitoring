# setup-argocd.ps1
# Jalankan SETELAH setup-cluster.ps1 selesai (cluster + kubectl sudah siap).

Write-Host "=== Membuat namespace argocd ===" -ForegroundColor Cyan
kubectl create namespace argocd 2>$null

Write-Host "=== Install Argo CD ===" -ForegroundColor Cyan
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "=== Menunggu pod Argo CD siap (60 detik) ===" -ForegroundColor Cyan
Start-Sleep -Seconds 60
kubectl get pods -n argocd

Write-Host "=== Password admin Argo CD: ===" -ForegroundColor Green
$encodedPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
Write-Host ""

Write-Host "=== Jalankan ini di terminal TERPISAH untuk akses UI: ===" -ForegroundColor Yellow
Write-Host "kubectl port-forward svc/argocd-server -n argocd 8080:443"
Write-Host "Lalu buka: https://localhost:8080 (username: admin)"