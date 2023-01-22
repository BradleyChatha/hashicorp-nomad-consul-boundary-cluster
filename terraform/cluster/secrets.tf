resource "aws_secretsmanager_secret" "cluster_consul_bootstrap_token" {
  name                    = "cluster-consul-bootstrap-token"
  description             = "The bootstrap token for the Consul cluster"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}

resource "aws_secretsmanager_secret" "cluster_consul_client_token" {
  name                    = "cluster-consul-client-token"
  description             = "The client token for a typical Consul client"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}

resource "aws_secretsmanager_secret" "cluster_consul_traefik_token" {
  name                    = "cluster-consul-traefik-token"
  description             = "The client token for Traefik"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}

resource "aws_secretsmanager_secret" "cluster_nomad_bootstrap_token" {
  name                    = "cluster-nomad-bootstrap-token"
  description             = "The bootstrap token for the Nomad cluster"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}

resource "aws_secretsmanager_secret" "cluster_boundary_rds_credentials" {
  name                    = "cluster-boundary-rds-credentials"
  description             = "The credentials for boundary to access its postgres server"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}

resource "aws_secretsmanager_secret" "cluster_boundary_admin_password" {
  name                    = "cluster-boundary-admin-password"
  description             = "The (bootstrapped) password for the boundary admin account"
  recovery_window_in_days = var.allow_instant_delete_of_secrets ? 0 : 7
}
