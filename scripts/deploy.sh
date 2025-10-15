#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR/terraform"

echo "🧱 Terraform init & apply (this will create infra + k8s resources)..."
terraform init -input=false -upgrade
terraform apply -auto-approve

# After apply, fetch Ollama private ip and region (if you keep region output)
OLLAMA_IP=$(terraform output -raw ollama_private_ip 2>/dev/null || true)
echo "Ollama private IP: ${OLLAMA_IP}"

# Now ensure kubectl can access cluster (you may still need to run aws eks update-kubeconfig once locally)
echo "⏳ Waiting for LoadBalancer assignment (this may take 1-3 minutes)..."
kubectl -n default wait --for=condition=available deployment/openwebui --timeout=30s || true
echo "Service status:"
kubectl get svc openwebui -o wide

LB_HOST=$(kubectl get svc openwebui -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
if [[ -n "$LB_HOST" ]]; then
  echo "OpenWebUI should be reachable at: http://$LB_HOST"
else
  echo "LoadBalancer hostname not yet assigned. Run: kubectl get svc openwebui -w"
fi