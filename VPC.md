# 📘 **Guide: Creating a Production-Ready AWS VPC for EKS**

---

## 🎯 **Purpose**

A **Virtual Private Cloud (VPC)** isolates your AWS resources in a logically separated network.
EKS **requires** a VPC with both **public subnets** (for LoadBalancers) and **private subnets** (for worker nodes), with proper routing.

---

## 🟢 **1️⃣ What is a VPC?**

A **VPC** is your own network in AWS.
It defines:

* ✅ **CIDR range** (the IP space, e.g., `10.0.0.0/16`)
* ✅ **Subnets** (smaller ranges of IPs)
* ✅ **Routing** (how traffic flows)
* ✅ **Internet Gateway (IGW)** (access to the Internet)
* ✅ **NAT Gateway** (allow private subnets to reach the Internet)
* ✅ **Security Groups & NACLs** (firewall rules)

---

## 🟢 **2️⃣ Subnet Strategy**

**EKS Best Practice:**

* At least **3 public subnets** in different AZs
* At least **3 private subnets** in different AZs
* Public subnets: ALBs/NLBs
* Private subnets: EKS nodes and workloads

**Why?**

* High Availability across AZs
* Private nodes (more secure)
* LoadBalancer ingress in public subnets

---

## 🟢 **3️⃣ Core Components**

Let’s define them clearly:

| Component            | Purpose                                            |
| -------------------- | -------------------------------------------------- |
| **VPC**              | The whole network                                  |
| **Public Subnet**    | Routes to Internet Gateway (public access)         |
| **Private Subnet**   | Routes to NAT Gateway (outbound internet only)     |
| **Internet Gateway** | Enables internet access for public subnets         |
| **NAT Gateway**      | Lets private subnets initiate outbound connections |
| **Route Tables**     | Define how traffic is routed                       |
| **Security Groups**  | Control inbound/outbound traffic to EC2, EKS, etc. |

---

## 🟢 **4️⃣ Example Architecture**

| Subnet           | CIDR Block    | AZ          | Type    |
| ---------------- | ------------- | ----------- | ------- |
| Public Subnet 1  | 10.0.0.0/20   | ap-south-1a | Public  |
| Public Subnet 2  | 10.0.16.0/20  | ap-south-1b | Public  |
| Public Subnet 3  | 10.0.32.0/20  | ap-south-1c | Public  |
| Private Subnet 1 | 10.0.128.0/20 | ap-south-1a | Private |
| Private Subnet 2 | 10.0.144.0/20 | ap-south-1b | Private |
| Private Subnet 3 | 10.0.160.0/20 | ap-south-1c | Private |

---

## 🟢 **5️⃣ VPC Creation Options**

### ✅ Option 1: Use `eksctl`

**Easiest for EKS.**
`eksctl` can **auto-create** a VPC with recommended configuration.

Example:

```bash
eksctl create cluster \
  --name my-cluster \
  --region ap-south-1 \
  --nodes 3
```

This creates:

* VPC
* 3 public + 3 private subnets
* IGW, NAT Gateway
* Route tables

✅ **Pros:** Fast, zero manual config
❌ **Cons:** Less control over subnet CIDRs, naming

---

### ✅ Option 2: Use Terraform (Best Practice for Production)

This is the **most robust**, reusable way.

Example Terraform module: [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)

---

## 🟢 **6️⃣ Terraform Example VPC Code**

Below is **complete Terraform code** for a production VPC with 3 public and 3 private subnets.

