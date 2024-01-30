echo ':::ALREADY INIT?'
if [ ! -f ~/.apigeecli/bin/apigeecli ];
then 
    echo ':::DOWNLOAD CLI TOOL'
    export APIGEECLI_VERSION=v1.120
    export APIGEECLI_NO_USAGE=true
    export APIGEECLI_NO_ERRORS=true
    curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | sh -
fi
echo ':::VALIDATE SERVICE ACCOUNT' 
[[ -z "$SERVICE_ACCOUNT" ]] && exit 1
echo ':::COPY SERVICE ACCOUNT'
echo $SERVICE_ACCOUNT > ~/serviceAccount.json
echo ':::GENERATE OAUTH2 TOKEN'
GCP_TOKEN=$(~/.apigeecli/bin/apigeecli token gen -a ~/serviceAccount.json)
echo "GCP_TOKEN=$GCP_TOKEN" >> $GITHUB_ENV
[[ -z "$GCP_TOKEN" ]] && exit 1
echo ':::SUCCESSFULL END'