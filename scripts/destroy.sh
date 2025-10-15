#!/usr/bin/env bash
echo "🧹 Cleaning up Kubernetes resources before destroy..."
kubectl delete all --all --ignore-not-found
kubectl delete svc --all --ignore-not-found
sleep 60
terraform destroy

