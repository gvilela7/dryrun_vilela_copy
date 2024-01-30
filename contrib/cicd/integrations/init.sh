echo ':::ALREADY INIT?'
if [ ! -f ~/.integrationcli/bin/integrationcli ];
then 
    echo ':::DOWNLOAD CLI TOOL'
    export INTEGRATIONCLI_VERSION=v0.70
    curl -L https://raw.githubusercontent.com/GoogleCloudPlatform/application-integration-management-toolkit/main/downloadLatest.sh | sh -
fi
echo ':::VALIDATE SERVICE ACCOUNT' 
[[ -z "$SERVICE_ACCOUNT" ]] && exit 1 
echo ':::COPY SERVICE ACCOUNT' 
echo $SERVICE_ACCOUNT > ~/serviceAccount.json 
echo ':::GENERATE OAUTH2 TOKEN' 
GCP_TOKEN=$(~/.integrationcli/bin/integrationcli token gen -a ~/serviceAccount.json)
echo "GCP_TOKEN=$GCP_TOKEN" >> $GITHUB_ENV
[[ -z "$GCP_TOKEN" ]] && exit 1
echo ':::SUCCESSFULL END'
