/* March, 2023 */

//__________Utility Functions__________

function isObjectEmpty(objectName) {
    return Object.keys(objectName).length === 0;
}

// [{key: , value: }, ...] -> {key: value, ...}
function unwrapKeyValueArray(arr) {
    var obj = {};
    arr.forEach(function(element) {
        obj[element.key] = element.value;
    });
    return obj;
}

//__________Data mapping__________

// maps all fields of "input" to "out", except the productPrice array
function mapGeneral(input, out, isAddon) {
    out.id = input.id;
    out.status = input.entries.status;
    out.name = input.entries.name;
    if (input.entries.startDateTime !== undefined || input.entries.endDateTime !== undefined) {
        if (!out.validFor) out.validFor = {};
        out.validFor.startDateTime = input.entries.startDateTime;
        out.validFor.endDateTime = input.entries.endDateTime;
    } 
    if (input.product_offering_spec_id !== undefined || input.entries.productOfferingName !== undefined) {
        if (!out.productOffering) out.productOffering = {};
        out.productOffering.id = input.product_offering_spec_id;
        out.productOffering.name = input.entries.productOfferingName;
    }
    if (isAddon && input.parent_agreement_id !== undefined) {
        if (!out.productOffering) out.productOffering = {};
        if (!out.productRef) out.productRef = [];
        if (!out.productRef[0]) out.productRef[0] = {};
        out.productRef[0].id = input.parent_agreement_id;
    }
    if (isAddon && (input.parent_offer_id !== undefined || input.entries.parentOfferingName !== undefined)) {
        if (!out.productRef) out.productRef = [];
        if (!out.productRef[0]) out.productRef[0] = {};
        if (!out.productRef[0].productRefOffering) out.productRef[0].productRefOffering = {};
        out.productRef[0].productRefOffering.id = input.parent_offer_id;
        out.productRef[0].productRefOffering.name = input.entries.parentOfferingName;
    }
}

// Property names correspond to the array name in the Producer payloads.
// Values correspond to the value of the priceType property,
//      which will be added the corresponding array elements in the APIM payloads.
var PRICE_TYPE_MAP = {
    "usage_charges": "Usage Charge",
    "topups": "Topup",
    "allowances": "Allowance",
    "spending_limits": "Spending Limit",
    "alarms_ng": "Alarm",
    "recurring_charges": "Recurring Charge",
    "balances": "Balance Inquiry",
    "otas": "One Time Allowance",
    "otcs": "One Time Charge"
};

function mapPriceArray(typeName, priceArray, apimResponse) {    
    // map each object of the array
    for (var i in priceArray)
    {
        if (isObjectEmpty(priceArray[i])) continue; // Skipping empty objects

        // Unwrapping entries (objects of {key: , value: } properties)
        priceArray[i].entries = unwrapKeyValueArray(priceArray[i].entries);

        var oldPrice = priceArray[i];
        var newPrice = {
            // mandatory properties
            'priceType': PRICE_TYPE_MAP[typeName],
            'id': oldPrice.id,
            'specId': oldPrice.spec_id,
            'status': oldPrice.admin_status,
            
            // conditional existance, treated as non-mandatory property
            'scopeId': oldPrice.scope_id
        };


        // non-mandatory properties
        if (oldPrice.start_date !== undefined || oldPrice.end_date !== undefined)
        {
            newPrice.validFor = {
                'startDateTime': oldPrice.start_date,
                'endDateTime': oldPrice.end_date
            };
        }
        if (oldPrice.entries !== undefined)
        {
            newPrice.productCharacteristic = [];
            for (var entry in oldPrice.entries)
                newPrice.productCharacteristic.push({
                        'name': entry,
                        'value': oldPrice.entries[entry]
                    });
        }
        
        // ensure productPrice array exists (will only exist if it contains elements)
        if (!apimResponse.productPrice) apimResponse.productPrice = [];
        // Append the mapped price object
        apimResponse.productPrice.push(newPrice);
    }

}


//__________Main__________

function mapping(payload, accountId, isAddon){
    var apimResponse = {};
    
    // Unwrapping entries (objects of {key: , value: } properties)
    payload.entries = unwrapKeyValueArray(payload.entries);

    // Mapping payload to the new object
    if(!isAddon) apimResponse.billingAccount = { "id": accountId };
    mapGeneral(payload, apimResponse, isAddon);

    // Merge all types of price arrays into productPrice, essentially reverting the grouping by priceType.
    // Type will be defined in the 'priceType' property.
    for (var prop in PRICE_TYPE_MAP)
        if (typeof payload[prop] == "object" && payload[prop] !== null && payload[prop]!=[])
            mapPriceArray(prop, payload[prop], apimResponse);
    return apimResponse;
}

try {
    // Initialization
    var producerResponse = JSON.parse(context.getVariable('jsparamResponseToTransform'));
    var accountId = context.getVariable('req.header.account_id'); // the only header to map
    var flow = context.getVariable('current.flow.name');

    var apimResponse = mapping(producerResponse, accountId, flow == "QueryAddonProduct");

    // Apply the changes
    context.setVariable("jsparamResponseToTransform", JSON.stringify(apimResponse));
    context.setVariable("js.isError", false);

} catch (e) {
    print(e);
    context.setVariable("js.errorMsg", JSON.stringify(e));
    context.setVariable("js.isError", true);
}