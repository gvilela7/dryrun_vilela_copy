# Github Cache

Caching in GitHub Actions  helps speed up the workflow building and execution process by saving time and resources. It allows to temporarily store files and directories that are frequently used in your workflows.

**Table of contents**:

* [GitHub Dependencies File](#GitHub-Dependencies-File)
  * [Configurations Steps all](#Steps)
  * [How to apply cache in other workflows](#How-to-apply-cache-in-other-workflows)

# GitHub Dependencies File

 File: `.github/workflows/cliOpsDependencies.yml`
* Trigger: *workflow_dispatch*

## Steps

* **Name** Install NPM Dependencies
  
    The step is setting up the necessary npm dependencies and tools for a Framework project

* **Name** * Cache NPM dependencies

    This step is caching the ~/.npm directory with a key that includes information about the operating system and a hash of the package-lock.json files in your project. Reusing npm dependencies will reduce the the need to download them again.

* **Name** Install other Dependencies

    The step is setting up the necessary dependencies and tools for a Framework project like "jo", "python3" and "libxml2-utils"

* **Name** * Cache other  dependencies

    "Cache other Dependencies" stores the dependencies above in a specified directory for reuse of the packages. 


## How to apply cache in other workflows

    To use caching, you should include the code snippet from the cache steps that pertain to the packages your workflow relies on, whether they are npm or apt packages."



