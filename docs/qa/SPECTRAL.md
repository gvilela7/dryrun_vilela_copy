# JSON/YAML Linter (Spectral YAML)

The power of integrating linting into the design-first workflow, or any workflow which involves API descriptions, is often overlooked. Linting isn't just about validating OpenAPI or JSON Schema documents against specifications. It's for enforcing style guides to ensure that your APIs are consistent, valid, and of high quality.

To achieve this, Spectral has three key concepts:

* **Rules** filter your object down to a set of target values and specify the function (or functions) used to evaluate those values.
* **Functions** accept a value and return issues if the value is incorrect.
* **Rulesets** act as a container for rules and functions.

Spectral comes bundled with a set of core functions and rulesets for working with OpenAPI v2 and v3 and AsyncAPI v2 that you can chose to use or extend, but Spectral is about far more than just checking your OpenAPI/AsyncAPI documents are valid.

## Installation

Use the following command to install.

```bash
npm install -g @stoplight/spectral-cli
```

## Usage

Spectral, being a generic YAML/JSON linter, needs a ruleset to lint files. A ruleset is a JSON, YAML, or JavaScript/TypeScript file (often the file is called .spectral.yaml for a YAML ruleset) that contains a collection of rules, which can be used to lint other JSON or YAML files such as an API description.

To get started, run this command in your terminal to create a .spectral.yaml file that uses the Spectral predefined rulesets based on OpenAPI or AsyncAPI:


If you would like to create your own rules, check out the Custom Rulesets page.

```yaml
echo 'extends: ["spectral:oas", "spectral:asyncapi"]' > .spectral.yaml
```

The fastest way to create a ruleset is to use the extends property to leverage an existing ruleset.
Spectral comes with two built-in rulesets: 
* spectral:oas - OpenAPI v2/v3 rules
* spectral:asyncapi - AsyncAPI v2 rules

If you would like to create your own rules or find more informations about default/custom rules check out the [Custom Rulesets](https://meta.stoplight.io/docs/spectral/01baf06bdd05a-create-a-ruleset) page.

## Lint
Use this command if you have a ruleset file in the same directory as the documents you are linting:

```yaml
spectral lint myapifile.yaml
```
Where myapifile.yaml is the swagger I built.

Use this command to lint with a custom ruleset, or one that's located in a different directory than the documents being linted:

```yaml
spectral lint myapifile.yaml --ruleset spectral.yaml
```