output "ssh_key" {
  value = tls_private_key.ssh
}

output "ssh_key_filename" {
  value = local_sensitive_file.ssh.filename
}

output "ssh_key_pair" {
  value = aws_key_pair.ssh
}

output "servers" {
  value = aws_instance.servers
}
