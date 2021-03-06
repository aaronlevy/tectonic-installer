resource "aws_elb" "api-internal" {
  name            = "${var.cluster_name}-api-internal"
  subnets         = ["${var.subnet_ids}"]
  internal        = true
  security_groups = ["${aws_security_group.master_sec_group.id}"]

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 10255
    instance_protocol = "tcp"
    lb_port           = 10255
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:10255/healthz"
    interval            = 5
  }

  tags {
    Name              = "${var.cluster_name}-api-internal"
    KubernetesCluster = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "api-internal" {
  zone_id = "${var.internal_zone_id}"
  name    = "${var.cluster_name}-k8s.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.api-internal.dns_name}"
    zone_id                = "${aws_elb.api-internal.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "api-external" {
  name            = "${var.cluster_name}-api-external"
  subnets         = ["${var.subnet_ids}"]
  internal        = false
  security_groups = ["${aws_security_group.master_sec_group.id}"]

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:22"
    interval            = 5
  }

  tags {
    Name              = "${var.cluster_name}-api-external"
    KubernetesCluster = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "api-external" {
  zone_id = "${var.external_zone_id}"
  name    = "${var.cluster_name}-k8s.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.api-external.dns_name}"
    zone_id                = "${aws_elb.api-external.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_elb" "console" {
  name            = "${var.cluster_name}-console"
  subnets         = ["${var.subnet_ids}"]
  internal        = false
  security_groups = ["${aws_security_group.master_sec_group.id}"]

  listener {
    instance_port     = 32001
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 32000
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:32002/healthz"
    interval            = 5
  }

  tags {
    Name              = "${var.cluster_name}-console"
    KubernetesCluster = "${var.cluster_name}"
  }
}

resource "aws_route53_record" "ingress-public" {
  zone_id = "${var.external_zone_id}"
  name    = "${var.cluster_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.console.dns_name}"
    zone_id                = "${aws_elb.console.zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "ingress-private" {
  zone_id = "${var.internal_zone_id}"
  name    = "${var.cluster_name}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = "${aws_elb.console.dns_name}"
    zone_id                = "${aws_elb.console.zone_id}"
    evaluate_target_health = true
  }
}
