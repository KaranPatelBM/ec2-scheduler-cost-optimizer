# ===== Dynamic Variables =====
MY_IP              ?= $(shell echo $$MY_IP)
BUDGET_ALERT_EMAIL ?= $(shell echo $$BUDGET_ALERT_EMAIL)
AWS_REGION         ?= $(shell echo $$AWS_REGION || echo "ap-south-1")
TF_STATE_BUCKET    ?= $(shell echo $$TF_STATE_BUCKET)
INFRACOST_API_KEY  ?= $(shell echo $$INFRACOST_API_KEY)

# ===== File Variables =====
PLAN_FILE     ?= tfplan.binary
PLAN_JSON     ?= plan.json
COST_FILE     ?= cost-estimate.txt

# ===== Validation =====
check-vars:
	@if [ -z "$(MY_IP)" ]; then echo "Error: MY_IP not set"; exit 1; fi
	@if [ -z "$(BUDGET_ALERT_EMAIL)" ]; then echo "Error: BUDGET_ALERT_EMAIL not set"; exit 1; fi
	@echo "Required variables validated"

# ===== Terraform Targets =====
init:
	@echo "Initializing Terraform..."
	@if [ -n "$(TF_STATE_BUCKET)" ]; then \
		terraform init \
			-backend-config="bucket=$(TF_STATE_BUCKET)" \
			-backend-config="key=ec2-scheduler/terraform.tfstate" \
			-backend-config="region=$(AWS_REGION)"; \
	else \
		terraform init; \
	fi

fmt:
	@echo "Formatting Terraform code..."
	terraform fmt -check -recursive

validate:
	@echo "Validating Terraform configuration..."
	terraform validate

plan: check-vars fmt validate init
	@echo "Creating Terraform plan..."
	
	terraform plan -out $(PLAN_FILE) \
		-var="my_ip=$(MY_IP)" \
		-var="budget_alert_email=$(BUDGET_ALERT_EMAIL)"

	@echo "Converting plan to JSON..."

	terraform show -json $(PLAN_FILE) > $(PLAN_JSON)
	@if [ -n "$$INFRACOST_API_KEY" ]; then \
		echo "Generating cost estimate..."; \
		infracost breakdown --path $(PLAN_JSON) --format table --out-file $(COST_FILE); \
		echo "Cost estimate saved to $(COST_FILE)"; \
	else \
		echo "INFRACOST_API_KEY not set, skipping cost estimation"; \
		infracost breakdown --path $(PLAN_JSON); \
	fi

apply:
	@echo "Applying Terraform plan..."
	terraform apply $(PLAN_FILE)

destroy: check-vars
	@echo "Destroying infrastructure..."
	@read -p "Are you sure you want to destroy all resources? (yes/no): " confirm && [ "$$confirm" = "yes" ]
	terraform destroy \
		-var="my_ip=$(MY_IP)" \
		-var="budget_alert_email=$(BUDGET_ALERT_EMAIL)" \
		-auto-approve

output:
	@echo "Terraform outputs:"
	terraform output

clean:
	@echo "Cleaning up generated files..."
	rm -f $(PLAN_FILE) $(PLAN_JSON) $(COST_FILE)

help:
	@echo "EC2 Scheduler Cost Optimizer - Available Commands:"
	@echo ""
	@echo "  plan       - Format, validate, init, plan + cost estimation"
	@echo "  apply      - Apply the terraform plan"
	@echo "  destroy    - Destroy all resources (with confirmation)"
	@echo "  output     - Show terraform outputs"
	@echo "  clean      - Remove generated files"
	@echo "  check-vars - Validate required environment variables"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "  Required Environment Variables:"
	@echo "  MY_IP              - Your IP address with CIDR (e.g., 1.2.3.4/32)"
	@echo "  BUDGET_ALERT_EMAIL - Email for budget alerts"
	@echo ""
	@echo "  Optional Environment Variables:"
	@echo "  AWS_REGION         - AWS region (default: ap-south-1)"
	@echo "  TF_STATE_BUCKET    - S3 bucket for remote state"
	@echo "  INFRACOST_API_KEY  - API key for cost estimation"

.PHONY: plan apply destroy output clean help check-vars init fmt validate