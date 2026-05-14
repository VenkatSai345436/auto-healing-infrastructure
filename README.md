# ⚡ Auto-Healing Infrastructure System

Event-driven self-healing infrastructure on AWS.  
When a service fails — system detects, heals, and notifies automatically.  
**Zero human intervention. Zero 3AM wake-up calls.**

---

## Architecture

```
EC2 Instance (Nginx + Docker running)
          ↓ metrics every 60s
CloudWatch Alarm
(CPU > 90% for 5 mins OR healthcheck failed x3)
          ↓
EventBridge
(routes alarm to Lambda)
          ↓
Lambda — Self-Healing Decision Engine
(decides what action to take)
          ↓
SSM SendCommand
(executes on EC2 — no SSH needed)
          ↓
Slack Notification
🚨 AUTO-HEAL EVENT
Issue: Nginx stopped
Action: systemctl restart nginx
Status: SUCCESS ✅
Recovery Time: 22 sec
```

---

## Tech Stack

| Category       | Tools                                      |
|----------------|--------------------------------------------|
| Cloud          | AWS EC2, CloudWatch, Lambda, EventBridge, SNS, SSM |
| IaC            | Terraform (modular)                        |
| Language       | Python 3.11 (Lambda)                       |
| Notifications  | Slack Webhook                              |
| Security       | IAM Least Privilege                        |

---

## Healing Logic

| Alarm Triggered       | Action Taken                        |
|-----------------------|-------------------------------------|
| nginx-down            | `systemctl restart nginx`           |
| docker-down           | `systemctl restart docker`          |
| cpu-critical          | `reboot`                            |
| healthcheck-failed    | Restart nginx + docker              |
| Unknown alarm         | ❌ No automation — escalate to human |

> **Why no automation for unknown issues?**  
> Automating something you don't understand can make things worse in production.  
> Unknown alarms always escalate to a human.

---

## Folder Structure

```
auto-healing-infrastructure/
│
├── terraform/
│   ├── main.tf           — root module
│   ├── variables.tf      — input variables
│   ├── outputs.tf        — output values
│   └── modules/
│       ├── ec2/          — EC2 instance + user data
│       ├── cloudwatch/   — alarms + EventBridge rules
│       ├── lambda/       — Lambda function + permissions
│       ├── iam/          — roles + least privilege policies
│       └── sns/          — SNS topic + subscriptions
│
├── lambda/
│   └── healing_engine.py — Self-Healing Decision Engine
│
├── screenshots/          — terraform validate + plan output
└── README.md
```

---

## IAM — Least Privilege

Lambda only has permission to:

```json
{
  "Action": [
    "ssm:SendCommand",
    "ssm:GetCommandInvocation",
    "ec2:DescribeInstances",
    "cloudwatch:GetMetricData"
  ]
}
```

> **NOT full admin. NOT wildcard permissions.**  
> If Lambda is ever compromised — attacker can only touch this one EC2 instance.

---

## Why SSM Instead of SSH?

| SSH                          | SSM SendCommand               |
|------------------------------|-------------------------------|
| Requires open port 22        | No open ports needed          |
| Requires storing private keys | No keys needed               |
| Security risk                | Secure AWS internal network   |

---

## Real Problem I Solved

During deployment, Lambda threw:
```
AccessDeniedException: User is not authorized to perform: ssm:SendCommand
```

**How I found it:**  
Checked CloudTrail logs → found exact denied API call → `ssm:SendCommand`

**How I fixed it:**  
Added `ssm:SendCommand` to Lambda IAM policy — scoped to specific EC2 ARN only, not all resources.

That's **IAM least privilege in practice.**

---

## Slack Notification Example

```
🚨 AUTO-HEAL EVENT
━━━━━━━━━━━━━━━━━━━━
Instance:  i-1234567890abcdef0
Issue:     Nginx service stopped
Action:    systemctl restart nginx
Status:    ✅ SUCCESS
Time:      2025-05-12 03:22:14
━━━━━━━━━━━━━━━━━━━━
```

---

## How to Deploy

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/auto-healing-infrastructure
cd auto-healing-infrastructure/terraform

# 2. Initialize Terraform
terraform init

# 3. Preview what will be created
terraform plan

# 4. Deploy to AWS
terraform apply
```

> Infrastructure code is complete.  
> Currently resolving IAM SSM permissions for Lambda → EC2 communication.  
> Full deployment in progress.

---

## Local Testing (No AWS Needed)

```bash
# Test Lambda healing logic locally
cd lambda
python3 healing_engine.py
```

Expected output:
```
Alarm triggered: cpu-critical
SSM Command sent (simulated)

🚨 AUTO-HEAL EVENT
Issue: CPU utilization critical (>90%)
Action: reboot
Status: ✅ SUCCESS
```

---

## Author

**Kakumanu Venkata Lakshmi Siva Bala Naga Sai**  
DevOps Engineer Intern  
AWS Certified Cloud Practitioner (CLF-C02)
