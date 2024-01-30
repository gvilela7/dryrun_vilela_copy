 /* April, 2023 */

//__________Main__________


try {
    // Initialization
    var apimRequest_content = context.getVariable('request.content');
    var apimRequest = JSON.parse(apimRequest_content);
    context.setVariable("apimRequest", apimRequest_content);

    for (var price in apimRequest.productPrice){
        if (!apimRequest.productPrice[price].productCharacteristic) continue; // Skipping empty objects
    
        for (var entry in apimRequest.productPrice[price].productCharacteristic){
            if (typeof apimRequest.productPrice[price].productCharacteristic[entry].value != "string")
                apimRequest.productPrice[price].productCharacteristic[entry].value = JSON.stringify(apimRequest.productPrice[price].productCharacteristic[entry].value);
        }
    }

    // Apply the changes
    context.setVariable("request.content", JSON.stringify(apimRequest));

    context.setVariable("js.isError", false);

} catch (e) {
    print(e);
    context.setVariable("js.errorMsg", JSON.stringify(e));
    context.setVariable("js.isError", true);
}