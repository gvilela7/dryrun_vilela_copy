var errorMessage = context.getVariable("errorMessage");
if(context.getVariable("fault.name")){
    errorMessage["faultName"] = context.getVariable("fault.name");
}
if(context.getVariable("fromTarget.error.content")){
    errorMessage["target.error.content"] = context.getVariable("fromTarget.error.content");
}
if(context.getVariable("fromTarget.error.message")){
    errorMessage["target.error.message"] = context.getVariable("fromTarget.error.message");
}
if(context.getVariable("toTarget.querystring")){
    errorMessage["targetRequestQuerystring"] = context.getVariable("toTarget.querystring");
}
if(context.getVariable("response.header.content-length")){
    errorMessage["proxyResponseBodySize"] = context.getVariable("response.header.content-length");
}
if(context.getVariable("fromClient.querystring")){
    errorMessage["clientRequestQuerystring"] = context.getVariable("fromClient.querystring");
}
if(context.getVariable("toTarget.received.end.timestamp")){
    errorMessage["targetResponseReceived"] = context.getVariable("toTarget.received.end.timestamp");
}
context.setVariable("errorMessage",errorMessage);