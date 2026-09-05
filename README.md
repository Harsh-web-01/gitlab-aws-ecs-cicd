# 🚀 GitLab CI/CD → AWS ECS Fargate

<p align="center">
  <img src="https://img.shields.io/badge/GitLab-CI%2FCD-FC6D26?logo=gitlab&logoColor=white" alt="GitLab CI/CD">
  <img src="https://img.shields.io/badge/AWS-ECS%20Fargate-FF9900?logo=amazonaws&logoColor=white" alt="AWS ECS Fargate">
  <img src="https://img.shields.io/badge/Amazon-ECR-FF9900?logo=amazonaws&logoColor=white" alt="Amazon ECR">
  <img src="https://img.shields.io/badge/Docker-Containerized-2496ED?logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/Tests-JUnit-C21325?logo=jest&logoColor=white" alt="JUnit">
</p>

<p align="center">
  <b>A hands-on CI/CD and cloud deployment project focused on automating application delivery from GitLab to AWS ECS Fargate.</b>
</p>

---

## 📌 About the Project

This project demonstrates how **GitLab CI/CD can orchestrate the complete application delivery lifecycle on AWS**.

The frontend application itself is based on an existing React + Vite setup; the primary work in this project is the **CI/CD pipeline, Dockerization, AWS integration, ECS deployment, task-definition revision management, and deployment verification**.

### The pipeline automates:

```text
Code Push
   ↓
Build
   ↓
Test
   ↓
Docker Image
   ↓
Amazon ECR
   ↓
New ECS Task Definition Revision
   ↓
Update ECS Service
   ↓
Wait for Stable Deployment
   ↓
Running Application on Fargate
```

---

## 🏗️ Architecture

<img width="1942" height="809" alt="ChatGPT Image Sep 6, 2026 at 01_36_50 AM" src="https://github.com/user-attachments/assets/1369ebf8-d0f3-4e53-8665-9f779f60ec92" />


The architecture highlights the main responsibility of this project: **GitLab acts as the CI/CD orchestration layer while AWS provides the container registry and runtime environment.**

---

## ⚙️ CI/CD Pipeline

The pipeline is divided into four logical stages:

| Stage | Job | Purpose |
|---|---|---|
| 🔨 `build` | `build_website` | Build the production application and store `build/` as an artifact |
| 📦 `package` | `build_docker_image` | Build the Docker image and push it to ECR |
| 🚀 `deploy` | `ecs_deploy` | Register a new ECS task-definition revision and update the service |
| 🧪 `test` | `test_website`, `unit_tests` | Validate the build and publish JUnit test results |

> **Note:** The current project demonstrates `build → package → deploy → test`. For a production deployment gate, tests should normally run before deployment: `build → test → package → deploy`.

### Pipeline orchestration

<img width="2213" height="1309" alt="96E789DB-62DB-43E0-9612-9A42131FEE96_1_201_a" src="https://github.com/user-attachments/assets/70b8d29c-9d52-4776-8e45-e5d2dc250d81" />


---

## 🐳 Docker & Amazon ECR

The application is packaged into a lightweight **Nginx Docker image**.

The Dockerfile copies the generated production files into:

```text
/usr/share/nginx/html
```

The CI job uses Docker-in-Docker so GitLab can build the image inside the runner.

The image is tagged with:

```text
learngitlabapp:<commit-sha>
learngitlabapp:latest
```

and pushed to a private **Amazon ECR** repository.

Using the commit SHA provides an identifiable version, while `latest` is used by the current ECS task-definition configuration.

---

## ☁️ Amazon ECS Fargate

The deployment uses:

| Resource | Configuration |
|---|---|
| ECS Cluster | `LearnGitlabApp-Cluster-Prod` |
| Launch Type | Fargate |
| Task Definition | `LearnGitlabAppTo-Prod` |
| ECS Service | `LearnGitlabApp-Service-Prod` |
| CPU | `256` = 0.25 vCPU |
| Memory | `512 MiB` = 0.5 GiB |
| Network Mode | `awsvpc` |
| Container Port | `80` |
| Container | Nginx |

The task definition is maintained in:

```text
aws/td_prod.json
```

### Deployment process

The deployment job runs:

```bash
aws ecs register-task-definition \
  --cli-input-json file://aws/td_prod.json
```

This creates a **new revision** of the ECS task definition.

The service is then updated:

