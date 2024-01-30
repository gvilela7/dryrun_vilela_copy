## QA Apigee Components

####    - *What type of API test must we do?*
We can do some type of API test. API Apigee has communication with all customers which must need to test those communication.
Due to that, we must build only one type of test: funcional test and integration test.

>  - **Funcional tests** -> verifies that individual units of code (mostly functions) work as expected. Usually, you write the test cases yourself, but some can be automatically generated. You will need mock different services.
> - **Integration tests** -> check whether different chunks of code are interacting successfully in a local environment. A “chunk of code” can manifest in many ways, but generally integration tests involve verifying service/API interactions. 
####    - *How can we build an API test?*
**1º** - You must install **dotenv** to build your test. It lets you sync and deploy your .env files across machines, teams, and environments – simply and securely. **All your tests are built with Cucumber.** 
>
>_Cucumber_ is a software tool that supports behavior-driven development (BDD). It's ordinary language parser called Gherkin. It allows expected software behaviors to be specified in a logical language that customers can understand.
You need to install on the source of the repository, inside in _src/<component_name>/<api_name>/_  with a following structure:

        tests/
            features/
               step_definitions/
                  apickli-gherkin.js
               support/
                  init.js
               myapi.feature (here you write the cucumber tests)
            package.json

_Features directory_ contains cucumber feature files written in gherkin syntax. _step_definitions_ contains the JavaScript implementation of gherkin test cases. 

Now we can get the project dependencies installed, always we change branch, repository or location project. You should be sure that dependencies are installed on global folder, on _nodule_modules_ folder:

      npm install

If you have a MAC or Linux computer, you need to install a nuget called _**dotenv-cli**_ used to throught Linux or MAC commandline. 

      # its dependencie to use on VSCode 
      npm install dotenv --save

      #do it if your computer is MAC or Linux
      npm install -g dotenv-cli  

As you see above, the dependency dotenv is used to build your automatic test, with this following code in file _init.js_, folder _./support/_  

      # you add this on init.js
      require('dotenv').config();

**2º** - In the folder _src/<component_name>/<component>/_tests_/_ we create a file environment with a following name _.env.<environment>_ with following text:

    - HOST=<name_of_endpoint_ip>

**3º** - Create a folder in _src/<component_name>/<api_name>/_tests_/_ with a name _features_. We create all your test with Cucumber. 

The test files must be create with the following name: _**method_valueTest_API.feature**_
>  - _method:_ **the method or verb we use for the test**. It'll can be GET, POST, DELETE, etc.
>  - _valueTest:_ **If the test must be positive**, you must define it with _**"P"**_, otherwise, define it with _**"N"**_
>  - _API:_ **The name of API we built**
An example of the name we must use:

      POST_P_ApiClientAlt.feature

**4º** - After your tests built, you can run with a following code which .env file is environment host:

      dotenv -e .env.development npx cucumber-js features --publish-quiet

**Note:** Those commands run all js files inside the features folder and return your results.