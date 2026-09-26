"""Unit tests for scripts/guard-terraform.py. Run: python3 -m unittest discover -s tests"""
import json
import subprocess
import sys
import unittest
from pathlib import Path

GUARD = Path(__file__).resolve().parent.parent / "scripts" / "guard-terraform.py"


def run(command, as_hook=True):
    if as_hook:
        payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": command}})
        return subprocess.run([sys.executable, str(GUARD)], input=payload, capture_output=True, text=True).returncode
    return subprocess.run([sys.executable, str(GUARD), "--", *command.split()], capture_output=True, text=True).returncode


BLOCKED = [
    "terraform apply -auto-approve",
    "terraform apply -auto-approve=true tfplan",
    "terraform -chdir=blueprints/x apply",
    "terraform apply -destroy tfplan",
    "terraform destroy",
    "tofu destroy -target=module.x",
    "cd blueprints/x && terraform apply -auto-approve",
    "make fmt; terraform destroy",
    "bash -c 'terraform apply -auto-approve'",
    "echo $(terraform destroy)",
    "terraform state rm module.aks",
    "terraform state mv a b",
    "terraform force-unlock 1234",
    "terraform import azurerm_resource_group.x /subscriptions/x",
    "terraform taint module.aks.azurerm_kubernetes_cluster.this",
    "terraform workspace delete prod",
    "terraform plan -lock=false",
    "terragrunt run-all destroy",
    "az group delete --name rg-prod --yes",
    "az keyvault purge --name kv",
    "aws s3 rb s3://bucket --force",
    "aws ec2 terminate-instances --instance-ids i-1",
    "gcloud container clusters delete prod",
    "oci os bucket delete --name b",
]

ALLOWED = [
    "terraform fmt -check -recursive .",
    "terraform -chdir=blueprints/x init -backend=false",
    "terraform validate",
    "terraform test",
    "terraform plan -out=tfplan",
    "terraform plan -destroy -out=destroy.tfplan",
    "terraform plan -replace=module.aks.azurerm_kubernetes_cluster.this -out=tfplan",
    "terraform apply tfplan",
    "terraform -chdir=blueprints/x apply .evidence/20260926T000000Z/tfplan",
    "terraform show -json tfplan",
    "terraform state list",
    "terraform state show module.aks.azurerm_kubernetes_cluster.this",
    "az account show",
    "az aks get-versions --location centralindia",
    "aws sts get-caller-identity",
    "gcloud config list",
    "git commit -m 'remove terraform destroy usage from docs'",
    "grep -r auto-approve docs/",
]


class GuardTest(unittest.TestCase):
    def test_blocked(self):
        for command in BLOCKED:
            with self.subTest(command=command):
                self.assertEqual(run(command), 2, command)

    def test_allowed(self):
        for command in ALLOWED:
            with self.subTest(command=command):
                self.assertEqual(run(command), 0, command)

    def test_cli_mode(self):
        self.assertEqual(run("terraform apply -auto-approve", as_hook=False), 2)
        self.assertEqual(run("terraform apply tfplan", as_hook=False), 0)

    def test_cursor_payload(self):
        payload = json.dumps({"command": "terraform destroy", "cwd": "/tmp"})
        result = subprocess.run([sys.executable, str(GUARD)], input=payload, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertEqual(json.loads(result.stdout)["permission"], "deny")


if __name__ == "__main__":
    unittest.main()
