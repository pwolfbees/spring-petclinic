# CloudBees Core Integration with Binary Authorization 

## CloudBees Core
<a href="https://www.cloudbees.com/get-started">Get Started</a>

## Binary Authorization

<a href="https://cloud.google.com/binary-authorization/">

## Prerequisites

1. Cloud Environment
  * Google Cloud Platform (GCP) Project
  * CloudBees Core or Jenkins 
    * Plugins required
      * [Pipeline Plugin](https://plugins.jenkins.io/workflow-aggregator)
      * [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes)
      * [Workspace Cleanup Plugin](https://plugins.jenkins.io/ws-cleanup)

2. Tools 
  * Linux or OSX
  * gcloud
  * gpg

## Installation

### Simple Installation
This setup assumes that you have a GCP project available for testing that can be cleaned up easily and not affect other workloads.

#### Steps:
1. Edit ./setup/configuration 

2. Run ./setup/setup.sh

## Running the Demo

