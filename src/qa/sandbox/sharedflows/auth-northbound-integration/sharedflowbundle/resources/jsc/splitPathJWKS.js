var audArr = context.getVariable('jwt.JWT-Decode.claim.audience');
var url = context.getVariable('jwks-endpoint');

try {
    if(!url)
        throw "JWKS endpoint not found";
    
    // Split URL between hostname and path
    var urlAsArr = url.split('/');
    var host = urlAsArr.shift();
    var path = urlAsArr.join('/');
    
    //Decoded audience
    var audience = audArr.replace("[", "").replace("]", "");
    
    context.setVariable('jwks.host', host);
    context.setVariable('jwks.path', path);
    
    context.setVariable('audience.decoded', audience);    
} catch (err) {
    print(err);
    context.setVariable("flow.error", true);
    context.setVariable("flow.error.message", err);
}