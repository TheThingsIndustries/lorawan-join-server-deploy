# Terraform Configuration for The Things Join Server in AWS

This folder contains Terraform Configuration for deploying The Things Join Server in your AWS account.

Prerequisites:

- Terraform 1.1.7 or higher ([download](https://www.terraform.io/downloads))
- Administrator access to an AWS account

## Preparation

This repository uses the default local Terraform Backend. However, it is recommended to use a Terraform Backend to store state. See [Terraform Backends](https://www.terraform.io/language/settings/backends) for more information.

Before proceeding, make sure the Backend is accessible and all dependencies are installed:

```bash
$ terraform init
```

## Configuration

There are various variables to configure The Things Join Server deployment. The most important variables:

| Name              | Description                               | Default                               |
| ----------------- | ----------------------------------------- | ------------------------------------- |
| `region`          | AWS region                                | `eu-west-1`                           |
| `domain`          | Custom domain name                        | none                                  |
| `public_url`      | Public URL                                | `https://<domain>` or API Gateway URL |
| `release_channel` | Version to deploy: `stable` or `snapshot` | `stable`                              |
| `networks`        | LoRaWAN Network Servers                   | none                                  |
| `applications`    | LoRaWAN Application Servers               | none                                  |

Besides these variables, you can configure the resource prefixes and AWS IoT Core Thing Type name to keep multiple deployments of The Things Join Server in the same AWS account apart. It is recommended to use different AWS accounts for different The Things Join Server deployments.

For convenience, you can start your custom configuration from the example configuration:

```bash
$ cp example.tfvars custom.tfvars
```

### Optional: Custom domain name

Use the `domain` variable to use a custom domain name, like `join.example.com`.

When using a custom domain, a certificate with AWS Certificate Manager (ACM) will be requested. This certificate uses DNS validation for proof of ownership of the domain name. During the deployment process, you have 45 minutes to verify the ownership of the domain name by creating a CNAME record for the DNS validation. [See DNS validation documentation](https://docs.aws.amazon.com/acm/latest/userguide/dns-validation.html).

After you have deployed The Things Join Server with a custom domain name, create a DNS CNAME record for your domain with the Terraform output value `domain_target`.

If you do not configure a custom domain, the public AWS API Gateway invocation URL will be used.

### Optional: Networks and Applications

You can optionally configure LoRaWAN Network Servers and Application Servers through Terraform Configuration. The Things Join Server also supports management of Network Servers and Application Servers via the API and [`ttjs` CLI](https://www.npmjs.com/package/ttjs-cli).

If you wish to declare Network Servers and Application Servers via Terraform, you can do so in your `custom.tfvars` file.

## Deploy

Deploy:

```bash
$ terraform apply -var-file custom.tfvars
```

You should see all resources being deployed. This may take a few minutes. When the deployment is done, you see various outputs specific to your deployment.

> 🎉 Congratulations! You have now deployed The Things Join Server.

## Next Steps

The Things Join Server uses HTTP Basic Authentication to authenticate Provisioners, Network Servers and Application Servers.

The Terraform Configuration deploys a Provisioner with username `root` and a random password. You can obtain the password for `root` via:

```bash
$ terraform output -raw root_provisioner_password
```

### Use The Things Join Server CLI

Get started with [`ttjs` CLI](https://www.npmjs.com/package/ttjs-cli) to manage The Things Join Server. When you run `ttjs init`, use the following settings:

- **Server URL**: Terraform output `url`
- **Configure Provisioner**: on
- **Provisioner username**: `root`
- **Provisioner password**: Terraform output `root_provisioner_password`

### The Things Join Server API

You can also work directly with the API. Go to [Swagger UI](https://petstore.swagger.io), copy the Terraform output `openapi_url` in the URL bar and click **Explore**. Click Authorize to authorize with the Provisioner username and password.

The API can also be used by Network Server and Application Server operators. They authorize with their own credentials.

## Update

You can pull this repository for updates to the Terraform Configuration. To apply updates:

```bash
# See if everything looks good:
$ terraform plan -var-file custom.tfvars
# Apply the update:
$ terraform apply-var-file custom.tfvars
```

You can also update the AWS Lambda function code by running the update script:

```bash
$ ./update.sh
```

This updates the AWS Lambda functions to using the latest The Things Join Server code available in the configured release channel.

## Destroy

To remove all resources of The Things Join Server:

```bash
$ terraform destroy -var-file custom.tfvars
```

If you have dynamically created Network Servers and Application Servers through the CLI or API, you may still need to delete Parameters from AWS Systems Manager. In the AWS Console, go to Systems Manager and then Parameter Store. The concerning Parameters start with the `ssm_parameter_prefix` Terraform variable, by default `lorawan/joinserver/v1`.

## Legal

Copyright © 2022 The Things Industries B.V.
