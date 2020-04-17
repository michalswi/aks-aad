#!/usr/bin/env bash

set -e

# source:
# https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration#create-the-client-application


# generate manifest for client application

cat > ./manifest-client.json << EOF
[
  {
    "resourceAppId": "${AD_SERVER_APP_ID}",
    "resourceAccess": [
      {
        "id": "${AD_SERVER_APP_OAUTH2PERMISSIONS_ID}",
        "type": "Scope"
      }
    ]
  }
]
EOF

# [optional] but it works too:

# cat > ./manifest-client.json << EOF
# [
#   {
#     "resourceAppId": "${AD_SERVER_APP_ID}",
#     "resourceAccess": [
#       {
#         "id": "${AD_SERVER_APP_OAUTH2PERMISSIONS_ID}",
#         "type": "Scope"
#       }
#     ]
#   },
#   {
#     "resourceAppId": "00000003-0000-0000-c000-000000000000",
#     "resourceAccess": [
#       {
#         "id": "e1fe6dd8-ba31-4d61-89e7-88639da4683d",
#         "type": "Scope"
#       }
#     ]
#   }
# ]
# EOF

# check manifest
cat manifest-client.json

# create AD client application
echo "Creating client application..."
az ad app create --display-name ${AD_CLIENT_APP_NAME} \
    --native-app \
    --reply-urls "${AD_CLIENT_APP_URL}" \
    --homepage "${AD_CLIENT_APP_URL}" \
    --required-resource-accesses @manifest-client.json

# Application (client) ID
AD_CLIENT_APP_ID=$(az ad app list --display-name ${AD_CLIENT_APP_NAME} --query [].appId -o tsv)

# create service principal for the client application
echo "Creating service principal for the client application..."
az ad sp create --id ${AD_CLIENT_APP_ID}

# remove manifest-client.json
rm -rf ./manifest-client.json

# grant 'API permissions' (in UI: AD >> your app >> API permissions) to the client application
echo "Granting permissions to the client application..."
AD_CLIENT_APP_RESOURCES_API_IDS=$(az ad app permission list --id $AD_CLIENT_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $AD_CLIENT_APP_RESOURCES_API_IDS;
do
  az ad app permission grant --api $RESOURCE_API_ID --id $AD_CLIENT_APP_ID
done

# output terraform variables for AKS
echo "
Client application has been created.
"
echo "Use these variables when running terraform to deploy AKS:"
echo "
export TF_VAR_rbac_server_app_id="${AD_SERVER_APP_ID}"
export TF_VAR_rbac_server_app_secret="${AD_SERVER_APP_SECRET}"
export TF_VAR_rbac_client_app_id="${AD_CLIENT_APP_ID}"
"