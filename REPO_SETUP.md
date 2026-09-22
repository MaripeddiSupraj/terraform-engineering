# Create the GitHub repository

Recommended repository name:

`terraform-engineering`

Recommended description:

> Production-grade, agent-neutral Terraform engineering framework for Azure, AWS, GCP, and OCI — modular IaC, tests, security gates, controlled plans, and evidence.

When creating it in GitHub:

- Visibility: **Public**
- Do **not** add a README, `.gitignore`, or license in the GitHub wizard; this package already contains them.

Then from this folder:

```bash
git init
git add .
git commit -m "feat: bootstrap agent-neutral Terraform engineering framework"
git branch -M main
git remote add origin git@github.com:<your-user>/terraform-engineering.git
git push -u origin main
```

After the first push, enable:

- branch protection / ruleset for `main`;
- required pull requests;
- required `Terraform Quality` and `IaC Security` checks;
- secret scanning and push protection if available;
- Dependabot alerts;
- private vulnerability reporting.
