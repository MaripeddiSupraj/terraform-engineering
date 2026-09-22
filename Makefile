.PHONY: fmt fmt-check validate test quality

TF_DIRS := \
	modules/azure/resource-group \
	modules/azure/network \
	modules/azure/log-analytics \
	modules/azure/key-vault \
	modules/azure/aks \
	bootstrap/azure \
	blueprints/kubernetes-platform/azure

fmt:
	terraform fmt -recursive .

fmt-check:
	terraform fmt -check -recursive .

validate:
	@for dir in $(TF_DIRS); do \
		echo "==> validate $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir validate; \
	done

test:
	@for dir in modules/azure/resource-group modules/azure/network modules/azure/log-analytics modules/azure/key-vault modules/azure/aks; do \
		echo "==> test $$dir"; \
		terraform -chdir=$$dir init -backend=false -input=false >/dev/null; \
		terraform -chdir=$$dir test; \
	done

quality: fmt-check validate test
	@echo "Terraform core quality gates passed."