**📄 `vpc.tf`**

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "prod-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
  private_subnets = ["10.0.128.0/20", "10.0.144.0/20", "10.0.160.0/20"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "kubernetes.io/cluster/prod-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

✅ This automatically:

* Creates the VPC
* Subnets (public/private)
* Internet Gateway
* NAT Gateway
* Route tables
* Tags needed for EKS

**Usage:**

```bash
terraform init
terraform plan
terraform apply
```

---

## 🟢 **7️⃣ Manual Console Steps**

If you prefer to **click in AWS Console**, do this:

1. **Create VPC**

   * CIDR: `10.0.0.0/16`
2. **Create Subnets**

   * Public in each AZ (`10.0.0.0/20`, etc.)
   * Private in each AZ
3. **Create Internet Gateway**

   * Attach to VPC
4. **Create NAT Gateway**

   * Create Elastic IP
   * Associate NAT Gateway in one public subnet
5. **Create Route Tables**

   * **Public Route Table**

     * Route `0.0.0.0/0` → Internet Gateway
     * Associate with public subnets
   * **Private Route Table**

     * Route `0.0.0.0/0` → NAT Gateway
     * Associate with private subnets
6. **Subnet Tagging**

   * Public subnets: `kubernetes.io/role/elb=1`
   * Private subnets: `kubernetes.io/role/internal-elb=1`
   * All subnets: `kubernetes.io/cluster/<CLUSTER_NAME>=shared`

---

## 🟢 **8️⃣ Security Groups**

**EKS creates security groups automatically** if you use `eksctl`.
If you create manually, ensure:

* Worker nodes allow traffic from control plane (port 443)
* Nodes allow intra-node communication (all TCP/UDP)

---

## 🟢 **9️⃣ Best Practices**

* ✅ Always use **3 AZs** for resilience
* ✅ Use **private subnets** for nodes
* ✅ Enable **DNS support & hostnames**
* ✅ Tag subnets correctly
* ✅ Use Terraform for repeatability
* ✅ Use **NAT Gateway** for outbound internet in private subnets
* ✅ Keep your CIDR ranges spacious (`/16` for VPC, `/20` per subnet)

---

## 🟢 **10️⃣ Validation Checklist**

* ✅ VPC created with correct CIDR
* ✅ Subnets created and tagged
* ✅ IGW and NAT gateway attached
* ✅ Public subnets route to IGW
* ✅ Private subnets route to NAT
* ✅ DNS hostnames enabled
* ✅ Tested from EC2 in private subnet:

```bash
curl https://google.com
```

✅ Verified subnet tags via:

```bash
aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
```

---

## 📑 **Conclusion**

With this guide, you can:

* Understand all core VPC concepts
* Create a production-ready VPC manually or via Terraform
* Prepare networking for a secure, scalable EKS cluster

-----
-----
-----
# 🟢 **Additional Information & Learning for Deeper Understanding**

---

## 🌱 **1️⃣ Why do we split subnets into public and private?**

**Public Subnet**

* A subnet whose route table **routes 0.0.0.0/0 to the Internet Gateway (IGW)**.
* Resources inside can be reached **directly from the internet**, e.g.,

  * ALB/NLB
  * Bastion Hosts
* Used when you need inbound traffic from the public internet.

**Private Subnet**

* Has no direct route to IGW.
* Has a route to a **NAT Gateway** in a public subnet.
* Resources can **reach out to the internet**, e.g.,

  * Download updates
  * Pull container images
  * Send logs
* But **the internet cannot reach them directly** (safer).

✅ **Tip:**
EKS worker nodes *should* be in **private subnets** for security.

---

## 🌱 **2️⃣ What is a NAT Gateway?**

* **NAT = Network Address Translation**
* Sits in a **public subnet**
* Allows resources in private subnets to:

  * Initiate outbound connections
  * Get response traffic back
* Does **not** allow inbound connections
* You **pay per hour and per GB** (consider cost!)

---

## 🌱 **3️⃣ What are Route Tables?**

Every subnet has a **route table**:

* Public Subnets:

  ```
  0.0.0.0/0 --> IGW
  ```
* Private Subnets:

  ```
  0.0.0.0/0 --> NAT Gateway
  ```
* Local VPC traffic is always implicitly allowed.

✅ **Tip:**
Without correct routes, your nodes won’t pull images or connect to AWS APIs.

---

## 🌱 **4️⃣ What are Security Groups vs. NACLs?**

**Security Groups** (SG):

* Act as **firewalls on EC2/EKS ENIs**
* **Stateful** (if inbound traffic is allowed, response is automatically allowed)
* Applied at instance/pod level
* More commonly used for fine-grained control

**Network ACLs** (NACLs):

* Applied at subnet level
* **Stateless** (you must allow inbound and outbound separately)
* Rarely used alone for pod security

✅ For EKS, **Security Groups are primary**.

---

## 🌱 **5️⃣ How does EKS Networking Work?**

Each EKS node gets:

* An **Elastic Network Interface (ENI)**
* Secondary IP addresses for pods
* The number of IPs depends on:

  * Instance type
  * Pod density

✅ **Tip:**
Plan subnets with **enough IP space** to avoid running out of IPs for pods!

---

## 🌱 **6️⃣ Differences: Internet Gateway vs NAT Gateway**

| Feature               | Internet Gateway | NAT Gateway     |
| --------------------- | ---------------- | --------------- |
| Attached to           | VPC              | Subnet          |
| Inbound from Internet | Yes              | No              |
| Outbound to Internet  | Yes              | Yes             |
| Used by               | Public Subnets   | Private Subnets |

---

## 🌱 **7️⃣ VPC Peering and Transit Gateway**

As you grow:

* **VPC Peering** lets you connect VPCs directly (1-to-1)
* **Transit Gateway** allows **many VPCs to connect via a hub**

✅ If you expect:

* Multi-account architecture
* Separate dev/staging/prod VPCs

Consider planning **Transit Gateway** early.

---

## 🌱 **8️⃣ Cost Considerations**

Be aware:

* NAT Gateways **cost per hour + per GB**.
* Data transfer across AZs **incurs charges**.
* EIP for NAT is free if associated.
* Each NAT needs a public subnet.

✅ **Tip:**
Use **single NAT Gateway** unless high availability requires multiple.

---

## 🌱 **9️⃣ Monitoring & Troubleshooting**

✅ **Tools:**

* **VPC Flow Logs**

  * Record traffic at ENI/subnet level.
* **CloudWatch Logs**

  * Analyze flow logs.
* **Reachability Analyzer**

  * Test if traffic can flow between resources.
* **VPC Traffic Mirroring**

  * Capture packet-level traffic.

✅ **Troubleshooting Tips:**

* Nodes can’t pull images?
  Check NAT route and SGs.
* ALB not appearing?
  Subnet tagging missing.
* Pod IP exhaustion?
  Subnets too small.

---

## 🌱 **10️⃣ Tagging Best Practices**

Tag **everything** consistently:

| Resource    | Key                             | Value       |
| ----------- | ------------------------------- | ----------- |
| VPC         | Name                            | prod-vpc    |
| Subnets     | kubernetes.io/role/elb          | 1 (public)  |
| Subnets     | kubernetes.io/role/internal-elb | 1 (private) |
| All Subnets | kubernetes.io/cluster/<CLUSTER> | shared      |
| NAT Gateway | Name                            | prod-nat    |
| IGW         | Name                            | prod-igw    |

✅ **Tip:**
Well-tagged resources = easier billing and automation.

---

## 🌱 **11️⃣ IPv6**

While most EKS clusters use IPv4, AWS VPCs also support **dual-stack IPv6**.

Benefits:

* No NAT required
* Public IPv6 addresses by default
* Useful for future-proofing

**Considerations:**

* Not all AWS services support IPv6
* Security groups need separate IPv6 rules

---

## 🌱 **12️⃣ Further Reading and Study Resources**

Here are **top AWS docs & guides** to deepen your understanding:

* ✅ [AWS VPC Official Guide](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
* ✅ [EKS Networking](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
* ✅ [Amazon VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-bestpractices.html)
* ✅ [AWS Networking Fundamentals](https://aws.amazon.com/getting-started/hands-on/build-vpc-subnets/)
* ✅ [Terraform VPC Module](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest)
* ✅ [Kubernetes Networking Concepts](https://kubernetes.io/docs/concepts/cluster-administration/networking/)

---

## 🏁 **Final Tip**

**Mastering VPC is one of the highest-leverage skills in AWS.**

Every cloud architecture builds on:

* Solid **VPC design**
* Proper **subnetting**
* Correct **routing**
* Thoughtful **security**

---
---
---

# 🟢 **VPC Architecture Diagram (Production EKS Cluster)**

```
+-----------------------------------------------------------------------------------+
|                                  VPC: 10.0.0.0/16                                 |
|                                                                                   |
|       +----------------+           +----------------+           +----------------+|
|       | AZ-1a          |           | AZ-1b          |           | AZ-1c           |
|       |                |           |                |           |                 |
|       | +------------+ |           | +------------+ |           | +------------+  |
|       | | Public Sub | |           | | Public Sub | |           | | Public Sub |  |
|       | | 10.0.0.0/20| |           | |10.0.16.0/20| |           | |10.0.32.0/20|  |
|       | +------------+ |           | +------------+ |           | +------------+  |
|       |      |         |           |       |        |           |       |         |
|       |      |         |           |       |        |           |       |         |
|       |   +--------+   |           |                |           |                 |
|       |   |  IGW   |------------------------(Internet Gateway)------------------  |
|       |   +--------+    |                                                         |
|       |      |          |                                                         |
|       |   +---------+   |                                                         |
|       |   | NAT GW  |------------------------------+                              |
|       |   +---------+   |                          |                              |
|       +----------------+                           |                              |
|                                                    |                              |
|       +------------+           +------------+          +------------+             |
|       | Private Sub|           | Private Sub|          | Private Sub|             |
|       |10.0.128.0/20|          |10.0.144.0/20|         |10.0.160.0/20|            |
|       |            |           |            |          |            |             |
|       | [EKS Nodes]|           |[EKS Nodes] |          |[EKS Nodes] |             |
|       +------------+           +------------+          +------------+             |
|                                                                                   |
|                                                                                   |
|                        +-------------------------------------+                    |
|                        |          ALB (Public)              |                     |
|                        +-------------------------------------+                    |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

---

# 🟢 **Explanation of the Diagram**

✅ **VPC**

* CIDR Block: `10.0.0.0/16`
* Contains everything

✅ **Availability Zones (AZs)**

* 3 AZs: `ap-south-1a`, `ap-south-1b`, `ap-south-1c`
* High Availability

✅ **Public Subnets**

* `/20` each
* Host the ALB and NAT Gateway

✅ **Private Subnets**

* `/20` each
* Host the EKS worker nodes

✅ **Internet Gateway (IGW)**

* Enables outbound + inbound public traffic for public subnets

✅ **NAT Gateway**

* Lives in **one** public subnet
* Allows private nodes to access the Internet (e.g., pull images)

✅ **ALB**

* Created by the AWS Load Balancer Controller
* Fronts your Kubernetes Ingress resources
* Public

✅ **EKS Nodes**

* Lives in private subnets
* Communicate with the control plane over AWS private endpoints

---
