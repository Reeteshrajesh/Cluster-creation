# 📘 **Amazon EKS Production Cluster – Terraform Setup**

This project provides a **complete Terraform configuration** to deploy a **production-ready Amazon EKS cluster** on AWS.
It includes:

* ✅ VPC with public and private subnets
* ✅ NAT Gateway and Internet Gateway
* ✅ EKS cluster with managed node groups
* ✅ Essential Kubernetes add-ons:

* AWS Load Balancer Controller
* EBS CSI Driver
* Cluster Autoscaler
* Metrics Server

---

## 🏗️ **Project Structure**

```
.
├── main.tf            # Core resources (VPC, EKS, add-ons)
├── variables.tf       # Input variables
├── outputs.tf         # Outputs after deployment
├── provider.tf        # AWS provider configuration
├── versions.tf        # Terraform and provider versions
└── README.md          # Project documentation
```

---

## ✨ **Features**

* **Highly available VPC** across 3 Availability Zones
* Public subnets (for ALB) and private subnets (for nodes)
* NAT Gateway for outbound internet access
* EKS cluster running Kubernetes `1.29`
* Managed Node Group with auto scaling
* OIDC integration for secure IAM roles
* Pre-installed production add-ons:

  * **AWS Load Balancer Controller** (Ingress)
  * **EBS CSI Driver** (Persistent storage)
  * **Metrics Server** (Resource metrics)
  * **Cluster Autoscaler** (Node scaling)

---

## 🛠️ **Prerequisites**

Make sure you have:

* ✅ [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured (`aws configure`)
* ✅ [kubectl](https://kubernetes.io/docs/tasks/tools/) installed
* ✅ [Terraform v1.3+](https://www.terraform.io/downloads.html) installed
* ✅ An existing **AWS Key Pair** if you plan to SSH into worker nodes

---

## ⚙️ **How to Use**

1️⃣ **Initialize Terraform**

```bash
terraform init
```

2️⃣ **Review the plan**

```bash
terraform plan
```

3️⃣ **Apply configuration**

```bash
terraform apply
```

4️⃣ **Update your kubeconfig**

```bash
aws eks update-kubeconfig --name prod-eks-cluster --region ap-south-1
```

5️⃣ **Verify connectivity**

```bash
kubectl get nodes
```

You should see the worker nodes in `Ready` state.

---

## 🌐 **Outputs**

After successful deployment, Terraform will display:

* VPC ID
* Public and private subnet IDs
* EKS cluster name
* Path to your kubeconfig file

Example:

```
Outputs:

eks_cluster_name = "prod-eks-cluster"
kubeconfig       = "/path/to/kubeconfig_prod-eks-cluster"
private_subnets  = [...]
public_subnets   = [...]
vpc_id           = "vpc-xxxxxxxx"
```

---

## ✨ **Customization**

You can override default variables by editing `variables.tf` or using CLI arguments:

Example:

```bash
terraform apply \
  -var="region=us-east-1" \
  -var="node_instance_type=t3.large" \
  -var="desired_capacity=4"
```

---

## 🛡️ **Security Considerations**

* ✅ All worker nodes are deployed in **private subnets**.
* ✅ Only ALB (Ingress) is exposed publicly.
* ✅ OIDC is enabled for secure IAM role access.
* ✅ Ensure security group rules match your workload needs.

---

## 💡 **Next Steps**

After cluster provisioning, you can:

* Install monitoring (Prometheus + Grafana)
* Set up logging (CloudWatch, Loki)
* Configure ingress certificates (Cert Manager + ACM)
* Deploy your microservices

---

## 📝 **License**

This project is open-source and available under the [MIT License](LICENSE).

---

## 🙌 **Author**

Created with ❤️ by \Reetesh Kumar.

---

## 📫 **Support**

Questions or issues? Feel free to open an issue or contact \[[Reetesh kumar](mailto:uttamreetesh@gmail.com)].

---
