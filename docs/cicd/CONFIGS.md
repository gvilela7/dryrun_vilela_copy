# APIGEE Configs
**Table of contents**:

* [Generate Settings Documentation](#generate-settings-documentation)
* [API Products](#api-products)
* [Apps](#apps)
* [Developers](#developers)
* [Authentication Profiles](#authentication-profiles)
* [Flow Hooks](#flow-hooks)
* [Target Servers](#target-servers)
* [Key Value Maps](#key-value-maps)
* [TLS Keystores](#tls-keystores)

## Generate Settings Documentation

Search for the schema file *`docs/configs/<CONFIG_TYPE>/<NAME>.json`* ,  Create schema documentation in folder *`docs/configs/<CONFIG_TYPE>/<NAME>/`* that shows how to fill a settings file. Creates a example settings file in folder *`docs/configs/<CONFIG_TYPE>/settings.yml`* with dummy data.

* File: `.github/workflows/configsCreate.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * [OPTIONAL] **NAME** *`String`*: The schema name. Default value is `schema.json`
  * **CONFIG_TYPE** *`Choice`*: The type of config to generate documentation. Current supported values are:
    * authprofiles
    * apiproducts
    * apps
    * developers
    * integrations
    * kvms
    * proxies
    * sharedflows
    * targetservers
    * tlskeystores
    * flowhooks

>Aditional reading:
>
> * <https://github.com/atomsfat/fake-schema-cli#readme>
> * <https://github.com/coveooss/json-schema-for-humans>
## API Products

Use an existing settings file to create an API product with a defined name in Apigee. This workflow will be used to import and export an API Product

* File: `.github/workflows/configsApiProduct.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **NAME** *`String`*: API product name
  * **ORGANIZATION** *`String`*: API product organization
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## Apps

Use an existing settings file to create an app with a defined name in Apigee. This workflow will be used to import and export an application. Beware, you must first of all create all developers associated for organization/project.

* File: `.github/workflows/configsApp.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: App name
  * **ORGANIZATION** *`String`*: App organization
  * [OPTIONAL]* **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## Developers

Use an existing settings file to create a developer in Apigee. This workflow will be used to import or update and export a developer.

* File: `.github/workflows/configsDeveloper.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **EMAIL** *`String`*: Developer's email
  * **ORGANIZATION** *`String`*: Apigee organization
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## Authentication Profiles

Use an existing settings file to create an authentication profile with defined name. This workflow will be used to import or update and export an authprofile.

* File: `.github/workflows/configsAuthProfile.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: Authentication profile name or unique identifier
  * **REGION** *`String`*: Authentication profile region
  * **PROJECT** *`String`*: Authentication profile project
  * **ENVIRONMENT** *`String`*: Authentication profile environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## Flow Hooks

Use an existing settings file to create flow hooks in a certain environment. This workflow will be used to import or update and export a Flow Hooks.

* File: `.github/workflows/configsFlowHook.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **ORGANIZATION** *`String`*: Flow hook organization
  * **ENVIRONMENT** *`String`*: Flow hook environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## Target Servers

Use an existing settings file to create/update a target server with a defined name. This workflow will be used to import or update and export a targetserver.

* File: `.github/workflows/configsTargetServer.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: Target server name
  * **ORGANIZATION** *`String`*: Target server organization
  * **ENVIRONMENT** *`String`*: Target server environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`Listbox`*: Define the GitHub Environment, according by client scenarios. Default DEVCI


## Key Value Maps

Requirements:

* **SERVICE ACCOUNT**
* **SECRETS**
  * Name: `CONFIGS_ENCRYPTION`
  * Description: Passphrase to encrypt/decrypt data using GPG

### Import/Export KVM

Use an existing settings file to create a KVM with a defined name. This workflow will be used to import or update and export a KVM.

* File: `.github/workflows/configsKVM.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: The name of the KVM
  * **ORGANIZATION** *`String`*: KVM organization
  * **ENVIRONMENT** *`String`*: KVM environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default DEVCI

## TLS Keystores

Documents all the methods defined for the use of TLS Keystores, used to guarantee the security of the various components in APIGEE.

Requirements:

* **SECRETS**
  * Name: `CONFIGS_ENCRYPTION`
  * Description: Passphrase to encrypt/decrypt data using GPG

### Import/Export TLSKeystore

Imports or export a TLS Keystore to an environment of an organization, updating an existing keystore, or creating a new one.

* File: `.github/workflows/configsTlsKeystore.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: TLS Keystore name
  * **ENVIRONMENT** *`String`*: TLS Keystore environment
  * **ORGANIZATION** *`String`*: TLS Keystore organization
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default DEVCI