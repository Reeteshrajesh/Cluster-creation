# 🚀 **Terraform EKS Setup – Complete Prerequisites**

This document shows **everything you must do before you run Terraform** to create your production EKS cluster.

---

## ✅ **1️⃣ Install Required CLI Tools**

On your workstation (Mac/Linux/Windows WSL):

---

### 📌 Terraform

Verify:

```bash
terraform -version
```

Must be >= `v1.3.0`.

Install:

* [Terraform Download](https://developer.hashicorp.com/terraform/downloads)

---

### 📌 AWS CLI

Verify:

```bash
aws --version
```

Must be >= `v2.x`.

Install:

* [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

---

### 📌 kubectl

Verify:

```bash
kubectl version --client
```

Install:

* [Install kubectl](https://kubernetes.io/docs/tasks/tools/)

---

### 📌 Helm

Verify:

```bash
helm version
```

Install:

* [Install Helm](https://helm.sh/docs/intro/install/)

---

## ✅ **2️⃣ Configure AWS CLI**

Set up your AWS credentials:

```bash
aws configure
```

You will be prompted for:

* AWS Access Key ID
* AWS Secret Access Key
* Default region (e.g., `ap-south-1`)
* Default output format (`json`)

✅ Verify your credentials work:

```bash
aws sts get-caller-identity
```

✅ You should see your account ID and user/role ARN.

---

## ✅ **3️⃣ Confirm IAM Permissions**

Make sure your credentials have permissions to:

* ✅ Create VPC, Subnets, Route Tables, IGWs, NAT Gateways
* ✅ Create EKS clusters and node groups
* ✅ Create IAM Roles and Policies
* ✅ Create EC2 instances
* ✅ Attach IAM policies to nodes
* ✅ Create Load Balancers

**Recommended Managed Policy**:

* `AdministratorAccess`
  or equivalent permissions.

---

## ✅ **4️⃣ Create ALB Controller IAM Policy**

**Important:** You are attaching this policy to your node IAM role. It must exist first.

---

**Download the policy JSON:**

```bash
curl -o alb-iam-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

---

**Create the policy:**

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://alb-iam-policy.json
```

✅ Copy the ARN from the output, e.g.,

```
arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy
```

and **update your `main.tf` to use this ARN** in:

```hcl
iam_role_additional_policies = [
  ...
  "arn:aws:iam::123456789012:policy/AWSLoadBalancerControllerIAMPolicy",
  ...
]
```

---

## ✅ **5️⃣ Prepare Variables**

Verify your `variables.tf` and optionally create `terraform.tfvars`:

Example `terraform.tfvars`:

```hcl
region             = "ap-south-1"
cluster_name       = "prod-eks-cluster"
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
private_subnet_cidrs = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]
node_instance_type = "t3.medium"
desired_capacity   = 3
```

✅ Double-check:

* No overlapping CIDRs.
* Cluster name is correct.

---

## ✅ **6️⃣ (Optional) Prepare an EC2 Key Pair**

If you want SSH access to nodes:

* Create a Key Pair in AWS Console or CLI:

```bash
aws ec2 create-key-pair --key-name my-eks-keypair
```

* Reference it in your `main.tf` node group config:

```hcl
key_name = "my-eks-keypair"
```

---

## ✅ **7️⃣ Initialize Terraform**

Once all of the above is complete:

```bash
terraform init
```

✅ This will:

* Download modules
* Download providers
* Lock dependency versions

✅ You should see:

```
Terraform has been successfully initialized!
```

---

## ✅ **8️⃣ Generate a Plan**

Review what Terraform will create:

```bash
terraform plan
```

✅ Verify:

* VPC
* Subnets
* Route tables
* NAT Gateway
* EKS cluster
* Node groups
* IAM roles
* Helm add-ons

---

## ✅ **9️⃣ Apply**

When ready:

```bash
terraform apply
```

✅ Confirm with `yes` when prompted.

Provisioning typically takes **10–20 minutes**.

---

## ✅ **10️⃣ Update kubeconfig**

When apply completes:

```bash
aws eks update-kubeconfig --name prod-eks-cluster --region ap-south-1
```

✅ Test connectivity:

```bash
kubectl get nodes
```

✅ All nodes should be `Ready`.

---

## 📝 **Quick Recap Checklist**

* ✅ Installed: Terraform, AWS CLI, kubectl, Helm
* ✅ AWS credentials configured
* ✅ IAM permissions confirmed
* ✅ ALB policy created
* ✅ Variables checked
* ✅ `terraform init`
* ✅ `terraform plan`
* ✅ `terraform apply`


