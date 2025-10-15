output "ollama_private_ip" {
  description = "Private IP of Ollama EC2 (for EKS pods)"
  value       = aws_instance.ollama.private_ip
}
output "key_pair_name" {
  value = aws_key_pair.this.key_name
}