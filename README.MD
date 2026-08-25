# 🌤️ Weather Monitoring — End-to-End DevOps Project

A production-grade weather monitoring application built to demonstrate a complete DevOps lifecycle — from containerization to GitOps-driven deployment on AWS EKS.

---

## 🏗️ Architecture Overview

```
                         Internet
                            │
                    AWS Load Balancer (ALB)
                    (managed by Ingress via
                     AWS Load Balancer Controller)
                            │
                ┌───────────┴───────────┐
                │                        │
          /weather, /health          / (Frontend)
                │                        │
          weather-api              weather-frontend
          (Node.js)                   (nginx)
                │
        ┌───────┴───────┐
        │                │
     Redis           PostgreSQL
    (cache)          (history)
        │
  weather-worker
   (Python, fetch
    OpenWeatherMap
    tiap 30 menit)
```

**Infrastructure:** AWS EKS (ap-southeast-3/Jakarta), private subnet + NAT Gateway, Application Load Balancer via Ingress

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Application** | Node.js/Express (API), Python (Worker), HTML/CSS/JS + nginx (Frontend) |
| **Database** | PostgreSQL (history), Redis (cache) |
| **Container** | Docker, Docker Hub |
| **Orchestration** | Kubernetes (AWS EKS) |
| **Infrastructure** | Terraform (VPC, EKS, IAM, KMS) |
| **CI/CD** | GitHub Actions |
| **GitOps** | Argo CD |
| **Security** | Gitleaks, Checkov, OWASP Dependency Check, SonarCloud, Trivy, Sealed Secrets, Network Policy, KMS Encryption |
| **State Management** | Terraform Remote State (S3 + DynamoDB locking) |

---

## 📁 Project Structure

```
weather-monitoring/
├── .github/
│   └── workflows/
│       └── ci-security.yml        # CI pipeline dengan 5 security tools
├── api/                            # Backend Node.js/Express
├── worker/                         # Python worker (fetch OpenWeatherMap)
├── frontend/                       # Dashboard HTML/CSS/JS + nginx
├── terraform/                      # AWS Infrastructure as Code
│   ├── provider.tf
│   ├── variables.tf
│   ├── vpc.tf                      # VPC, subnet publik/privat, NAT Gateway
│   ├── eks.tf                      # EKS cluster + node group + KMS encryption
│   ├── oidc.tf                     # OIDC Provider untuk IRSA
│   ├── lbc-iam.tf                  # IAM Role untuk Load Balancer Controller
│   ├── kms.tf                      # KMS key untuk EKS Secrets encryption
│   ├── backend.tf                  # Remote State (S3 + DynamoDB)
│   └── outputs.tf
├── k8s/                            # Kubernetes manifests
│   ├── sealed-secret.yaml          # Secrets terenkripsi (Sealed Secrets)
│   ├── worker-configmap.yaml
│   ├── postgres-init-configmap.yaml
│   ├── postgres.yaml
│   ├── redis.yaml
│   ├── api-deployment.yaml
│   ├── worker-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── lbc-service-account.yaml
│   ├── ingress-api.yaml
│   ├── ingress-frontend.yaml
│   ├── postgres-network-policy.yaml
│   ├── redis-network-policy.yaml
│   ├── api-network-policy.yaml
│   └── frontend-network-policy.yaml
├── scripts/
│   ├── setup-cluster.ps1           # Otomatisasi post-apply setup
│   └── setup-argocd.ps1            # Otomatisasi instalasi Argo CD
└── sonar-project.properties
```

---

## 🔐 Security Implementation

### CI Pipeline (GitHub Actions)

5 security tools yang berjalan di tiap `git push`:

| Tool | Fungsi | Blocking? |
|---|---|---|
| **Gitleaks** | Deteksi secret/credential yang ter-commit | ✅ Yes |
| **Checkov** | Scan misconfiguration Terraform | ⚠️ Non-blocking (report) |
| **OWASP Dependency Check** | Scan vulnerable packages | ⚠️ Non-blocking (report) |
| **SonarCloud** | Code quality & security hotspot | ✅ Yes (via Quality Gate) |
| **Trivy** | Image vulnerability scan | ✅ Yes (CRITICAL), ⚠️ Non-blocking (HIGH/MEDIUM) |

