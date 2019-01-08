variable "project" {
  default = "Unknown"
}

variable "environment" {
  default = "Unknown"
}

variable "name" {}

variable "vpc_id" {}

variable "release_label" {
  default = "emr-5.8.0"
}

variable "applications" {
  default = ["Spark"]
  type    = "list"
}

variable "configurations" {}

variable "key_name" {}

variable "subnet_id" {}

variable "service_access_security_group_id" {
  description = "Security group with access to AWS Services over internet gateway. Applied to cluster service, master and slaves"
}

variable "keep_job_flow_alive_when_no_steps" {
  default = true
}

variable "custom_policy_count" {
  default = 0
  description = "Number of custom policy arns in custom_policy_arns"
}

variable "custom_policy_arns" {
  type    = "list"
  default = []
  description = "List of policy arns to add to instance profile role"
}

variable "instance_groups" {
  default = [
    {
      name           = "MasterInstanceGroup"
      instance_role  = "MASTER"
      instance_type  = "m3.xlarge"
      instance_count = 1
    },
    {
      name           = "CoreInstanceGroup"
      instance_role  = "CORE"
      instance_type  = "m3.xlarge"
      instance_count = "1"
      bid_price      = "0.30"
    },
  ]

  type = "list"
}

variable "bootstrap_name" {}

variable "bootstrap_uri" {}

variable "bootstrap_args" {
  default = []
  type    = "list"
}

variable "log_uri" {}

variable "step" {
  type = "map"

  default = {
    name              = "My Step"
    action_on_failure = "CONTINUE"
    jar               = "command-runner.jar"
  }
}

variable "step_args" {
  type    = "list"
  default = []
}
