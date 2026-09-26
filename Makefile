SHELL := /usr/bin/env bash
.SHELLFLAGS := -euo pipefail -c
.PHONY: help fmt fmt-check validate test lint security policy-test guard-test schema docs quality ci

# Every Terraform root/module directory: anything with a versions.tf.
TF_DIRS   := $(shell find modules bootstrap blueprints -name versions.tf -exec dirname {} \; | sort)
# Directories with native Terraform tests.
TEST_DIRS := $(shell find modules bootstrap blueprints -type d -name tests -exec dirname {} \; | sort)

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

fmt: ## Format all Terraform files
	terraform fmt -recursive .

fmt-check: ## Fail if any Terraform file is not formatted
	terraform fmt -check -diff -recursive .

validate: ## terraform init (no backend) + validate every module, bootstrap and blueprint
	@for dir in $(TF_DIRS); do \
		echo "==> validate $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

test: ## Run native Terraform tests (mock providers, no cloud credentials)
	@for dir in $(TEST_DIRS); do \
		echo "==> test $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done

lint: ## TFLint every Terraform directory
	tflint --init
	@for dir in $(TF_DIRS); do \
		echo "==> tflint $$dir"; \
		tflint --chdir=$$dir --config=$(CURDIR)/.tflint.hcl; \
	done

security: ## Trivy IaC misconfiguration scan (HIGH/CRITICAL)
	trivy config --severity HIGH,CRITICAL --exit-code 1 .

policy-test: ## Unit-test the plan policies and run them against fixtures
	conftest verify --policy policies/terraform
	./scripts/policy-check.sh policies/fixtures/plan-compliant.json
	@if ./scripts/policy-check.sh policies/fixtures/plan-violations.json >/dev/null 2>&1; then \
		echo "policy fixture with violations unexpectedly passed"; exit 1; \
	else echo "==> violations fixture correctly rejected"; fi

guard-test: ## Unit-test the agent command guard
	python3 -m unittest discover -s tests -v

schema: ## Validate example infrastructure requests and render them to tfvars
	@for f in examples/requests/*.yaml; do \
		python3 scripts/request-to-tfvars.py --check "$$f"; \
	done
	@for f in examples/requests/invalid/*.yaml; do \
		if python3 scripts/request-to-tfvars.py --check "$$f" 2>/dev/null; then \
			echo "$$f should have been rejected"; exit 1; \
		else echo "$$f: correctly rejected"; fi; \
	done

docs: ## Regenerate module input/output tables with terraform-docs
	@for dir in $(TF_DIRS); do terraform-docs markdown table --output-file README.md --output-mode inject $$dir >/dev/null; done

quality: fmt-check validate test ## Terraform core quality gates
	@echo "Terraform core quality gates passed."

ci: quality lint policy-test guard-test schema ## Everything CI runs except the Trivy/Gitleaks scans
	@echo "All local CI gates passed."
