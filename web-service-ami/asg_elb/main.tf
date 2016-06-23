/**
 * The ELB module creates an ELB, security group
 * a route53 record and a service healthcheck.
 * It is used by the service module.
 */

variable "name" {
  description = "ELB name, e.g cdn"
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs"
}

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "port" {
  description = "Instance port"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs"
}

variable "healthcheck" {
  description = "Healthcheck path"
}

variable "log_bucket" {
  description = "S3 bucket name to write ELB logs into"
}

variable "external_dns_name" {
  description = "The subdomain under which the ELB is exposed externally, defaults to the task name"
}

variable "internal_dns_name" {
  description = "The subdomain under which the ELB is exposed internally, defaults to the task name"
}

variable "external_zone_id" {
  description = "The zone ID to create the record in"
}

variable "internal_zone_id" {
  description = "The zone ID to create the record in"
}

variable "ssl_certificate_id" {
}

/**
 * Resources.
 */

resource "aws_elb" "main" {
  name = "${var.name}"

  internal                  = false
  cross_zone_load_balancing = true
  subnets                   = ["${split(",", var.subnet_ids)}"]
  security_groups           = ["${split(",",var.security_groups)}"]

  idle_timeout                = 30
  connection_draining         = true
  connection_draining_timeout = 15

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.port}"
    instance_protocol = "http"
  }

  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = "${var.port}"
    instance_protocol  = "http"
    ssl_certificate_id = "${var.ssl_certificate_id}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:${var.port}${var.healthcheck}"
    interval            = 30
  }

  access_logs {
    bucket = "${var.log_bucket}"
  }

  tags {
    Name        = "${var.name}-balancer"
    Service     = "${var.name}"
    Environment = "${var.environment}"
  }
}

resource "aws_route53_record" "external" {
  zone_id = "${var.external_zone_id}"
  name    = "${var.external_dns_name}"
  type    = "A"

  alias {
    zone_id                = "${aws_elb.main.zone_id}"
    name                   = "${aws_elb.main.dns_name}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "internal" {
  zone_id = "${var.internal_zone_id}"
  name    = "${var.internal_dns_name}"
  type    = "A"

  alias {
    zone_id                = "${aws_elb.main.zone_id}"
    name                   = "${aws_elb.main.dns_name}"
    evaluate_target_health = false
  }
}


resource "aws_launch_configuration" "launch_config" {
  name = "${var.name}"
  image_id = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  #iam_instance_profile = "${var.iam_role}"
  key_name = "${var.key_name}"
  security_groups = ["${var.security_groups}"]
  user_data = "${file(var.user_data)}"
}

resource "aws_autoscaling_group" "main_asg" {
  # We want this to explicitly depend on the launch config above
  depends_on = ["aws_launch_configuration.launch_config"]

  name = "${var.name}"

  # The chosen availability zones *must* match the AZs the VPC subnets are tied to.
  availability_zones = ["${split(",", var.availability_zones)}"]
  vpc_zone_identifier = ["${split(",", var.vpc_zone_subnets)}"]

  # Uses the ID from the launch config created above
  launch_configuration = "${aws_launch_configuration.launch_config.id}"

  max_size = "${var.asg_max_size}"
  min_size = "${var.asg_min_size}"
  desired_capacity = "${var.asg_desired_capacity}"

  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type = "${var.health_check_type}"

  load_balancers = ["${split(",", var.load_balancer_names)}"]
}

/**
 * Outputs.
 */

// The ELB name.
output "name" {
  value = "${aws_elb.main.name}"
}

// The ELB ID.
output "id" {
  value = "${aws_elb.main.id}"
}

// The ELB dns_name.
output "dns" {
  value = "${aws_elb.main.dns_name}"
}

// FQDN built using the zone domain and name (external)
output "external_fqdn" {
  value = "${aws_route53_record.external.fqdn}"
}

// FQDN built using the zone domain and name (internal)
output "internal_fqdn" {
  value = "${aws_route53_record.internal.fqdn}"
}

// The zone id of the ELB
output "zone_id" {
  value = "${aws_elb.main.zone_id}"
}
