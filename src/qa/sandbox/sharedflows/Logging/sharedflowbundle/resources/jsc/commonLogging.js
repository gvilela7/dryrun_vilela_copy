try{
    var flow = context.getVariable("flow");


    if(flow === "in.req")
        context.setVariable("logging.in.request",JSON.stringify(handleRequest("request")));

    else if (flow === "out.req")
        context.setVariable("logging.out.request",JSON.stringify(handleRequest("request")));

    else if(flow === "in.res")
        context.setVariable("logging.in.response",JSON.stringify(handleResponse("response")));

    else if (flow === "out.res"){
        context.setVariable("logging.out.response",JSON.stringify(handleResponse("response")));
        handleFinal();
    }

    else if (flow === "callout")
        handleCallout();

    else if (flow === "error")
        context.setVariable("logging.error",JSON.stringify(handleResponse("error")));
}
catch (e) {
    print("There was an error:",e);
    throw e;
}

function handleFinal(){
    print(context.getVariable("logging.in.request"));
    
    var inReq = JSON.parse(context.getVariable("logging.in.request") || null);
    var outRes = JSON.parse(context.getVariable("logging.out.response") || null);
    var outReq = JSON.parse(context.getVariable("logging.out.request") || null);
    var inRes = JSON.parse(context.getVariable("logging.in.response") || null);
    var callouts = JSON.parse(context.getVariable("logging.callouts") || null);
    var err = JSON.parse(context.getVariable("logging.error") || null);
    
    var proxy = {};
    if (inReq) proxy.request = inReq;
    if (outRes) proxy.response = outRes;
    
    // Calculate proxy total time
    var proxyStartTime = context.getVariable("client.received.end.timestamp");
    var proxyEndTime = Date.now();
    proxy.timeTaken = proxyEndTime - proxyStartTime;
    
    var target = {};
    if (outReq) {
        target.request = outReq;
        
        // Calculate target time
        var targetStartTime = context.getVariable("target.sent.end.timestamp");
        var targetEndTime = context.getVariable("target.received.end.timestamp");
        target.timeTaken = targetEndTime - targetStartTime;
    }
    if (inRes) target.response = inRes;
    
    var logAll = {test:"test"};
    if (proxy) logAll.proxy = proxy;
    if (target) logAll.target = target;
    if (callouts) logAll.callouts = callouts;
    if (err) logAll.error = err;
    
    context.setVariable("logging.all",JSON.stringify(logAll));
}

function handleRequest(reqVar){
    var log = {};
    log.path = context.getVariable(reqVar+".uri");
    log.verb = context.getVariable(reqVar+".verb");
    
    /**
     *    HANDLE PAYLOAD
     */
    var req = context.getVariable(reqVar+".content");
    if (req) log.payload= req;
    
    
    /**
     *    HANDLE HEADERS
     */
    var headerNames = context.getVariable(reqVar+".headers.names");
    if (headerNames){
        var headers = {};
    
        String(headerNames).slice(1,-1).split(/, ?/).forEach( function(hName){
            headers[hName] = context.getVariable(reqVar+".header."+hName+".values.string");
        });
        
        log.headers = headers;
    }
    
    
    /**
     *    HANDLE FORM PARAMS
     */
    var formParamNames = context.getVariable(reqVar+".formparams.names");
    if (formParamNames){
        var formParams = {};
    
        String(formParamNames).slice(1,-1).split(/, ?/).forEach( function(fpName){
            formParams[fpName] = context.getVariable(reqVar+".formparam."+fpName);
        });
        
        log.formParams = formParams;
    }
    
    
    /**
     *    HANDLE QUERY PARAMS
     */
    var queryParamNames = context.getVariable(reqVar+".queryparam.names");
    if (queryParamNames){
        var queryParams = {};
    
        String(queryParamNames).slice(1,-1).split(/, ?/).forEach( function(qpName){
            queryParams[qpName] = context.getVariable(reqVar+".queryparam."+qpName);
        });
        
        log.queryParams = queryParams;
    }

    return log;
}

function handleResponse(resVar){
    var log = {};
    
    log.status = context.getVariable(resVar+".status.code")+" "+context.getVariable(resVar+".reason.phrase");

    /**
     *    HANDLE PAYLOAD
     */
    var res = context.getVariable(resVar+".content");
    if (res) log.payload= res;
    
    
    /**
     *    HANDLE HEADERS
     */
    var headerNames = context.getVariable(resVar+".headers.names");
    if (headerNames){
        var headers = {};
    
        String(headerNames).slice(1,-1).split(/, ?/).forEach( function(hName){
            headers[hName] = context.getVariable(resVar+".header."+hName+".values.string");
        });
        
        log.headers = headers;
    }

    return log;
}

function handleCallout(){
    var calloutLog = {}
    var reqVar = context.getVariable("callout.req");
    var resVar = context.getVariable("callout.res");
    var calloutName = context.getVariable("callout.name");

    if(reqVar)
        calloutLog.request = handleRequest(reqVar);
    
    if(resVar)
        calloutLog.response = handleRequest(resVar);
    
    if(calloutName){
        calloutLog.name = calloutName;
        calloutLog.timeTaken = Math.round(context.getVariable("apigee.metrics.policy."+calloutName+".timeTaken")/1000000);
    }
    
    /**
     *    SET LOGGING OBJECT
     */
    var callouts = JSON.parse(context.getVariable("logging.callouts") || "[]");
    callouts.push(calloutLog);

    context.setVariable("logging.callouts",JSON.stringify(callouts));
}