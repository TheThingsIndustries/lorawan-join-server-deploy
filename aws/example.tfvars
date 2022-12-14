## AWS region
# region = "us-east-1"

## Custom resource names to keep multiple The Things Join Servers in the same AWS account apart.
# kms_alias_name_prefix = "alias/the-things-join-server"
# resource_prefix       = "the-things-join-server"
# ssm_parameter_prefix  = "the-things-join-server/v2"

## Additional IAM principals (users, roles) that can assume the role.
# assume_role_principals = [
#  "arn:aws:iam::123456789012:user/john-doe",
# ]

## Define Provisioners
# provisioners = {
#   "root" = {
#     name = "root"
#   }
# }

## Define Network Servers.
# network_servers = {
#   "000013" = {
#     name       = "The Things Stack Cloud and Community Edition"
#     truststore = "truststores/the-things-industries.pem"
#   }
#   "000000/EC656E0000000001" = {
#     name       = "Network Server 1"
#     truststore = "truststores/ns1.pem"
#   }
#   "000000/EC656E0000000002" = {
#     name       = "Network Server 2"
#     truststore = "truststores/ns2.pem"
#   }
# }

## Define Application Servers.
# application_servers = {
#   "example.com" = {
#     name       = "Application Server 1"
#     truststore = "as1-truststore.pem"
#   }
# }
