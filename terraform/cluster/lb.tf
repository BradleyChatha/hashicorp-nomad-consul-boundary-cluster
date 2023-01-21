resource "aws_acm_certificate" "lb" {
  domain_name       = "*.${var.root_domain_name}"
  validation_method = "DNS"
}

resource "aws_lb_target_group" "ingress" {
  name_prefix        = "ingrss"
  preserve_client_ip = false
  port               = 80
  protocol           = "TLS"
  vpc_id             = module.vpc.vpc.id
}

resource "aws_lb" "lb" {
  name_prefix                      = "lb"
  internal                         = false
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  subnets = [
    module.vpc.subnets.public_1.id,
    module.vpc.subnets.public_2.id,
    module.vpc.subnets.public_3.id,
  ]
}

resource "aws_lb_listener" "lb_https" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "443"
  protocol          = "TLS"
  certificate_arn   = aws_acm_certificate.lb.arn
  alpn_policy       = "HTTP2Preferred"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress.arn
  }
}
