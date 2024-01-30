var errorMessage = JSON.parse(context.getVariable("errorMessage"));

var replacer = (key, value) => (value === null || value === "") ? undefined : value;
var cleanCopy = JSON.parse(JSON.stringify(errorMessage), replacer);


context.setVariable("errorMessage", JSON.stringify(cleanCopy));