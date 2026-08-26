# Terraform AWS Refresher Project

A from-scratch AWS infrastructure project built with Terraform to develop genuine, current hands-on fluency — remote state, modules, multi-environment config, and a real CI pipeline, all built and debugged against real AWS resources rather than copied from a tutorial.

**Scope note:** this is a personal, self-directed project. It demonstrates real competence in the practices below — it does not represent years of production experience, multi-account/multi-region setups, or team-scale usage. Framed honestly, not oversold.

## What's built

- A VPC with a public subnet, internet gateway, route table, and a security group scoped to HTTP (open) and SSH (restricted to a single IP)
- A single EC2 instance (`t3.micro`/`t3.small` depending on environment), AMI resolved dynamically rather than hardcoded
- An SSH key pair, dedicated to this project
- Remote state in S3 with locking via DynamoDB
- Two reusable modules (`network`, `compute`) instead of one flat config
- A dev/prod environment split via separate `.tfvars` files
- A GitHub Actions CI pipeline that validates every change before merge

## Project structure

.
├── backend.tf              # S3 remote state + DynamoDB locking config
├── provider.tf              # AWS provider + version constraint
├── variables.tf              # Root-level input variables
├── main.tf                  # Wires the network and compute modules together
├── outputs.tf                # Exposes instance ID and public IP
├── terraform.tfvars          # Local-only values (gitignored — contains a real IP)
├── environments/
│   ├── dev.tfvars            # t3.micro, environment = "dev"
│   └── prod.tfvars           # t3.small, environment = "prod"
├── modules/
│   ├── network/               # VPC, subnet, IGW, route table, security group
│   └── compute/                # AMI lookup, key pair, EC2 instance
├── ci/
│   └── placeholder-key.pub     # Fake public key, used only by CI (see below)
└── .github/workflows/
    └── terraform.yml           # fmt / validate / plan on every PR and push to main

## Remote state & locking

State lives in an S3 bucket (versioned) rather than locally, with a DynamoDB table providing locking so concurrent runs (e.g. a local run and a CI run) can't corrupt state by writing at the same time. Both are provisioned once, outside of Terraform itself (a standard, accepted pattern — you can't remote-backend the thing that creates the remote backend), and deliberately persist between sessions rather than being torn down with everything else.

## Environments

Dev and prod are separated via distinct `.tfvars` files (`-var-file=environments/dev.tfvars` / `prod.tfvars`) rather than Terraform workspaces. Workspaces share the same backend/state structure with only an internal state-path difference, which makes it easy to forget which environment is currently selected and apply the wrong one by accident. Separate files make the environment explicit in the command itself — harder to get wrong, and the more common pattern on real teams.

## CI/CD pipeline

Every pull request and every push to `main` runs `terraform fmt -check`, `terraform validate`, and `terraform plan` via GitHub Actions. **There is no `apply` step anywhere in the pipeline, on any trigger — that's a deliberate scope decision, not a gap.** Applying stays a manual, local, human-reviewed action every time. A CI-triggered `apply` is a reasonable choice for a team with proper environment protections and approval gates in place; for a personal project without that infrastructure, keeping a human in the loop for every real change is the safer default.

Two CI-specific gaps had to be worked around, both handled the same way — a placeholder value supplied only in CI, since CI never applies and so never needs real values:
- `allowed_ssh_cidr` has no default (intentionally — see below), so CI supplies a documentation-range placeholder IP (`203.0.113.0/32`, RFC 5737) via `TF_VAR_allowed_ssh_cidr`.
- The SSH key pair's public key normally comes from a local file (`~/.ssh/...`) that only exists on the machine that generated it. CI instead reads a committed, clearly-fake placeholder key (`ci/placeholder-key.pub`) via `TF_VAR_public_key_path`.

## Security notes

- The Terraform IAM user runs under a custom least-privilege policy, not admin/root — built iteratively against real `AccessDenied` errors during development rather than written perfectly upfront (worth being honest about: `ec2:ModifySubnetAttribute` and `ec2:ImportKeyPair`/`ec2:DeleteKeyPair` were both missing initially and added after hitting real failures, not anticipated in advance).
- `allowed_ssh_cidr` has **no default value**, by design — this forces every plan/apply to explicitly supply a real IP, so a forgotten default can never leave SSH open to `0.0.0.0/0` by accident.
- No secrets are ever committed. AWS credentials for CI are stored as encrypted GitHub Actions secrets; the real SSH public key and home IP live only in a gitignored local `terraform.tfvars`.

## Real friction hit along the way

This project wasn't a clean, scripted run — genuine problems came up and were diagnosed and fixed, which is arguably more representative of real infrastructure work than a flawless run would be:

- **IAM policy gaps**, caught via real `AccessDenied` errors rather than anticipated in advance (see Security notes above).
- **A tainted subnet** after a partial apply failure (the `ModifySubnetAttribute` permission error left the subnet resource in an uncertain state) — Terraform correctly destroyed and recreated it cleanly on the next apply rather than leaving stale state behind.
- **AWS provider version drift** — an initial `~> 5.0` constraint conflicted with a provider version (`6.61.0`) that had already been locked in before the constraint existed; resolved by updating the constraint to match reality rather than forcing a downgrade.
- **An orphaned DynamoDB state lock**, left behind by a CI run that died mid-run during a genuine GitHub Actions infrastructure outage (confirmed independently via githubstatus.com, not assumed) — cleared safely with `terraform force-unlock` once confirmed no real operation was still in progress.
- **A missing local file in CI** — `file()` calls that read local paths (the SSH key) work locally but fail on GitHub's ephemeral runners, which have no access to files outside the checked-out repo. Fixed by making the path configurable and pointing CI at a committed placeholder.

## Getting started

```bash
# Configure a dedicated AWS CLI profile scoped to a least-privilege IAM user
aws configure --profile terraform-project

# Initialize (pulls remote state from S3)
terraform init

# Plan against an environment
terraform plan -var-file=environments/dev.tfvars

# Apply (manual, reviewed — never automated)
terraform apply -var-file=environments/dev.tfvars

# Tear down when done — mandatory, not optional, since this provisions real billable AWS resources
terraform destroy -var-file=environments/dev.tfvars

Cost discipline

This project provisions real AWS resources that cost money while running (a t3.micro/t3.small instance, at fractions of a cent per minute). terraform destroy is treated as a mandatory step at the end of every working session, not optional cleanup — nothing is left running between sessions. The S3 state bucket and DynamoDB lock table are the one deliberate exception: they're meant to persist, and their idle cost is negligible (a few KB of storage, pay-per-request billing with zero requests when idle).
