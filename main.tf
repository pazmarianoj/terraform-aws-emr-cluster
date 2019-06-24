#
# EMR IAM resources
#
data "aws_iam_policy_document" "emr_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "emr_service_role" {
  name               = "emr${var.environment}ServiceRole"
  assume_role_policy = "${data.aws_iam_policy_document.emr_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "emr_service_role" {
  role       = "${aws_iam_role.emr_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

resource "aws_iam_role_policy_attachment" "ssm_service_role" {
  role       = "${aws_iam_role.emr_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

#
# EMR IAM resources for EC2
#
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "emr_ec2_instance_profile" {
  name               = "${var.environment}JobFlowInstanceProfile"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "emr_ec2_instance_profile" {
  role       = "${aws_iam_role.emr_ec2_instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "emr_ec2_instance_profile_custom_policies" {
  count      = "${var.custom_policy_count}"
  policy_arn = "${element(var.custom_policy_arns, count.index)}"
  role       = "${aws_iam_role.emr_ec2_instance_profile.name}"
}

resource "aws_iam_instance_profile" "emr_ec2_instance_profile" {
  name = "${aws_iam_role.emr_ec2_instance_profile.name}"
  role = "${aws_iam_role.emr_ec2_instance_profile.name}"
}

#
# Security group resources
#
resource "aws_security_group" "emr_master" {
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = true

  tags {
    Name        = "sg${var.name}Master"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

resource "aws_security_group" "emr_slave" {
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = true

  tags {
    Name        = "sg${var.name}Slave"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}

#
# EMR resources
#
resource "aws_emr_cluster" "cluster" {
  name                              = "${var.name}"
  release_label                     = "${var.release_label}"
  applications                      = "${var.applications}"
  configurations                    = "${var.configurations}"
  keep_job_flow_alive_when_no_steps = "${var.keep_job_flow_alive_when_no_steps}"

  ec2_attributes {
    key_name                          = "${var.key_name}"
    subnet_id                         = "${var.subnet_id}"
    service_access_security_group     = "${var.service_access_security_group_id}"
    additional_master_security_groups = "${var.additional_master_security_group_id}"
    additional_slave_security_groups  = "${var.additional_slave_security_group_id}"
    emr_managed_master_security_group = "${aws_security_group.emr_master.id}"
    emr_managed_slave_security_group  = "${aws_security_group.emr_slave.id}"
    instance_profile                  = "${aws_iam_instance_profile.emr_ec2_instance_profile.arn}"
  }

  step {
    action_on_failure = "TERMINATE_CLUSTER"

    "hadoop_jar_step" {
      jar  = "command-runner.jar"
      args = ["state-pusher-script"]
    }

    name = "Setup Hadoop Debugging"
  }

  instance_group = "${var.instance_groups}"

  bootstrap_action = "${var.bootstrap_actions_list}"

  log_uri      = "${var.log_uri}"
  service_role = "${aws_iam_role.emr_service_role.arn}"

  tags {
    Name        = "${var.name}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}
