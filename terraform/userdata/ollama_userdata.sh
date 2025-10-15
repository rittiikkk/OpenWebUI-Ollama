#!/bin/bash
set -e
# install docker
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release
apt-get install -y apt-transport-https software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker ubuntu
systemctl enable docker && systemctl start docker
# pull and run Ollama official docker container
docker run -d --name=ollama --restart unless-stopped -p 11434:11434 ollama/ollama:latest

# wait for container, then pull model (non-blocking background)

if docker exec ollama ollama pull llama2; then
  echo "✅ Llama2 model pulled"
else
  echo "⚠️ Failed to pull Llama2 model"
fi

# sleep 8
# docker exec ollama ollama pull llama2 || true