provider "aws" {
  region      = "us-east-1"
}

# #VPC
# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"
#   version = "3.19.0"
#   name = "CustomVPC"
#   cidr = "10.0.0.0/16"

#   azs             = ["us-east-1a", "us-east-1b"]
#   private_subnets = ["10.0.128.0/20", "10.0.144.0/20"]
#   public_subnets  = ["10.0.0.0/20", "10.0.16.0/20"]

#   create_igw = true

#   //manage_default_security_group = true
# }

# #Security group for LB
# resource "aws_security_group" "load_balancer_security_group" {
#   name              = "load_balancer_security_group"
#   description       = "load_balancer_security_group"
#   vpc_id            = module.vpc.vpc_id
# }

# #Allows traffic to port 80
# resource "aws_security_group_rule" "http_for_load_balancer" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.load_balancer_security_group.id
# }
# #Allows accessing to the internet
# resource "aws_security_group_rule" "egress_for_load_balancer" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.load_balancer_security_group.id
# }

# #Security group for LB
# resource "aws_security_group" "security_group_ec2" {
#   name              = "security_group_ec2"
#   description       = "security_group_ec2"
#   vpc_id            = module.vpc.vpc_id
# }
# #Security group rules
# #Allows connecting to port 80
# resource "aws_security_group_rule" "http_ec2" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   source_security_group_id =  aws_security_group.load_balancer_security_group.id #Allows access from the load balancer security group
#   security_group_id = aws_security_group.security_group_ec2.id
# }
# #Allows connecting to the instance from ssh
# resource "aws_security_group_rule" "ssh_ec2" {
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.security_group_ec2.id
# }

# #Allows accessing to the internet
# resource "aws_security_group_rule" "egress_ec2" {
#   type              = "egress"
#   from_port         = 0
#   to_port           = 0
#   protocol          = "-1"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.security_group_ec2.id
# }

#KEYPAIR_custom
resource "tls_private_key" "rsa" {
  algorithm         = "RSA"
  rsa_bits          = 4096
}

resource "aws_key_pair" "customkey" {
  key_name          = "customkey"
  public_key        = tls_private_key.rsa.public_key_openssh
}


resource "local_file" "customkeypair" {
  filename          = "customkey.pem"
  content           = tls_private_key.rsa.private_key_pem
  file_permission   = "0400"
}

resource "aws_secretsmanager_secret" "customkey" {
  name = "keypair_customkey"
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.customkey.id
  secret_string = tls_private_key.rsa.private_key_pem
}
# #Application load balancer
# resource "aws_lb" "hellolb" {
#   name               = "MyHelloLB"
#   internal           = false

#   load_balancer_type = "application"
#   ip_address_type   = "ipv4"
#   subnets = [module.vpc.public_subnets[0],module.vpc.public_subnets[1]]

#   security_groups    = toset([aws_security_group.load_balancer_security_group.id])

#   enable_deletion_protection = false

#   tags = {
#     Environment = "production"
#   }
# }

# resource "aws_lb_target_group" "hellolb_target_group" {
#   name     = "myhellolbtargetgroup"
#   port     = 80
#   protocol = "HTTP"
#   target_type = "instance"
#   vpc_id   = module.vpc.vpc_id
#   health_check {
#     healthy_threshold = 2
#     unhealthy_threshold = 2
#   }
# }

# resource "aws_lb_listener" "hellolb_listener" {
#   load_balancer_arn = aws_lb.hellolb.arn
#   port              = "80"
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.hellolb_target_group.arn
#   }
# }

# # Creating the autoscaling launch template that contains AWS EC2 instance details
# resource "aws_launch_template" "aws_autoscale_conf" {
# # Defining the name of the Autoscaling launch configuration
#   name          = "web_config"
# # Defining the image ID of AWS EC2 instance
#   image_id      = "ami-0fec2c2e2017f4e7b" #Debian 11
# # Defining the instance type of the AWS EC2 instance
#   instance_type = "t2.micro"
# # Defining the Key that will be used to access the AWS EC2 instance
#   key_name = "customkey"
#   user_data = filebase64("${path.module}/install_user_data.sh")
#   vpc_security_group_ids = toset([aws_security_group.security_group_ec2.id])

#   depends_on = [
#     aws_key_pair.customkey
#   ]

# }

# # Creating the autoscaling group within us-east-1a availability zone
# resource "aws_autoscaling_group" "autoscale_group" {
# # Defining the availability Zone in which AWS EC2 instance will be launched
#   vpc_zone_identifier = [module.vpc.public_subnets[0],module.vpc.public_subnets[1]]
# # Specifying the name of the autoscaling group
#   name                      = "autoscale_group"
# # Defining the maximum number of AWS EC2 instances while scaling
#   max_size                  = 6
# # Defining the minimum number of AWS EC2 instances while scaling
#   min_size                  = 2
#   desired_capacity          = 2
# # Grace period is the time after which AWS EC2 instance comes into service before checking health.
#   health_check_grace_period = 30
# # The Autoscaling will happen based on health of AWS EC2 instance defined in AWS CLoudwatch Alarm 
#   health_check_type         = "EC2"
# # force_delete deletes the Auto Scaling Group without waiting for all instances in the pool to terminate
#   force_delete              = true
# # Defining the termination policy where the oldest instance will be replaced first 
#   termination_policies      = ["OldestInstance"]
# # Scaling group is dependent on autoscaling launch configuration because of AWS EC2 instance configurations
#   launch_template       {
#     id = aws_launch_template.aws_autoscale_conf.id
#     version = "$Latest"
#   }
#   #Load balancer
#   target_group_arns = toset([aws_lb_target_group.hellolb_target_group.arn])
  
# }
# #Policy for autoscaling
# resource "aws_autoscaling_policy" "autoscale_policy" {
#   name                   = "autoscale_policy"
#   policy_type            = "TargetTrackingScaling"
#   estimated_instance_warmup = 10
#   target_tracking_configuration  {
#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = "20"
#   }
#   autoscaling_group_name = aws_autoscaling_group.autoscale_group.name
# }
