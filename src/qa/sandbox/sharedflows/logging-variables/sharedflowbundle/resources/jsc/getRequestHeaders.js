var requestHeaders = context.getVariable("request.headers.names"),
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
    result[name] = context.getVariable("request.header." + name + ".values.string" );
  }
});

// set the jsreqheaders variable:
context.setVariable('jsreqheaders', JSON.stringify(result, null, 2));