```bash
aws ecs update-service \
  --cluster LearnGitlabApp-Cluster-Prod \
  --service LearnGitlabApp-Service-Prod \
  --task-definition LearnGitlabAppTo-Prod
```

Finally, the pipeline waits for ECS to finish the deployment:

```bash
aws ecs wait services-stable \
  --cluster LearnGitlabApp-Cluster-Prod \
  --services LearnGitlabApp-Service-Prod
```

This makes the deployment job wait for the service to reach a stable state instead of immediately finishing after the update request.

---

## 🧪 Testing

The project includes automated unit testing and GitLab JUnit reporting.

The test pipeline generates:

```text
reports/junit.xml
```

GitLab then displays the test results directly in the pipeline interface.

<img width="2156" height="1303" alt="06DB9E17-FFA3-43C3-946A-36DF08A34909_1_201_a" src="https://github.com/user-attachments/assets/edc22467-db79-4a5d-b143-71cb4c85ff61" />


---

## 🔐 GitLab CI/CD Variables

AWS and registry configuration are stored as GitLab CI/CD variables rather than hard-coded in the repository.

Examples include:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
AWS_S3_BUCKET
DOCKER_REGISTRY
```

**[Add your GitLab CI/CD variables screenshot here]**

> Never commit AWS access keys, secret keys, `.env` files, or other credentials to the repository.

---

## 💰 Estimated AWS Cost — `ap-south-1`

This is an **estimated on-demand cost**, not a fixed bill. AWS charges Fargate based on the resources consumed while the task is running. ECR charges primarily for stored image data; creating an ECR private repository itself has no separate repository-creation fee. Same-Region data transfer between ECR and Fargate is free according to AWS pricing.  
[Amazon Fargate Pricing](https://aws.amazon.com/fargate/pricing/) · [Amazon ECR Pricing](https://aws.amazon.com/ecr/pricing/)

### Fargate configuration

```text
Region:       ap-south-1 (Mumbai)
CPU:          256 = 0.25 vCPU
Memory:       512 MiB = 0.5 GiB
Tasks:        1
Runtime:      24 hours
```

Using the current regional Linux/x86 indicative rates of approximately **$0.04456/vCPU-hour** and **$0.00488/GB-hour**:

| Resource | Calculation | Approx. 24h |
|---|---:|---:|
| vCPU | `0.25 × $0.04456 × 24` | **$0.267** |
| Memory | `0.5 × $0.00488 × 24` | **$0.059** |
| **Fargate total** | | **≈ $0.326/day** |

That is approximately:

```text
≈ $0.33 / day
≈ $9.78 / 30 days
≈ ₹31 / day
≈ ₹923 / 30 days
```

The INR conversion uses approximately **₹94.42/USD** as a reference rate and will naturally fluctuate. Actual AWS billing can also differ because of taxes, discounts, architecture, usage, and other AWS resources.

### ECR cost

Amazon ECR private repositories are charged based on the amount of image data stored rather than simply for creating a repository. AWS's standard private ECR storage example is **$0.10 per GB-month**.

For example, if the repository contains:

```text
100 MB of stored images
```

for one day:

```text
0.1 GB × $0.10 × (1 / 30)
≈ $0.00033
```

So for a small project image, **ECR storage for one day is effectively negligible** compared with keeping the Fargate task running continuously.

> **Important:** The estimate above covers the basic Fargate task + ECR storage. It does **not** include possible charges from NAT Gateways, load balancers, public internet data transfer, CloudWatch logs, Elastic IPs, or other AWS resources that may exist in the networking/deployment setup.

### Cost takeaway

 **Fargate is the primary recurring cost** among the two services considered.

If the application is no longer needed, stopping/deleting the ECS service/tasks is important because Fargate compute charges continue while tasks are running.

---

## 📁 Project Structure

```text
.
├── aws/
│   └── td_prod.json
├── src/
├── tests/
├── public/
├── Dockerfile
├── .gitlab-ci.yml
├── package.json
├── package-lock.json
├── vite.config.js
└── README.md
```

---

## 🧠 Key Concepts Demonstrated

- GitLab CI/CD orchestration
- Pipeline stages and jobs
- GitLab artifacts
- Docker-in-Docker
- Docker image tagging
- Amazon ECR private repositories
- AWS CLI automation
- ECS Fargate
- ECS task definitions and revisions
- ECS service deployments
- Deployment stability checks
- IAM permissions
- GitLab CI/CD variables
- JUnit test reporting
- Containerized application deployment

