resource "local_file" "inventory" {
  filename = "../../ansible/generated/cluster-${data.aws_region.current.name}.inventory"
  content  = <<-HERE
    [all:vars]
    ansible_connection=ssh
    ansible_user=admin
    ansible_ssh_private_key_file=${replace(local_sensitive_file.cluster_ssh.filename, "../../", "")}

    [bastion]
    %{if var.enable_bootstrap_resources}
    ${aws_instance.bootstrap_bastion[0].public_ip} ansible_connection=ssh ansible_user=admin ansible_ssh_private_key_file=${replace(local_sensitive_file.bootstrap_bastion_ssh[0].filename, "../../", "")}  f_postgres_username=${aws_db_instance.boundary.username} f_postgres_password=${aws_db_instance.boundary.password} f_postgres_host=${aws_db_instance.boundary.address} f_postgres_port=${aws_db_instance.boundary.port} f_postgres_db_name=${aws_db_instance.boundary.db_name}
    %{endif}
  HERE
}

resource "local_file" "dynamic_inventory" {
  filename = "../../ansible/generated/cluster-${data.aws_region.current.name}_aws_ec2.yaml"
  content  = <<-HERE
    plugin: aws_ec2
    regions:
      - ${data.aws_region.current.name}
    groups:
      servers: tags.get("bchatha:cluster:consul:role") == "server"
      clients: tags.get("bchatha:cluster:consul:role") == "client"
      boundary_servers: tags.get("bchatha:cluster:boundary:role") == "server"
      boundary_clients: tags.get("bchatha:cluster:boundary:role") == "client"
      ingress: tags.get("bchatha:cluster:ingress:role") == "ingress"
  HERE
}

output "lb_dns_name" {
  value = aws_lb.lb.dns_name
}
