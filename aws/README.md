# Terraform Configuration for The Things Join Server in AWS

This folder contains Terraform Configuration for deploying The Things Join Server in on an AWS Elastic Kubernetes Service (EKS) cluster in your AWS account.

Prerequisites:

- Terraform 1.3.4 or higher ([download](https://www.terraform.io/downloads))
- AWS Elastic Kubernetes Service (EKS) cluster ([documentation](https://aws.amazon.com/eks/getting-started/))
- Administrator access to an AWS account

## Usage

```hcl
module "joinserver" {
  source = "/path/to/lorawan-join-server-deploy/aws"
  
  # EKS cluster name
  eks_cluster_name = "thethingslabs"

  # Kubernetes namespace
  kubernetes_namespace = "joinserver"

  # Custom resource names to keep multiple The Things Join Servers in the same AWS account apart.
  # kms_alias_name_prefix = "alias/the-things-join-server"
  # resource_prefix       = "the-things-join-server"
  # ssm_parameter_prefix  = "the-things-join-server/v2"
  
  # Additional IAM principals (users, roles) that can assume the role.
  # assume_role_principals = [
  #  "arn:aws:iam::123456789012:user/john-doe",
  # ]
  
  # Define Provisioners
  provisioners = {
    "root" = {
      name = "root"
    }
  }
  
  # Define Network Servers.
  network_servers = {
    "000013" = {
      name       = "The Things Stack Cloud and Community Edition"
      truststore = "/path/to/lorawan-join-server-deploy/aws/truststores/the-things-industries.pem"
    }
    "000000/EC656E0000000001" = {
      name       = "Network Server 1"
      truststore = "truststores/ns1.pem"
    }
    "000000/EC656E0000000002" = {
      name       = "Network Server 2"
      truststore = "truststores/ns2.pem"
    }
  }
  
  # Define Application Servers.
  application_servers = {
    "example.com" = {
      name       = "Application Server 1"
      truststore = "truststores/as1-truststore.pem"
    }
  }
}

output "provisioner_passwords" {
  value     = module.joinserver.provisioner_passwords
  sensitive = true
}

output "server_role_arn" {
  value = module.joinserver.server_role_arn
}
```

## Next Steps

### Deploy The Things Join Server

You can see the IAM role ARN with `terraform output server_role_arn`. This role ARN is needed for The Things Join Server deployments.

Deploy The Things Join Server using the Helm chart, [see instructions](../helm-chart/README.md).

### Configure Provisioners

You can see the provisioner passwords with `terraform output provisioner_passwords`.

## Legal

Copyright © 2022 The Things Industries B.V.