### Infrastructure Security

- **KMS Encryption** — Kubernetes Secrets ter-enkripsi di etcd via AWS KMS
- **IRSA** — Pod-level IAM permissions (tidak pakai Node role, prinsip least privilege)
- **Sealed Secrets** — Secret terenkripsi sungguhan, aman di-commit ke Git
- **Network Policy** — Pembatasan eksplisit komunikasi antar-pod (deny by default)
- **EKS Public Endpoint Restriction** — Akses kubectl dibatasi ke IP tertentu

---

## 🚀 How It Works

### CI/CD Flow

```
git push → GitHub Actions triggered
        ↓
1. Gitleaks scan (secret detection)
2. Checkov scan (Terraform IaC)
3. OWASP Dependency Check
4. SonarCloud analysis
5. Build Docker image
6. Trivy scan (image vulnerability)
7. Push to Docker Hub (only if all blocking checks pass)
        ↓
Argo CD detects new image → Auto-sync to EKS cluster
```

### GitOps Flow (Argo CD)

```
Developer push manifest → GitHub repo
        ↓
Argo CD polls repo (every ~3 minutes)
        ↓
Detects diff between Git state vs cluster state
        ↓
Auto-applies changes to EKS cluster
        ↓
Self-healing: if manual change detected → reverts to Git state
```

---

## ⚙️ Infrastructure Setup

### Prerequisites

- AWS CLI configured
- Terraform >= 1.5
- kubectl, Helm, kubeseal
- Docker Desktop

### Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

### Setup Cluster (Post-Apply)

```powershell
.\scripts\setup-cluster.ps1
.\scripts\setup-argocd.ps1
```

### Re-seal Secrets (Wajib tiap cluster baru)

```powershell
Get-Content k8s/secret.yaml | kubeseal \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  --format=yaml > k8s/sealed-secret.yaml
```

> ⚠️ **Note:** Sealed Secrets private key di-generate ulang setiap cluster baru dibuat. Wajib re-seal tiap sesi baru.

---

## 📊 Key Challenges & Solutions

| Challenge | Root Cause | Solution |
|---|---|---|
| NAT Gateway `AlreadyAssociated` | Crash di tengah `terraform apply` | `terraform destroy` + bersihkan resource sisa manual |
| Node `NodeCreationFailure` | EKS public endpoint terlalu restrict, node tidak bisa join via NAT | Tambahkan `endpoint_private_access = true` |
| Frontend tidak tampil data | Image Docker lama (dengan `localhost:3000`) masih dipakai | Build ulang dengan `--no-cache`, delete pod untuk force pull |
| ALB Frontend `Unhealthy` | Health check path `/health` tidak ada di nginx | Pisah jadi 2 Ingress dengan `group.name` yang sama |
| Sealed Secrets tidak ter-decrypt | Private key cluster beda tiap `terraform apply` baru | Re-seal `secret.yaml` setiap sesi baru |
| Too many pods (`t3.small`) | Batas pod per node ~11, total pod ~18 | Upgrade ke `t3.medium` (2 node) |

---

## 💡 Architecture Decisions & Trade-offs

- **Public subnet untuk worker node** — Skip NAT Gateway biaya ~$32/bulan, tradeoff: node dapat IP publik langsung
- **Single NAT Gateway** — Hemat biaya vs High Availability (dual NAT), wajar untuk non-production
- **Cluster sering di-destroy** — Strategi hemat biaya ($300rb/3 bulan), konsekuensi: re-seal Secret & re-setup komponen tiap sesi
- **IRSA vs Node IAM Role** — Pilih IRSA untuk least privilege (hanya pod tertentu yang dapat izin AWS API, bukan semua pod di node)

---

## 📝 Accepted Risks (Documented)

| Finding | Alasan Diterima |
|---|---|
| VPC Flow Logs disabled | Biaya CloudWatch, tidak relevan untuk cluster belajar yang sering di-destroy |
| EKS Control Plane logging disabled | Sama, biaya CloudWatch |
| Subnet public IP enabled | Desain disengaja, skip NAT Gateway untuk efisiensi biaya |
