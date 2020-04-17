#!/usr/bin/env bash

set -e

# source:
# https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration#create-the-server-application


# create AD server application
# https://docs.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest
# --password == Certificates & secrets >> New client secret
echo "Creating server application..."
az ad app create \
    --display-name "${AD_SERVER_APP_NAME}" \
    --password "${AD_SERVER_APP_SECRET}" \
    --identifier-uris "${AD_SERVER_APP_URL}" \
    --reply-urls "${AD_SERVER_APP_URL}" \
    --homepage "${AD_SERVER_APP_URL}" \
    --required-resource-accesses @manifest.json

# Application (client) ID
# if more apps with similar name - error
AD_SERVER_APP_ID=$(az ad app list --display-name $AD_SERVER_APP_NAME --query [].appId -o tsv)
AD_SERVER_APP_OAUTH2PERMISSIONS_ID=$(az ad app show --id $AD_SERVER_APP_ID --query oauth2Permissions[0].id -o tsv)

# update the application 'groupMembershipClaims'
az ad app update --id ${AD_SERVER_APP_ID} --set groupMembershipClaims=All

# create service principal for the server application
echo "Creating service principal for the server application..."
az ad sp create --id ${AD_SERVER_APP_ID}

# grant 'API permissions' (in UI: AD >> your app >> API permissions) to the server application
echo "Granting permissions to the server application..."
# User.Read (Sign in and read user profile)
# Directory.Read.All (Read directory data)
AD_SERVER_APP_RESOURCES_API_IDS=$(az ad app permission list --id $AD_SERVER_APP_ID --query [].resourceAppId --out tsv | xargs echo)
for RESOURCE_API_ID in $AD_SERVER_APP_RESOURCES_API_IDS;
do
  if [ "$RESOURCE_API_ID" == "00000002-0000-0000-c000-000000000000" ]
  then
    az ad app permission grant --api $RESOURCE_API_ID --id $AD_SERVER_APP_ID --scope "User.Read"
  elif [ "$RESOURCE_API_ID" == "00000003-0000-0000-c000-000000000000" ]
  then
    az ad app permission grant --api $RESOURCE_API_ID --id $AD_SERVER_APP_ID --scope "Directory.Read.All"
  else
    az ad app permission grant --api $RESOURCE_API_ID --id $AD_SERVER_APP_ID --scope "user_impersonation"
  fi
done

echo "
Server application has been created. To grant permission follow these steps:
Azure Active Directory >> App registrations >> App >> API permissions >> Grant admin consent
"
echo "Use these variables when running the client application creation script:"
echo "
export AD_SERVER_APP_ID="${AD_SERVER_APP_ID}"
export AD_SERVER_APP_OAUTH2PERMISSIONS_ID="${AD_SERVER_APP_OAUTH2PERMISSIONS_ID}"
export AD_SERVER_APP_SECRET="${AD_SERVER_APP_SECRET}"
"