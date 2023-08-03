# Makefile for Terraform and Jenkins

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

.PHONY: init plan apply destroy
