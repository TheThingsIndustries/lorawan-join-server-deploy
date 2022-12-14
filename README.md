# The Things Join Server Deployment

This repository contains deployment templates for The Things Join Server.

1. Deploy cloud resources: [Amazon Web Services (AWS)](./aws)
2. [Deploy Helm chart](./helm-chart)

## After Deployment

### Use The Things Join Server CLI

Get started with [`ttjs` CLI](https://www.npmjs.com/package/ttjs-cli) to manage The Things Join Server. When you run `ttjs init`, use the following settings:

- **Server URL**: The public URL (`https://<domain>`)
- **Provisioner username**: `root` (default)
- **Provisioner password**: See deployment instructions

### The Things Join Server API

You can also work directly with the API. Go to [Swagger UI](https://petstore.swagger.io), enter `https://<domain>/v2/api/openapi.json` in the URL bar and click **Explore**. Click Authorize to authorize with the Provisioner username and password.

## Legal

Copyright © 2022 The Things Industries B.V.
