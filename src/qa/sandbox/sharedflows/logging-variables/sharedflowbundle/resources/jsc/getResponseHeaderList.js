var requestHeaders = context.getVariable("message.headers.names"),
    result = {};

// requestHeaders is a java.util.TreeMap$KeySet; convert it to string
requestHeaders = requestHeaders + '';

// convert from "[A, B, C]" to an array of strings: ["A", "B", "C"]
requestHeaders = requestHeaders.slice(1, -1).split(', ');

// insert each header into the response
requestHeaders.forEach(function(name){
  var value = context.getVariable("message.header." + name );
  result[name] = value;
});

// set the jsreqheaders variable:
context.setVariable('jsresheaders', JSON.stringify(result, null, 2));
