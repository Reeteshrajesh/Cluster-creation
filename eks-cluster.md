# 📄 **Document: Creating an Amazon EKS Cluster (Production-Ready)**

---

## 🎯 **Purpose**

This document provides detailed instructions to create a production-ready **Amazon EKS cluster** using `eksctl`, configure IAM permissions, install essential add-ons, and verify the setup.

---

## 📘 **Prerequisites**

Before you begin, ensure:

* ✅ AWS CLI installed and configured (`aws configure`)
* ✅ `eksctl` installed ([Install Guide](https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html))
* ✅ `kubectl` installed ([Install Guide](https://kubernetes.io/docs/tasks/tools/))
* ✅ Your AWS account has sufficient permissions to create:

* EKS clusters
* EC2 instances
* IAM roles and policies
* ✅ A VPC with at least 3 public and 3 private subnets in different Availability Zones

---

## 🔹 **Step 1: Tag Subnets**

**Purpose:** EKS uses subnet tags to identify where to place resources.

For **public subnets**, tag:

```
Key: kubernetes.io/role/elb
Value: 1
```

For **private subnets**, tag:

```
Key: kubernetes.io/role/internal-elb
Value: 1
```

**Additionally**, tag all subnets for cluster association:

```
Key: kubernetes.io/cluster/<CLUSTER_NAME>
Value: shared
```

**Example command:**

```bash
aws ec2 create-tags \
  --resources subnet-0123456789abcdef0 \
  --tags Key=kubernetes.io/role/elb,Value=1
```

Repeat for each subnet.

---

## 🔹 **Step 2: Create Security Groups**

EKS will create security groups automatically if you let `eksctl` manage them.
If you need custom security groups, ensure they:

* ✅ Allow inbound/outbound node communication
* ✅ Allow API server access (port 443) from your workstation
* ✅ Allow all traffic within the node group

---


## 🟢 2️⃣ eksctl Cluster YAML

**Why use YAML?**

* Declarative, repeatable, easy to version-control.
* You can modify and re-apply.

Below is a **production-ready eksctl cluster config YAML**, supporting:
* ✅ Kubernetes 1.29
* ✅ Managed Nodegroups
* ✅ 3 public + 3 private subnets
* ✅ Custom node IAM policies

**📄 `eks-cluster.yaml`**

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: prod-eks-cluster
  region: ap-south-1
  version: "1.29"

vpc:
  id: vpc-xxxxxxxx          # <-- YOUR VPC ID
  subnets:
    public:
      ap-south-1a: { id: subnet-xxxxxxxx }
      ap-south-1b: { id: subnet-xxxxxxxx }
      ap-south-1c: { id: subnet-xxxxxxxx }
    private:
      ap-south-1a: { id: subnet-xxxxxxxx }
      ap-south-1b: { id: subnet-xxxxxxxx }
      ap-south-1c: { id: subnet-xxxxxxxx }

managedNodeGroups:
  - name: mng-on-demand
    instanceTypes: ["t3.medium"]
    minSize: 3
    maxSize: 6
    desiredCapacity: 3
    volumeSize: 50
    labels:
      lifecycle: on-demand
    tags:
      nodegroup-role: on-demand
    iam:
      withAddonPolicies:
        autoScaler: true
        externalDNS: true
        albIngress: true
        ebs: true
        cloudWatch: true
    ssh:
      allow: true
      publicKeyName: your-ec2-keypair-name   # <-- your EC2 KeyPair for SSH
```

**How to create:**

```bash
eksctl create cluster -f eks-cluster.yaml
```
---

## 🔹 **Step 4: Configure kubectl Access**

After creation, configure your kubeconfig file:

```bash
aws eks update-kubeconfig --name my-prod-cluster --region ap-south-1
```

**Verify connectivity:**

```bash
kubectl get nodes
```

You should see your nodes in `Ready` state.

---

## 🔹 **Step 5: Enable OIDC Provider**

**Purpose:** Allows Kubernetes ServiceAccounts to securely assume AWS IAM roles.

Enable OIDC for your cluster:

```bash
eksctl utils associate-iam-oidc-provider \
  --cluster my-prod-cluster \
  --approve
```

**Verify:**

```bash
aws eks describe-cluster --name my-prod-cluster --query "cluster.identity.oidc.issuer" --output text
```

You should see a URL.

---

## 🔹 **Step 6: Install AWS Load Balancer Controller**

**Purpose:** Automatically creates ALBs/NLBs for Kubernetes Ingress resources.

### 6.1 Create IAM Policy

Download the policy:

```bash
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
```

Create the policy:

```bash
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file://iam-policy.json
```

### 6.2 Create ServiceAccount with IAM Role

```bash
eksctl create iamserviceaccount \
  --cluster my-prod-cluster \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

Replace `<AWS_ACCOUNT_ID>` with your AWS Account ID.

### 6.3 Install the Controller via Helm

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=my-prod-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1
```

**Verify:**

```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
```

---

## 🔹 **Step 7: Install EBS CSI Driver**

**Purpose:** Enables dynamic provisioning of EBS volumes for PersistentVolumeClaims.

```bash
eksctl create iamserviceaccount \
  --cluster my-prod-cluster \
  --namespace kube-system \
  --name ebs-csi-controller-sa \
  --role-name AmazonEKS_EBS_CSI_DriverRole \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve
```

Install the driver:

```bash
eksctl create addon \
  --cluster my-prod-cluster \
  --name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::<AWS_ACCOUNT_ID>:role/AmazonEKS_EBS_CSI_DriverRole \
  --force
```

---

## 🔹 **Step 8: Install Metrics Server**

**Purpose:** Enables CPU/Memory metrics (required for autoscaling).

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

Verify:

```bash
kubectl get deployment metrics-server -n kube-system
```

---
## 🔹 Step 9: Cluster Autoscaler

**Purpose:** Automatically scale nodes.

**Create IAM policy:**
Already included if you used `withAddonPolicies.autoScaler: true` in your eksctl YAML.

**Install via Helm:**

```bash
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set autoDiscovery.clusterName=prod-eks-cluster \
  --set awsRegion=ap-south-1 \
  --set rbac.serviceAccount.create=false \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set extraArgs.balance-similar-node-groups=true \
  --set extraArgs.skip-nodes-with-system-pods=false \
  --set extraArgs.expander=least-waste
```

---

## 🔹 Step 10: Cert Manager

**Purpose:** Automate SSL certificates (Let’s Encrypt, etc.)

**Install:**

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.0/cert-manager.yaml
```

---


## 🔹 **Step 11: Configure a Default StorageClass**

**Purpose:** Define default disk provisioning (e.g., gp3 volumes).

Example YAML:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
```

Apply:

```bash
kubectl apply -f storageclass-gp3.yaml
```

---

## 🔹 **Step 12: Verify the Cluster**

Test everything works:

✅ Nodes:

```bash
kubectl get nodes
```

✅ Storage:

```bash
kubectl get storageclass
```

✅ Load Balancer Controller:

```bash
kubectl get pods -n kube-system
```
✅Deploy a test Nginx (Deploy a test workload (e.g., nginx) and confirm an ALB is created):

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```
---

## 📑 **Conclusion**

You now have a production-ready EKS cluster with:

* ✅ Managed nodes
* ✅ OIDC authentication
* ✅ ALB Ingress Controller
* ✅ Dynamic EBS storage
* ✅ Metrics Server

---

✅ **Tip:** Always configure:

* Monitoring (Prometheus/Grafana)
* Logging (CloudWatch/Loki)
* Secrets management (AWS Secrets Manager)

---

## 📂 **Files to Keep**

* `storageclass-gp3.yaml`
* OIDC IAM policies
* Helm chart configurations
