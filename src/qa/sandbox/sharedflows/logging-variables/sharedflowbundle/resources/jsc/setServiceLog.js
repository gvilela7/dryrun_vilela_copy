function maskJsonFields(jsonObj, sensibleFields) {
    return JSON.stringify(
        JSON.parse(jsonObj),
        ((key, value) => !sensibleFields.includes(key) ? value : "******")
    );
}

function maskFormFields(form, sensibleFields) {
    // Get form fields as key=pair list
    var entries = form.split('&');

    return entries.map(entry => {
        var [key, value] = entry.split('=');

        // Verify if key exists in sensibleFields list and mask its value
        return key + "=" + (sensibleFields.includes(key) ? "********" : value)
    }).join('&');
}


function getHeaders(varName){
    var requestHeaders = context.getVariable(varName+".headers.names"),
        result = {};
    
    // requestHeaders is a java.util.TreeMap$KeySet; convert it to string
    requestHeaders = requestHeaders + '';
    
    // convert from "[A, B, C]" to an array of strings: ["A", "B", "C"]
    requestHeaders = requestHeaders.slice(1, -1).split(', ');
    
    // insert each header into the response
    requestHeaders.forEach(function(name){
      if(name.toLowerCase() === "authorization" || name.toLowerCase() === "x-api-key"){
          result[name] = "**********";
      } else {
        result[name] = context.getVariable(varName+".header." + name + ".values.string" );
      }
    });
    
    // set the jsreqheaders variable:
    return JSON.stringify(result, null, 2);
}


try {
    var servicesLogs = context.getVariable("servicesLogs");
    if (servicesLogs){
        servicesLogs = JSON.parse(servicesLogs);
    } else {
        servicesLogs = [];
    }
    
    if(context.getVariable("chooseFlow") === "LogServiceCallout" ){
        var sc_policyName = context.getVariable("sc_policyName");
        var sc_requestVarName = context.getVariable("sc_requestVarName");
        var sc_requestVar = context.getVariable("sc_requestVar");
        var sc_responseVarName = context.getVariable("sc_responseVarName");
        
        var targetRequestBody = context.getVariable(sc_requestVarName + ".content");
        var targetResponseBody = context.getVariable(sc_responseVarName + ".content");
        
        if(sc_policyName === "SC-GetSouthboundToken") { // Southbound Auth masking
            var sensibleFieldsResponse = ["access_token", "accessToken", "client_secret", "clientSecret"];
            targetResponseBody = maskJsonFields(targetResponseBody, sensibleFieldsResponse);
            targetRequestBody = maskFormFields(targetRequestBody, ["client_secret"]);
        } else if(sc_policyName === "SC-VerifyToken") { // Northbound Auth masking
            targetRequestBody = maskFormFields(targetRequestBody, ["token"]);
        }
        
        servicesLogs.push({
            "targetType": "ServiceCallout",
            "targetRequestSent": context.getVariable("sc_targetRequestSent"),
            "targetResponseReceived": context.getVariable("sc_targetResponseReceived"),
            "targetUri": context.getVariable("servicecallout.requesturi"),
            "targetOperation": context.getVariable(sc_requestVarName+".verb"),
            "targetRequestBody": targetRequestBody,
            "targetRequestHeaders ": getHeaders(sc_requestVarName),
            "targetRequestQuerystring": context.getVariable(sc_requestVarName+".querystring"),
            "targetResponseStatusCode": context.getVariable(sc_responseVarName+".status.code"),
            "targetResponseReasonPhrase": context.getVariable(sc_responseVarName+".reason.phrase"),
            "targetResponseBody": targetResponseBody,
            "targetResponseHeaders ": getHeaders(sc_responseVarName),
            "targetRequestId": context.getVariable(sc_requestVarName+".x-request-apim-id.values.string"),
            "targetResponseId": context.getVariable(sc_responseVarName+".header.x-request-apim-id")
        });
        
    } else {
        if (!servicesLogs.find(element => element.targetType === "TargetEndpoint")){
            var apimId = context.getVariable("response.header.x-request-apim-id");
            //var producerId = context.getVariable("response.header.x-request-id");
            servicesLogs.push({
                "targetType": "TargetEndpoint",
                "targetRequestSent": context.getVariable("target.sent.end.timestamp"),
                "targetResponseReceived": context.getVariable("target.received.end.timestamp"),
                "targetUri": context.getVariable("toTarget.uri"),
                "targetOperation": context.getVariable("toTarget.verb"),
                "targetRequestBody": context.getVariable("toTarget.body"),
                "targetRequestHeaders ": context.getVariable("toTarget.headers"),
                "targetRequestQuerystring": context.getVariable("toTarget.querystring"),
                "targetResponseStatusCode": context.getVariable("fromTarget.status.code"),
                "targetResponseReasonPhrase": context.getVariable("fromTarget.reason.phrase"),
                "targetResponseBody": context.getVariable("fromTarget.body"),
                "targetResponseHeaders ": context.getVariable("fromTarget.headers"),
                "targetRequestId": context.getVariable("request.header.x-request-apim-id.values.string"),
                "targetResponseId": apimId //(apimId ? apimId : producerId )
            });
        }
    }

    
    context.setVariable("servicesLogs", JSON.stringify(servicesLogs));
    context.setVariable("js.isError", false);

} catch (e) {
    print(e);
    context.setVariable("js.errorMsg", JSON.stringify(e));
    context.setVariable("js.isError", true);
    throw e;
}