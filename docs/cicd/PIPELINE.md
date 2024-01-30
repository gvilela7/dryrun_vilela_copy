# CI/CD Pipeline

 Information about the available **GITHUB Actions** for GIT and APIGEE.

**Table of contents**:

* [Generate Settings Documentation](#generate-settings-documentation)
* [API Products](#api-products)
* [Apps](#apps)
* [Developers](#developers)
* [Authentication Profiles](#authentication-profiles)
* [Flow Hooks](#flow-hooks)
* [Target Servers](#target-servers)
* [Key Value Maps](#key-value-maps)
  * [Import/Export](#Import/Export-KVM)
* [APIGEE](#apigee)
  * [Configurations build all](#configurations-build-all)
* [Proxy](#apigee-proxy)
  * [Re-usable workflows](#re-usable-workflows)
    * [Export](#export)
  * [Proxy CI/CD](#apigee-proxy-cicd)
  * [Proxy QA Linter](#apigee-proxy-linter-pr-dev-main)
* [Integration](#apigee-integration)
  * [Re-usable workflows](#re-usable-workflows-1)
    * [Export](#export-1)
  * [Integration CI/CD](#apigee-integration-cicd)
* [Shared Flow](#apigee-shared-flow)
  * [Re-usable workflows](#re-usable-workflows-2)
    * [Export](#export-2)
  * [Shared Flow CI/CD](#apigee-shared-flow-cicd)
  * [Shared Flow QA Linter](#apigee-sharedflow-linter-pr-dev-main)

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
  * **OPERATION** *`String`*: Define operation you want (IMPORT or EXPORT)
  * **NAME** *`String`*: API product name
  * **ORGANIZATION** *`String`*: API product organization
  * [OPTIONAL] **APIGEE_PATH** *`String`*:  Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

## Apps

Use an existing settings file to create an app with a defined name in Apigee. This workflow will be used to import and export an application. 
Beware, you must first of all create all developers associated for organization/project.

* File: `.github/workflows/configsApp.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **NAME** *`String`*: App name
  * **ORGANIZATION** *`String`*: App organization
  * [OPTIONAL] **APIGEE_PATH** *`String`*:  Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

## Developers

Use an existing settings file to create a developer in Apigee. This workflow will be used to import or update and export a developer.

* File: `.github/workflows/configsDeveloper.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **DEVELOPER_ID** *`String`*: Define email or ID developer
  * **ORGANIZATION** *`String`*: Apigee organization
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

## Authentication Profiles

Use an existing settings file to create an authentication profile with defined name. This workflow will be used to import or update and export an authprofile.

* File: `.github/workflows/configsAuthProfile.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **NAME** *`String`*: Authentication profile name
  * **REGION** *`String`*: Authentication profile region
  * **PROJECT** *`String`*: Authentication profile project
  * **ENVIRONMENT** *`String`*: Authentication profile environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

## Flow Hooks

Use an existing settings file to create flow hooks in a certain environment. This workflow will be used to import or update and export a Flow Hooks.

* File: `.github/workflows/configsFlowHook.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **ORGANIZATION** *`String`*: Flow hook organization
  * **ENVIRONMENT** *`String`*: Flow hook environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*


## Target Servers

Use an existing settings file to create/update a target server with a defined name. This workflow will be used to import or update and export a targetserver.

* File: `.github/workflows/configsTargetServer.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **NAME** *`String`*: Target server name
  * **ORGANIZATION** *`String`*: Target server organization
  * **ENVIRONMENT** *`String`*: Target server environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

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
  * **OPERATION** *`String`*: Define operation you want  (IMPORT or EXPORT)
  * **NAME** *`String`*: The name of the KVM
  * **ORGANIZATION** *`String`*: KVM organization
  * **ENVIRONMENT** *`String`*: KVM environment
  * [OPTIONAL] **APIGEE_PATH** *`String`*: Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

> **Considerations:**
> Apigee X and hybrid do not support unencrytped key value maps.
> The APIM team has a tool for observing the value entries for each KVM that can be provided to the client and used by the Postman application.

## APIGEE

### **Configurations build all**

Creates all the kvm and target servers in the repository for a specified organisation and environments.

* File: `.github/workflows/apigeeCICD.yml`
* Trigger: *workflow_dispatch*
* Variables:
  * **ORGANIZATION** *`String`*: APIGEE Organization
  * **ENVIRONMENT** *`Array<String>`*: Where is deployed `ex: ["env1sit-pub", "env1sit-priv"]`
  * **CONFIG_TYPE** *`Choice`*: The type of configuration you want import/export. Current supported values are:
    * ALL
    * apiproducts
    * apps                    
    * authprofiles  
    * flowhooks 
    * integrations
    * kvms
    * proxies
    * sharedflows          
    * targetservers
    * tlskeystores      
  * [OPTIONAL] **APIGEE_PATH** *`String`*:  Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

## APIGEE PROXY

Requirements:

* **SECRETS**
  * Name: `PROXY_SERVICE_ACCOUNT`
  * Requires:
    * *Google Service Account Private Key*
    * Roles:
      * *Apigee API Admin*
      * *Apigee Environment Admin*
      * *Cloud Run Service Agent*
      * *Apigee Developer Admin*
      * *Apigee integration admin*
      * *Cloud Run Admin*

### RE-USABLE WORKFLOWS

#### **Export**

Retrieve an existing proxy that is deployed. You can push to target branch or create new branch `AUTO/proxy_<NAME>`, if variable AUTO_COMMIT will be *true*.

* File: `.github/workflows/proxyExport.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **PROXY_NAME** *`String`*: The proxy name to create.
  * **ORGANIZATION** *`String`*: The organization from Google Cloud Platform
  * **VERSION** *`Number`*: Number of version you want export to repository. If doesn't defined, the system export latest version
  * **SERVICE_ACCOUNT** *`String`*: Service account accord to do the action
  * **ENVIRONMENT** *`String`*: Where is deployed `ex: env1dev-priv, env1sit-priv, env1prod-priv`
  * [OPTIONAL] **APIGEE_PATH** *`String`*:  Path to APIGEE folder. Defaults to `src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*
  * **AUTO_COMMIT** *`Boolean`*: Check the box if you want to open new branch `ex: AUTO/proxy_<NAME>`

### APIGEE PROXY CICD

Create and deploy a **proxy** in a designed **ENVIRONMENT** and **ORGANIZATION**.

* File: `.github/workflows/proxyCICD.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **NAME** *`String`*: The name of the proxy
  * **ENVIRONMENT** *`String`*: Where it should be deployed to `ex: env1dev-priv, env1sit-priv, env1prod-priv`
  * **ORGANIZATION** *`String`*: The organization from Google Cloud Platform
  * **APIGEE_PATH** *`String`*: Proxies default directory location `ex: src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

Includes the following workflows, which will each define a job:
* [preCheck](../../.github/workflows/proxyCICD.yml)
* [proxySettings](../../.github/workflows/proxyCICD.yml)
* [postCheck](../../.github/workflows/proxyCICD.yml)
  * Variables:
    * [OPTIONAL] **RUNNER** *`String`*: Specifies which image will run the pipeline. (default: `ubuntu-latest`)

### APIGEE Proxy Linter PR dev-main

Validation of development done throught a pull request to branch *dev_main*, always you changes a **proxy** in *`'src/main/apigee/apiproxies/**'`*, running Apigee Linter.

* File: `.github/workflows/proxyQA.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * [OPTIONAL] **RUNNER** *`String`*: Specifies which image will run the pipeline. (default: `ubuntu-latest`)
  * [OUTPUT] **PROXY_LIST** *`Array`*: Specifies all files proxies modifies in feature branch.

## APIGEE INTEGRATION

Requirements:

* **SECRETS**
  * Name: `INTEGRATION_SERVICE_ACCOUNT`
  * Requires:
    * *Google Service Account Private KEY*
    * Roles: *Apigee Integration Admin* role

### RE-USABLE WORKFLOWS

#### **Export**

Retrieve an existing integration that is published. You can push to target branch or create new branch `AUTO/integration_<NAME>`, if variable AUTO_COMMIT will be *true*.

* File: `.github/workflows/integrationExport.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **NAME** *`String`*: Name of the integration on APIGEE
  * **PROJECT** *`String`*: Name of Google Project
  * **REGION** *`String`*: Region where is published `ex: europe-west3`
  * **VERSION** *`String`*: Versions are located at Web UI
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*
  * **AUTO_COMMIT** *`Boolean`*: Open new branch - `ex: AUTO/integration_<NAME>`
  * **APIGEE_PATH** *`String`*: Location of artifacts `default: src/apigee`

### APIGEE Integration CICD

Create and deploy an **Integration** in a designed **PROJECT** and **REGION**.

* File: `.github/workflows/integrationCICD.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **NAME** *`String`*: Name of the integration on APIGEE
  * **PROJECT** *`String`*: Name of Google Project
  * **REGION** *`String`*: Region where is published `ex: europe-west3`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*
  * **APIGEE_PATH** *`String`*: Location of artifacts `default: src/apigee`

Includes the following workflows, which will each define a job:

* [preCheck](../../.github/workflows/integrationCICD.yml)
* [integrationSettings](../../.github/workflows/integrationCICD.yml)
* [postCheck](../../.github/workflows/integrationCICD.yml)
  * Variables:
    * [OPTIONAL] **RUNNER** *`String`*: Specifies which image will run the pipeline. (default: `ubuntu-latest`)

## APIGEE SHARED FLOW

Requirements:

* **SECRETS**
  * Name: `PROXY_SERVICE_ACCOUNT`
  * Requires:
    * *Google Service Account Private Key*
    * Roles:
      * *Apigee API Admin*
      * *Apigee Environment Admin*
      * *Cloud Run Service Agent*
      * *Apigee Developer Admin*
      * *Apigee integration admin*
      * *Cloud Run Admin*

### RE-USABLE WORKFLOWS

#### **Export**

Retrieve an existing shared flow that is published. You can push to target branch or create a new branch `AUTO/sharedflow_<NAME>`, if variable AUTO_COMMIT will be *true*.

* File: `.github/workflows/sharedFlowExport.yml`
* Trigger: *workflow_dispatch*
* Variables:
  * **NAME** *`String`*: The shared flow name.
  * **ORGANIZATION** *`String`*: The organization from Google Cloud Platform
  * **ENVIRONMENT** *`String`*: Where it should be deployed to `ex: env1dev-priv, env1sit-priv, env1prod-priv`
  * **VERSION** *`String`*: Versions are located at Web UI
  * **SERVICE_ACCOUNT** *`String`*: Service account accord to do the action
  * **APIGEE_PATH** *`String`*: Proxies default directory location `ex: src/apigee`
  * **AUTO_COMMIT** *`Boolean`*: Check the box if you want to open new branch `ex: AUTO/sharedflow_<NAME>`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

### APIGEE Shared flow CICD

Create and deploy a **SHARED FLOW** in a designed **ENVIRONMENT**.

* File: `.github/workflows/sharedFlowCICD.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * **NAME** *`String`*: The shared flow name.
  * **ENVIRONMENT** *`String`*:  Where it should be deployed to `ex: env1dev-priv, env1sit-priv, env1prod-priv`
  * **ORGANIZATION** *`String`*: The organization from Google Cloud Platform
  * **APIGEE_PATH** *`String`*: Proxies default directory location `ex: src/apigee`
  * [OPTIONAL] **GITHUB_ENVIRONMENT** *`String`*: Define the GitHub Environment, according by client scenarios. Default *`DEVCI`*

Includes the following workflows, which will each define a job:

* [preCheck](../../.github/workflows/sharedFlowCICD.yml)
* [sharedflowSettings](../../.github/workflows/sharedFlowCICD.yml)
* [postCheck](../../.github/workflows/sharedFlowCICD.yml)
  * Variables:
    * [OPTIONAL] **RUNNER** *`String`*: Specifies which image will run the pipeline. (default: `ubuntu-latest`)

### APIGEE Sharedflow Linter PR dev-main

Validation of development done throught a pull request to branch *dev_main*, always you changes a **sharedflows** in *`'src/main/apigee/sharedflows/**'`*, running Apigee Linter.

* File: `.github/workflows/sharedFlowQA.yml`
* Trigger: *workflow_dispatch*, *workflow_call*
* Variables:
  * [OPTIONAL] **RUNNER** *`String`*: Specifies which image will run the pipeline. (default: `ubuntu-latest`)
  * [OUTPUT] **SHAREDFLOW_LIST** *`Array`*: Specifies all sharedflows files modifies in feature branch.