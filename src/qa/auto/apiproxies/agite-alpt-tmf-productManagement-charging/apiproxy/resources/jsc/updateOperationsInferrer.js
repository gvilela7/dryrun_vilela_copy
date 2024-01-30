/* March, 2023 */

//__________Utility Functions__________

function isObjectEmpty(objectName) {
    return Object.keys(objectName).length === 0;
}


//__________Main__________

function calculateOperationTypes(existingData, request){
    // Existing Prices yet to be evaluated. Will be Modified or Removed
    var existingPrices = {
        "Usage Charge": {},
        "Topup": {},
        "Allowance": {},
        "Spending Limit": {},
        "Alarm": {},
        "Recurring Charge": {},
        "Balance Inquiry": {},
        "One Time Allowance": {},
        "One Time Charge": {}
    };
    
    if(!request.productPrice) request.productPrice = [];

    var price; // price obj being evaluated in the current iteration
    
    // Store all existing Prices to evaluate by their Type and ID.
    // These will be Modified or Removed.
    for (var i in existingData.productPrice){
        price = existingData.productPrice[i];
        existingPrices[price.priceType][price.id] = price;
    }
    // Create / Modify
    for (var k in request.productPrice){
        price = request.productPrice[k];
        if (!existingPrices[price.priceType]) continue;
        if (existingPrices[price.priceType][price.id] !== undefined){
            // delete the Prices to Modify, only the one's to Remove will be left
            delete existingPrices[price.priceType][price.id];
            
            if (price.priceType != "One Time Allowance" && price.priceType != "One Time Charge")
                request.productPrice[k].operation = "MODIFY";
        } else {
            if (price.priceType != "One Time Allowance" && price.priceType != "One Time Charge")
                request.productPrice[k].operation = "CREATE";
        }
    }
    // Remove. Only the one's to Remove are left in existingPrices
    for (var type in existingPrices){
        for (var j in existingPrices[type]){
            price = existingPrices[type][j];
            // When Removing, the payload structure is simplified
            request.productPrice.push(
                {
                    "id": price.id,
                    "specId": price.specId, 
                    "priceType": type,
                    "operation": "REMOVE"
                });
        }
    }
    return request;
}

try {
    // Initialization
    var producerExistingData = JSON.parse(context.getVariable('jsparamResponseToTransform'));
    var apimRequest = JSON.parse(context.getVariable('request.content'));

    // Transform the payload to include the "operation" property in productPrice objects
    // If a received object already exists in the target system: "operation": "MODIFY"
    // If a received object doesn't exist in the target system: "operation": "CREATE"
    // If an object exists in the target system but isn't received: "operation": "REMOVE"
    var transformedRequest = calculateOperationTypes(producerExistingData, apimRequest);

    // Apply the changes
    context.setVariable("request.content", JSON.stringify(transformedRequest));
    context.setVariable("js.isError", false);

} catch (e) {
    print(e);
    context.setVariable("js.errorMsg", JSON.stringify(e));
    context.setVariable("js.isError", true);
}