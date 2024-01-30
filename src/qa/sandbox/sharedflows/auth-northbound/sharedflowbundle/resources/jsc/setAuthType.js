const isJWT = !(context.getVariable("JWT.failed"));
const authorizationHeader = context.getVariable("request.header.authorization");
const apiKeyHeader = context.getVariable("request.header.x-api-key");
const publicKey = context.getVariable("private.publicKey");
const clientIdJWT = context.getVariable("jwt.JWT-Decode.decoded.claim.sub");

// HELLOOOOOO

try {
    var authType = "";

    if(authorizationHeader) {
        var authHeaderPrefix = authorizationHeader.toLowerCase().split(" ")[0];
        var authHeaderValue = authorizationHeader.split(" ").pop(); 
        
        if(isJWT && authHeaderPrefix.includes("bearer")){
            authType = publicKey !== null ? "jwt" : "jwks";
            context.setVariable("clientId", clientIdJWT);
        }
        else if(authHeaderPrefix.includes("basic"))
            authType = "basic";
        else  
            throw "Invalid auth method";
    }
    else if (apiKeyHeader !== null){
        authType = "apikey";
        context.setVariable("clientId", apiKeyHeader);
    }
    else  
        throw "Invalid auth method";
        
    context.setVariable("flow.northbound.authType", authType);
    context.setVariable("private.client.token", (authHeaderValue || apiKeyHeader));
    
} catch (err) {
    print(err);
    context.setVariable("flow.error", true);
    context.setVariable("flow.error.message", err);
}