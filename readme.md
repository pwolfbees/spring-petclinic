# CloudBees Core() Integration with Binary Authorization 

This demonstration application [CloudBees Core](https://www.cloudbees.com/get-started) with Google Cloud's [Binary Authorization](https://cloud.google.com/binary-authorization). 

## Prerequisites

1. Cloud Environment
  * Google Cloud Platform (GCP) Project
  * CloudBees Core or Jenkins 
    * Plugins required
      * [Pipeline Plugin](https://plugins.jenkins.io/workflow-aggregator)
      * [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes)
      * [Workspace Cleanup Plugin](https://plugins.jenkins.io/ws-cleanup)

1. Tools 
  * Linux or OSX
  * gcloud
  * gpg

## Running the Demo

### Simple Installation
This setup assumes that you have a GCP project available for testing that can be cleaned up easily and not affect other workloads.

#### Steps:
1. Fork and clone this repository
1. Edit ./setup/configuration 
* **configuration** - 
1. Run ./setup/setup.sh
1. Commit and Push changes back to your repository
1. Create a [Multibranch Pipeline](https://jenkins.io/doc/book/pipeline/multibranch/) in Jenkins for your repository and enable [Tag Discovery](https://jenkins.io/blog/2018/05/16/pipelines-with-git-tags/) 

### Setup scripts
The setup.sh script runs multiple scripts to set up a particular part of the demonstration. Each of these scripts can also be run independently if you want to have more control of the installation or skip different steps.


* **container-analysis-setup** - In order for Binary Authorization to work  



