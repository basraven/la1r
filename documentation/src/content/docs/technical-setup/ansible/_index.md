# Ansible to prepare the playground 
Since there's always a need for installing packages on the nodes directly and I don't want to just use a bunch of shell scripts all configuration and applications outside of k8s is deployed with Ansible which are directed by makefiles. Makefiles because I don't want to remember all commands that I need to spin up ansible by heart,Ansible because I want to semi-formalize the steps I take. 

## Everything on bare-metal
Since I cannot put every step I take in Kubernetes, an example of this is how to setup Kubernetes itself, there is an need for a system such as Ansible.
The goal here is to document every step, it does not matter how small, into an Ansible Playbook script.
These Ansible scripts can be found on https://github.com/basraven/la1r/ansible

## Makefiles as operators
Since I want to formalize everything into scripts, there needs to be a way to formalize how to call the different playbook with the appropriate arguments.
This is why the Git repository contains 2 makefiles. There has been chosen for makefiles because the way these files are called is extremely predictable ```make <your command>```:
* [Makefile for Ansible](/) - This makefile contains all the Ansible Playbook calls which are made to construct la1r on bare metal
* [Makefile for Kubernetes](/) - This makefile contains all the used Kubernetes calls to setup the Kubernetes nodes. This also contains node setup scripts suchs as applying taints. 