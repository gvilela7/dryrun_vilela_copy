# cliOPS

This framework is intended to help out in the automation process for multiple purposes due to its modular approach. This framework is built in _bash_ programming language.

## apigeeOPS

ApigeeOPS a **cliOPS** fork aiming for operation automation from APIGEE Ecosystem

In order to interact with **Google Cloud Plataform**:
   - Set the type in the *contrib/cliOPS/settings.yml* in the property *googleCloud.authentication.settings*
   - **jsonKey** use file **_contrib/GCP_SA_KEY.json** to put your service account key
   - **settings** go to **Google Cloud Plataform** and run command *gcloud auth print-access-token* extract the token and set in the property *googleCloud.authentication.settings.token*

## Docker

We strongly advice to use apigeeOPS with **docker**, however you can run in your local machine, you require to install dependencies which are defined in *contrib/cliOPS/settings.yml*

### Requirements

You must to have installed **DOCKER** in your machine.

1. Install a image docker, running docker.sh(**Linux/Mac**)/*WIP*docker_cliOPS.ps1(**Windows**) located in folder *_contrib/docker/*. These shell should install all dependencies Linux in the operative system you work, through a docker (_dockerfile_ located in folder *_contrib/docker*).

2. Now, we have a docker image in execution. Now you can work with our framework linked to the Apigee. Run framework by using command *cliOPS.sh* 

### Configurations

To run this framework, it's required to set some files:

   - *_contrib/payload.json* is a **JSON** file where you can input values required for the commands. Those inputs you can find them in the controllers files (*controller.sh*) or you can find in test files (*_tests.yml*) located at the base of each **Module**

After the configuration is done, you can run your apigeeOPS.

### How to use *<WIP>*

Run the command `./cliOps help` to know available module commands that can help to do all operations you can perform such as export, import and deploy component core or configurations. The syntax we must known to use our framework is:

`./cliOPS.sh apigee <component> <function>`

For example, the syntax to export a proxy:

`./cliOPS.sh apigee proxy export`

# Development

In order to work with the framework that are some rules to follow, please read the guidelines and follow the examples

## Module Structure

| **moduleName**

|- **controller**.sh (middleware - entry en exit point for all functions available)

|- **entities**.sh (where you can keep state of module variables - access vars using GET/SET functions)

|- **core**.sh (all code logic implementation related to the module)

|- **main**.sh (where internal and external modules and libraries can be imported)

## Example

You can understand about the architecture by following the **examples** located inside **framework** *Module*. There you will find basic code examples to understand the roles of which file

Run the command *`./cliOPS.sh framework examples AUX_ArrayToJson`


## Code Conventions

Some instructions
  - Always use **Try Catch** inside of functions
  - Do NOT use GLOBAL vars, always use **local** - for GLOBAL requires permission and access in entities functions
  - Vars should always be **UPPER_CASE**, replace spaces with underscore
  - Functions
    - **Private** functions 
      - name should use the initial modules letter in **CAPITAL** following **underscore** ex: *apigeeProxySettings* -> *private_APS_*
      - should always receive **OPERATION_ID** as parameters for correlation in logging files
    - Outputs
      - Controllers: Always use **IPayload_OUTPUT** interface
      - Implementations: Always use **IPayload_CREATE** interface
      - Always use **JSON Objects**
    - Inputs: Can use **JSON Array** or **Primitives**
  - Logging
    - We should add logging for each **function**
    - Types Support:
      - OPERATION - `%s/%s_OPERATION_%s_%s.log`
      - SYSTEM - `%s/%s_SYSTEM_%s_%s.log`

## Debug

In order to debug you *should* need to use
  - use a *function* **logError**/**log** `ex: log "Some info" or logError $varWithErrors`
  - access log files in directory **./tmp** 
  - change *settings.yml* for debug different log levels
  - directly in BASH you can see "**set (-/+)x**" for verbosity

## Windows Mysteries

Read mode about `CRLF - LF Break Lines`

To run this framework we can have some trouble with bash not recognized. To fix that, you can use the following command, however that is considered in docker code built:

- `find . -type f -name "*.sh" -print0 | xargs -0 sed -i -e 's/\r$//'`
