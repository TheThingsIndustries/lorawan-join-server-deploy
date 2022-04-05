## AWS region
region = "us-east-1"

## Uncomment to use the snapshot release of The Things Join Server.
# release_channel = "snapshot"

## Custom resource names to keep multiple The Things Join Servers in the same AWS account apart.
# kms_alias_name_prefix = "alias/lorawan-join-server"
# resource_prefix       = "lorawan-join-server"
# ssm_parameter_prefix  = "lorawan/joinserver/v1"
# iot_thing_type        = "lorawan-join-server"

## Define Network Servers.
## NOTE: You can also dynamically manage Network Servers through the API and CLI.
# networks = {
#   "000000" = {
#     name = "Network 1"
#     kek = {
#       label = "Test Label"
#       key   = "11223344556677881122334455667788"
#     }
#     passwords = {
#       primary = "secret"
#     }
#   }
#   "000013" = {
#     name = "The Things Network"
#     kek = {
#       label = "Test Label"
#       key   = "11223344556677881122334455667788"
#     }
#     passwords = {
#       primary   = "secret1"
#       secondary = "secret2"
#     }
#   }
# }

## Define Application Servers.
## NOTE: You can also dynamically manage Application Servers through the API and CLI.
# applications = {
#   "example.com" = {
#     name = "Application 1"
#     kek = {
#       label = "Test Label"
#       key   = "11223344556677881122334455667788"
#     }
#     passwords = {
#       primary = "secret"
#     }
#   }
# }
