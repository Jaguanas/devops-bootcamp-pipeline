# devops-bootcamp-pipeline

An automated deployment pipeline for a PHP web application, built with GitHub, Concourse CI, Docker-compatible container images and AWS ECS Fargate.

## Project overview

The project demonstrates infrastructure provisioning, server configuration, continuous integration and continuous deployment. When changes are merged into the `dev` branch, Concourse tests the application, builds and publishes a container image, and deploys it to AWS Fargate.

## Architecture

```text
Developer → GitHub (dev branch)
                  ↓
          Concourse CI (EC2)
                  ↓
          PHP syntax check
                  ↓
       Kaniko Docker image build
                  ↓
         Docker Hub registry
                  ↓
          AWS ECS Fargate
                  ↓
           PHP website

Terraform → AWS EC2 and ECS infrastructure
Bash + Ansible → Ubuntu server and Concourse configuration
```

**CI server:** Concourse runs in Docker Compose with PostgreSQL on an Ubuntu EC2 instance.  
**Application:** A PHP 8.3 / Apache container runs as an ECS Fargate task.  
**Container registry:** `ricardssmans/app` on Docker Hub.

## Technology stack

| Technology | Role |
| --- | --- |
| Git and GitHub | Source control and pull requests |
| Terraform | AWS infrastructure provisioning |
| Bash | Server bootstrap and environment checks |
| Ansible | Ubuntu server and Concourse configuration |
| Docker and Docker Compose | Containerization and CI server services |
| Concourse CI | Automated build and deployment pipeline |
| Kaniko | Build container images from the Dockerfile |
| Docker Hub | Store application images |
| AWS ECS Fargate | Run and update the application |
| PHP and Apache | Serve the web application |
| PostgreSQL | Concourse database |

## Repository structure

| Path | Description |
| --- | --- |
| `app/index.php` | PHP web application |
| `Dockerfile` | Application container image definition |
| `ci/pipeline.yml` | Concourse CI/CD pipeline |
| `ci/deploy.py` | AWS ECS deployment script |
| `terraform/` | EC2, security groups and ECS infrastructure |
| `ansible/` | Server and Concourse configuration playbooks |
| `concourse/compose.yml` | Concourse and PostgreSQL services |
| `concourse/.env.example` | Configuration variable template |
| `scripts/` | Installation and diagnostic scripts |

## CI/CD pipeline

The `devops-capstone` pipeline monitors the GitHub `dev` branch and performs the following steps:

1. **Source checkout:** Retrieve the latest commit from GitHub.
2. **PHP validation:** Check `app/index.php` using `php -l`.
3. **Image build:** Use Kaniko to build the Docker-compatible image from the project's `Dockerfile`.
4. **Image publication:** Push `ricardssmans/app:latest` to Docker Hub.
5. **Deployment:** Use `ci/deploy.py` to register a new ECS task definition and update the application service.
6. **Service update:** AWS ECS launches the new application task and stops the old task as the deployment completes.

The pipeline automatically detects commits on `dev`, so a manual build trigger is not required for the normal workflow.

## AWS environment

| Resource | Name / setting |
| --- | --- |
| AWS Region | `eu-west-1` (Ireland) |
| Concourse EC2 instance | `Team3-ConcourseServer` |
| ECS cluster | `team3-app-cluster` |
| ECS service | `team3-app-service` |
| Docker Hub image | `ricardssmans/app:latest` |
| Application protocol | HTTP, port 80 |

To find the live site, open **AWS Console → ECS → Clusters → `team3-app-cluster` → Services → `team3-app-service` → Tasks**. Select the **Running** task and find its public IP under **Networking**. Open that address in a browser using HTTP.

## Configuration and setup

### Prerequisites

AWS access with the necessary permissions, Git, Terraform, an Ubuntu EC2 host and authorized Concourse/Docker Hub credentials. Use the AWS region and account resources assigned to the team.

### 1. Infrastructure — Terraform

Review the AWS values in `terraform/main.tf` and `terraform/fargate.tf` for the intended account and environment, then run from the repository root:

```bash
cd terraform
terraform init
terraform plan
terraform apply
cd ..
```

Coordinate infrastructure changes with the team before applying them to shared AWS resources.

### 2. Server configuration — Ansible

On the Ubuntu EC2 build server, clone the project and switch to `dev`:

```bash
git clone https://github.com/Jaguanas/devops-bootcamp-pipeline.git
cd devops-bootcamp-pipeline
git switch dev

sudo ansible-playbook -i ansible/inventory.ini ansible/configure-build-server.yml
sudo ansible-playbook -i ansible/inventory.ini ansible/prepare-concourse.yml
```

Create `/opt/concourse/.env` using `concourse/.env.example` as a template, provide the environment's private values, and protect the file with restricted permissions. Deploy Concourse:

```bash
sudo ansible-playbook -i ansible/inventory.ini ansible/deploy-concourse.yml
```

Concourse is bound to `127.0.0.1:8080` on the EC2 host. Access the web interface through an authorized connection to that host.

### 3. CI/CD configuration — Concourse

Log in to Concourse using the `fly` CLI and configure the `devops-capstone` pipeline from `ci/pipeline.yml`, supplying the `dockerhub_token` credential through the team's authorized configuration process.

The pipeline is configured to deploy to AWS Fargate when a build succeeds.

## End-to-end demonstration

The team verified automatic deployment by updating the application page from version **1.0** to **1.1**:

1. Update `app/index.php` on a feature branch.
2. Merge the pull request into `dev`.
3. Observe the Concourse pipeline start automatically and pass the PHP, image-build and publication stages.
4. Confirm that AWS ECS deploys the updated task definition.
5. Open the running task's public address and verify the updated page.

**Demonstration result:** Concourse build `build-and-test/13` was automatically started, and the application was deployed as ECS task definition revision `team3-app:5`.

## AWS resource management

Use Terraform to review changes to infrastructure and coordinate changes with the team. At the end of the lab, authorized team members can review the cleanup plan before deleting shared resources:

```bash
cd terraform
terraform plan -destroy
```

Never commit real credentials, private keys, `.env` files or Terraform state files to the repository.