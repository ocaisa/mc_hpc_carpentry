terraform {
  required_version = ">= 1.1.0"
  backend "remote" {
    organization = "EESSI"

    workspaces {
      name = "AWS"
    }
  }
}

module "aws" {
  source         = "./aws"
  config_git_url = "https://github.com/ComputeCanada/puppet-magic_castle.git"
  config_version = "11.9.1"

  cluster_name = "rhubard"
  domain       = "learnhpc.eu"
  # Rocky Linux 8 -  ca-central-1
  # https://rockylinux.org/cloud-images
  # image        = "ami-09ada793eea1559e6"
  image        = "ami-079f4c25253b27e9d" # Rocky 8 -  eu-central-1

  instances = {
    mgmt  = { type = "t3.large",  count = 1, tags = ["mgmt", "puppet", "nfs"] },
    login = { type = "t3.medium", count = 1, tags = ["login", "public", "proxy"] },
    node  = { type = "t3.medium", count = 2, tags = ["node", "spot"] }
  }

  volumes = {
    nfs = {
      home     = { size = 10, type = "gp2" }
      project  = { size = 50, type = "gp2" }
      scratch  = { size = 50, type = "gp2" }
    }
  }

  generate_ssh_key = true
  public_keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeIVruM+biV5n0hipfLyJAJss0RdaxVSTEtgCMPyVmOCmaHFNK/IwOQfLBRrcl8tKFhXBNIkQMae/k3VA7SbH+axuSVKsu2Zb/DhtpFuGTpQiMrcQHOp3Vig1Wz1nRgC5iWjs5dx9vc0bqGBL7SDghz1Pgr+x9t8KzftzVZOQR8BXrH9asNtYIzlJ2XB+2Xayr+8UxzQh7FNgUOxk1QzjQ51ppzJR+fgn2Ie92+4inkmyDSzWVOnOaBXb3fUp6QGSBWjdRj/kBWkGClveGF+ZrpF3KFaCSCYHw+5AbwUa8vaa3tkqFchgDPHssxmEvf0JSsoJaU5Ywz/mnIIFxyHvm0Ce/4zenFo89ZRknJw2Njk4hPFi9CbKuvjg4Qb3Mb1YUXrqK1AvJxIM5V2s2yeez5nxlQD1wBMjXTXZubyBTBAq6z8ejTDa3x/dJKLSuR84bU14aXv9/bu5negaEwOo8TTuv36dY9YBzG1Yv2TeW7WmrMCti9w1w66g97+zEEI0Ijosek7HJVRNf1lZRt/A2jftXWk8Sxq5BO3RcOeBcX2gJZ+kq0hRLYD+8hGKc6fV369QxAv+ZRJ9CUVsgUExeSS2zbcwnqrUM0HJT1PbTTcfQwJmTPMIqg0g9ETOoY2xsD0rRtVhW1NAMlrw2aIKBcqFSwLXfawgGPmnLZK16Lw== alanc@alanc-VirtualBox"]

  nb_users     = 1
  # Shared password, randomly chosen if blank
  guest_passwd = ""

  software_stack = "eessi"

  # AWS specifics
  region            = "eu-central-1"
}

output "accounts" {
  value = module.aws.accounts
}

output "public_ip" {
  value = module.aws.public_ip
}

## Uncomment to register your domain name with CloudFlare
module "dns" {
  source           = "./dns/cloudflare"
  email            = "alan.ocais@gmail.com"
  name             = module.aws.cluster_name
  domain           = module.aws.domain
  public_instances = module.aws.public_instances
  ssh_private_key  = module.aws.ssh_private_key
  sudoer_username  = module.aws.accounts.sudoer.username
}

## Uncomment to register your domain name with Google Cloud
# module "dns" {
#   source           = "./dns/gcloud"
#   email            = "you@example.com"
#   project          = "your-project-id"
#   zone_name        = "you-zone-name"
#   name             = module.aws.cluster_name
#   domain           = module.aws.domain
#   public_instances = module.aws.public_instances
#   ssh_private_key  = module.aws.ssh_private_key
#   sudoer_username  = module.aws.accounts.sudoer.username
# }

output "hostnames" {
	value = module.dns.hostnames
}
