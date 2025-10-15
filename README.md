# Open WebUI + Ollama (assessment)

This repo deploys Open WebUI to EKS and Ollama to a small EC2 instance and connects them.

## Architecture
- EKS cluster runs Open WebUI (frontend/backend).
- Ollama runs on an EC2 instance and listens on `11434`.
- Open WebUI connects to Ollama via `http://<OLLAMA_IP>:11434`.

## Quick steps (high-level)
1. Edit `terraform/variables.tf` with your AWS profile, ssh key and CIDR.
2. `cd terraform && terraform init && terraform apply -auto-approve`
3. Wait for EC2 to be ready (Terraform output `ollama_public_ip`).
4. Update kubeconfig: `aws eks update-kubeconfig --name openwebui-cluster --region <region>`
5. In `k8s/openwebui-deployment.yaml`, replace `OLLAMA_HOST` with the private IP of the EC2 (or set via env).
6. `kubectl apply -f k8s/`
7. Get the LoadBalancer IP: `kubectl get svc openwebui -o wide`
8. Open in browser. Go to Settings → Connections → enable Ollama and point to `http://<ollama-ip>:11434` if not already set.

## Verification
- `curl http://<ollama-ip>:11434` should respond (Ollama API).
- In Open WebUI, pick the Ollama runner and a model you pulled (e.g., `llama2`), type a prompt and verify responses.
- You can test Ollama directly: `curl -X POST "http://<ollama-ip>:11434/api/run" -d '{"model":"llama2", "prompt":"Hello"}'`

## Troubleshooting
- If no response in Open WebUI: check security groups, ensure EKS nodes can reach Ollama IP on 11434.
- Port-forward test: `kubectl port-forward svc/openwebui 3000:3000` then `curl localhost:3000` to confirm UI running.
- On Ollama: `docker logs -f ollama` and `docker exec ollama ollama list`.

## Notes & decisions
- Chose EC2 for Ollama to allow flexible instance selection (GPU later) and to avoid complex in-cluster GPU setup.
- OpenWebUI runs in EKS for scalability, LB/ingress is used to expose the UI.
- Security: restrict Ollama port to VPC or specific CIDRs; enable authentication at ingress if exposing to the public internet.

## References
- Open WebUI docs — Quick Start & Ollama integration. :contentReference[oaicite:2]{index=2}
- Ollama docs & Docker image. :contentReference[oaicite:3]{index=3}