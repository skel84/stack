/**
 * The web-service is similar to the `service` module, but the
 * it provides a __public__ ELB instead.
 *
 * Usage:
 *
 *      module "auth_service" {
 *        source    = "github.com/segmentio/stack/service"
 *        name      = "auth-service"
 *        ami       = "ami-adasada"
 *        cluster   = "default"
 *      }
 *
 */

/**
 * Required Variables.
 */

variable "environment" {
  description = "Environment tag, e.g prod"
}

variable "name" {
  description = "The service name, if empty the service name is defaulted to the image name"
  default     = ""
}

variable "ami_id" {
  description = "The ami to use for the service"
}

variable "key_name" {
  description = "The key to use for the ami"
}

variable "user_data" {
  description = "The user_data file path"
}

variable "subnet_ids" {
  description = "Comma separated list of subnet IDs that will be passed to the ELB module"
}

variable "security_groups" {
  description = "Comma separated list of security group IDs that will be passed to the ELB module"
}

variable "port" {
  description = "The port on which the service is listening to"
}

variable "cluster" {
  description = "The cluster name or ARN"
}

variable "log_bucket" {
  description = "The S3 bucket ID to use for the ELB"
}

variable "ssl_certificate_id" {
  description = "SSL Certificate ID to use"
}

variable "iam_role" {
  description = "IAM Role ARN to use"
}

variable "external_dns_name" {
  description = "The subdomain under which the ELB is exposed externally, defaults to the task name"
  default     = ""
}

variable "internal_dns_name" {
  description = "The subdomain under which the ELB is exposed internally, defaults to the task name"
  default     = ""
}

variable "external_zone_id" {
  description = "The zone ID to create the record in"
}

variable "internal_zone_id" {
  description = "The zone ID to create the record in"
}

/**
 * Options.
 */

variable "healthcheck" {
  description = "Path to a healthcheck endpoint"
  default     = "/"
}

variable "desired_count" {
  description = "The desired count"
  default     = 2
}

variable "instance_type" {
  description = "The desired instance type"
  default     = "t2.micro"
}

variable "asg_max_size" {
  description = "Maximum number of instances"
  default = 4
}
variable "asg_min_size" {
  description = "minimum number of instances"
  default = 1
}
variable "asg_desired_capacity" {
  description = "Desired number of instances"
  default = 1
}

variable "health_check_grace_period" {
  description = ""
  default = 60
  }
variable "health_check_type" {
  description = ""
  default = "HTTP"
  }

/**
 * Resources.
 */

module "asg_elb" {
  source = "./asg_elb"

  name                      = "${var.name}"
  port                      = "${var.port}"
  environment               = "${var.environment}"
  subnet_ids                = "${var.subnet_ids}"
  external_dns_name         = "${coalesce(var.external_dns_name, var.name)}"
  internal_dns_name         = "${coalesce(var.internal_dns_name, var.name)}"
  healthcheck               = "${var.healthcheck}"
  external_zone_id          = "${var.external_zone_id}"
  internal_zone_id          = "${var.internal_zone_id}"
  security_groups           = "${var.security_groups}"
  log_bucket                = "${var.log_bucket}"
  ssl_certificate_id        = "${var.ssl_certificate_id}"
  image_id                  = "${var.ami_id}"
  instance_type             = "${var.instance_type}"
  #iam_instance_profile      = "${var.iam_instance_profile}"
  max_size                  = "${var.asg_max_size}"
  min_size                  = "${var.asg_min_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  health_check_grace_period = "${var.health_check_grace_period}"
  health_check_type         = "${var.health_check_type}"

}

/**
 * Outputs.
 */

// The name of the ELB
output "name" {
  value = "${module.asg_elb.name}"
}

// The DNS name of the ELB
output "dns" {
  value = "${module.asg_elb.dns}"
}

// The id of the ELB
output "elb" {
  value = "${module.asg_elb.id}"
}

// The zone id of the ELB
output "zone_id" {
  value = "${module.asg_elb.zone_id}"
}

// FQDN built using the zone domain and name (external)
output "external_fqdn" {
  value = "${module.asg_elb.external_fqdn}"
}

// FQDN built using the zone domain and name (internal)
output "internal_fqdn" {
  value = "${module.asg_elb.internal_fqdn}"
}
