# Apigee Linter Validation

Static code analysis for Apigee proxy and sharedflow bundles to encourage API developers to use best practices and avoid anti-patterns.

This utility is intended to capture the best practices knowledge from across Apigee including our Global Support Center team, Customer Success, Engineering, and our product team in a tool that will help developers create more scalable, performant, and stable API bundles using the Apigee DSL.

At this point, we are focused on plugin execution and modelling the various lintable assets including Bundles, Proxies, SharedFlows, Targets, Flows, Steps, and Policies.

## Installation

If the _npm_ version isn't the latest, then proceed to update the version with the following command:

```bash
npm install npm@latest -g
```

After install the latest version _npm_, you must use the following command to install. 

```bash
npm install -g apigeelint
```

## Usage

You can use the following flags to built your apigeelint validation, where you can define your validation path (-s), the format (-f) and if you wish information in json format (json.js), table format (table.js) or HTML format (html.js). 

We can define ruleset to ignore in your pipeline.

Bewatch those information bellow.

```bash
apigeelint -h
Usage: apigeelint [options]

Options:
  -V, --version                           output the version number
  -s, --path <path>                       Path of the proxies
  -f, --formatter [value]                 Specify formatters (default: json.js)
  -w, --write [value]                     file path to write results
  -e, --excluded [value]                  The comma separated list of tests to exclude (default: none)
  -x, --externalPluginsDirectory [value]  Relative or full path to an external plugins directory
  --list                                  do not execute, instead list the available plugins and formatters
  --maxWarnings [value]                   Number of warnings to trigger nonzero exit code (default: -1)
  --profile [value]                       Either apigee or apigeex (default: apigee)
  -h, --help                              output usage information
```
Example:

```yaml
apigeelint -s sampleProxy/ -f table.js
```
Where -s points to the apiProxy source directory and -f is the output formatter desired.

## Tests
The test directory includes scripts to exercise a subset of rules. Overall linting can be tested with:

```yaml
apigeelint -s ./test/fixtures/resources/sampleProxy/24Solver/apiproxy/
```
This sample exhibits many bad practices and as such generates some noisy output.

## Rules
The list of rules is a work in progress. We expect it to increase over time. As product features change (new policies, deprecated policies, etc), we will change rules as well.

This is the current list, can be found [here](https://github.com/apigee/apigeelint#rules)