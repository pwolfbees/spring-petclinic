# CloudBees Core Integration with Binary Authorization on Google Cloud Platform

This application demonstrates how to use Google Cloud's [Binary Authorization](https://cloud.google.com/binary-authorization) to validate and approve container images before deploying them to Google Kubernetes Engine (GKE) with [CloudBees Core](https://www.cloudbees.com/get-started). 

The demonstration used the [Spring Petclinic](https://github.com/spring-projects/spring-petclinic) application as a sample application but the same methodology would apply to any application that is being deploying on Kubernetes.

## Goals
Choices were made in the Jenknisfile Pipeline for this application to highlight several features but are not the only way to accomplish this integration. 

* Provide an extensible integration that can be used for different combinations of CloudBees Core and GCP. E.g. Multiple Projects, Multiple Namespaces.
* Provide compartmentalized steps that can be used independently in different Jenkins Pipelines. E.g. Kaniko build, Attestation Signing.
* Demonstrate conditional flow control of Jenknis Declarative Pipeline using _environment_ and _when_ based on presence of git tags. 

## Prerequisites
These items must be available to run this demonstration. 

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



