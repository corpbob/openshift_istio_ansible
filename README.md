# How to setup Istio 1.0.2 on your OKD 3.10 cluster

## Pre-requisites
- An OKD 3.10 cluster
- Create a user called istio that is able to sudo without a password.

## Set up
1. Install apache-maven-3.5.4 and place it at /home/istio/apache-maven-3.5.4/
1. Run the ansible script

```
ansible-playbook -i hosts istio.yaml
```
