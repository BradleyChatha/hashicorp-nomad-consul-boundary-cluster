resource "local_file" "inventory" {
  filename = "../../ansible/generated/cluster-${data.aws_region.current.name}.inventory"
  content  = <<HERE
[servers]
%{for server in module.nomad_consul_servers.servers}
${server.public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=${replace(module.nomad_consul_servers.ssh_key_filename, "../../", "")} 
%{endfor}
[bastion]
%{if var.enable_bootstrap_bastion}
${aws_instance.bootstrap_bastion[0].public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=${replace(local_sensitive_file.bootstrap_bastion_ssh[0].filename, "../../", "")}  f_postgres_username=${aws_db_instance.boundary.username} f_postgres_password=${aws_db_instance.boundary.password} f_postgres_host=${aws_db_instance.boundary.address} f_postgres_port=${aws_db_instance.boundary.port} f_postgres_db_name=${aws_db_instance.boundary.db_name}
%{endif}
[boundary_servers]
%{for server in module.boundary_servers.servers}
${server.public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=${replace(module.boundary_servers.ssh_key_filename, "../../", "")} 
%{endfor}
  HERE
}
