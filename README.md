# Three-Tier Cloud Application Deployment


## Project Overview

This project demonstrates the deployment of a simple three-tier web application on AWS using modern Cloud and DevOps practices.

---

## Key Components

The application consists of:

- Frontend : A lightweight HTML application served by Nginx

- Backend : A FastAPI REST API

- Database : PostgreSQL hosted on Amazon RDS

- Containerization : Docker ( Multi-stage builds ) , Docker Compose

- Container Platform : Amazon ECS

- Container Registry : Amazon ECR

- Infrastructure as Code : Terraform

- CI/CD : GitHub Actions

- Monitoring and Logging : AWS CloudWatch

- Secrets Management : AWS Secrets Manager ( self managed one for DB password and other provisioned through TF for other DB credentials )

- Authentication for CI/CD : GitHub Actions OIDC with an AWS IAM role

---

## Project Architecture Diagram

![Architecture Diagram](<images/Architecture Diagram.png>)



## Detailed Architectures

### Project Simple Main Idea

![Project Idea](<images/Project Idea.png>)

### Network Architecture

![Network Resource Map](<images/Network Resource Map.png>)


### Why separate subnet tiers?

![Subnets](<images/Subnets.png>)

**Public subnet**

- The Application Load Balancer is placed in public subnets because it needs to receive traffic from users on the internet.

**Private application subnets**

- The ECS application tasks are placed in private subnets. They are not directly exposed to the internet.

- Internet-facing application traffic is instead handled by the ALB.

**Database subnets**

- The database is placed in dedicated database subnets.

- This provides an additional layer of isolation:

    - The database does not need to be directly accessible from the internet.

    - PostgreSQL traffic is restricted using security groups.

    - Only the backend application can communicate with the database.

    - The subnet design allows the database layer to be expanded to multiple Availability Zones for production use.

### Web Request Flow

![Request Flow](<images/Request Flow.png>)



### CI/CD Popeline Workflow 

![CI-CD Workflow](<images/CI-CD Workflow.png>)


---

## How to run the project locally ( on Linux )

- The backend doesn't need to be directly accessible from your host. So, The intended path is:

            Browser
                ↓
            localhost:8080
                ↓
            Nginx
                ↓
            backend:8000
                ↓
            database:5432

- The startup sequence is :

            PostgreSQL
                ↓
            database healthy
                ↓
            Backend starts
                ↓
            backend /health passes
                ↓
            Frontend starts


---

### 1. Open a terminal in the project root

Navigate to the directory containing the docker-compose.yml file :

```
cd path/to/your-project
```

### 2. Build and start the containers

Run:

```
docker compose up --build
```

or you can run in detached mode ( in background )

```
docker compose up --build -d
```

**Note** : The `--build` is important the first time because Docker needs to build your backend and frontend images.

You should see three services starting:

```
database
backend
frontend
```


### 3. Check the containers

Open another terminal and run:

```
docker compose ps
```

![Docker Compose Build](<images/Docker Build.png>)



### 4. Open the application in your browser

Now open:

```
http://localhost:8080
```

You should see your frontend running through Nginx.

![App Frontend](<images/App Frontend.png>)



### 5. Test the complete application

Enter something into the input and click **Add button**

![Testing the app](<images/App Testing.png>)

 The actual request flow is:

```
              Browser
                │
                │ http://localhost:8080
                ▼
              Nginx
                │
                │ /api/items
                ▼
            FastAPI backend
                │
                │ SQLAlchemy
                ▼
              PostgreSQL
```


### 6. Test the health endpoint from your browser

You can also open:

```
http://localhost:8080/health
```

You should get:

![App Health Endpoint](<images/Health Endpoint.png>)


This request goes:

```
          Browser
            ↓
        localhost:8080
            ↓
          Nginx
            ↓
        backend:8000/health
            ↓
          FastAPI
```


### 7. Test the database health endpoint

Open:

```
http://localhost:8080/api/db-health
```

You should get :

![DB Health Endpoint](<images/DB Health.png>)


This confirms :

```
          Browser
            ↓
          Nginx
            ↓
          FastAPI
            ↓
         PostgreSQL
```

is working.



### 8. Stop the application

Run:

```
docker compose down
```

This stops and removes the containers, but **keeps your PostgreSQL volume**.

So if you start again:

```
docker compose up
```

your database data should still be there.

---

### 9. Completely reset the database

If you want to delete everything and start with an empty database:

```
docker compose down -v
```

Then:

```
docker compose up --build
```

**Note** : `-v` deletes the PostgreSQL volume and therefore your local database data.

---


## How to run the project on AWS Cloud 

Since S3 backend bucket must exist before Terraform can initialize that backend, and can't create the bucket using the same configuration that is already using that bucket as its backend.

A a separate bootstrap configuration is used and initialized first. (I nstead of going to AWS and create s3 bucket either through console or aws command ) 

1. Run :

```
cd infrastructure/bootstrap

terraform init

terraform apply
```

So the bucket is typically bootstrapped once, then the  actual infrastructure uses it as its remote state backend.

![S3 Bucket](<images/S3 Bucket.png>)


![S3 Bucket Console](<images/S3 Bucket Console.png>)


2. To provision the terraform infrastructure :

```
cd ..

terraform init

terraform plan

terraform apply
```

3. Configure the used variables in CI/CD  in the same GitHub repository:

    - Open your GitHub repository.

    - Go to Settings.

    - Under Secrets and variables, select Actions.

    - Open the Variables tab.

    - Click New repository variable.

    - Add each variable: 

        ```
        AWS_REGION
        AWS_ROLE_ARN
        ECR_FRONTEND_REPOSITORY
        ECR_BACKEND_REPOSITORY
        ECS_CLUSTER
        ECS_FRONTEND_SERVICE
        ECS_BACKEND_SERVICE
        ECS_FRONTEND_TASK_FAMILY
        ECS_BACKEND_TASK_FAMILY
        APP_URL
        ```

![Repo Vars](<images/Repo Vars.png>)

4. Commit and push the workflow and application code to main **or** change in the app files ( simplest : Add a comment )

```
git add .github/workflows/deploy.yml frontend/ backend/
git commit -m "Add GitHub Actions CI/CD pipeline"
git push origin main
```
These changes in the App files will trigger the Github Action CI/CD pipeline and will deploy its workflow


5. In GitHub, open the repository's Actions tab and select the Build, Test, and Deploy to ECS workflow run. You should see the Build and Test job complete first, followed by Build Images and Deploy.


![Backend Image](<images/Backend Image.png>)

![Another commit including app change](<images/Backend Image After Changes.png>)


6. Upon deployment completion and succession, access the app through browser using the alb_url output value from terraform infrastructure provisioning 

---

## How the pipeline handles secrets without hard-coding them in the repository

There are no long-lived AWS credentials in GitHub. GitHub Actions uses OIDC to assume a restricted IAM role. The database credential remains in AWS Secrets Manager.

---

## Key architectural decisions & their rationale


**ECS Fargate for containerized workloads**

AWS ECS with Fargate was chosen to run the frontend and backend containers without managing EC2 instances. This reduces infrastructure management overhead while providing a production-oriented container deployment model.

**Two Secrets for database credentials**

Database credentials are stored in two AWS Secrets Manager rather than in source code, Docker images, or GitHub Secrets. ECS retrieves the required secrets at runtime using IAM permissions.
 
![DB Secrets](<images/DB Secrets.png>)

First one is RDS-managed secret for storing the **username & password** ( generated by it ). 

![Managed DB Credentials](<images/Managed DB Credentials.png>)


Other TF provisioned one for other credentials. 

![Provisioned DB Credentials](<images/Provisioned DB Credentials.png>)


**GitHub Actions with OIDC**

GitHub Actions authenticates to AWS through GitHub's OIDC provider rather than using long-lived AWS access keys. This removes the need to store permanent AWS credentials in GitHub and limits access through an IAM trust policy.

---

## Trade-offs made due to the time limit. 


**CI/CD deploys both application tiers**

The initial pipeline builds and deploys both frontend and backend images when the application changes. A more optimized implementation would detect whether app/frontend or app/backend changed and deploy only the affected service

**No automated rollback strategy**

ECS deployments rely on the new task definition becoming healthy and stable. A more mature implementation could include automated rollback mechanisms based on deployment health metrics and application-level alarms.

**Basic observability**

CloudWatch logging is configured for ECS workloads, but the implementation does not include a complete observability stack with centralized dashboards, custom metrics, distributed tracing, actions taken upon alerts and comprehensive alerting.


**Optimizing and fixing the Github Actions CI/CD Pipeline**

As it isn't fully functionable. Reached to deployment but there are still issues in accessing the app. ( In build # 17 in Repo Actions )


---

## Production Considerations

For a production environment, the architecture would be expanded to improve availability, scalability, security, observability, and operational reliability.

The application would use HTTPS with AWS Certificate Manager and Route 53, with traffic protected by appropriate security controls such as AWS WAF.

ECS services would run multiple tasks across Availability Zones and use ECS Service Auto Scaling. RDS would use Multi-AZ deployment, automated backups, and point-in-time recovery.

Monitoring would be expanded with CloudWatch dashboards, alarms, centralized logging, and notifications through services such as SNS.

Terraform state would use a secure remote backend with encryption and state locking. Development, staging, and production would be separated into isolated environments, and preferably separate AWS accounts.

For the frontend, static assets could be served through Amazon S3 and CloudFront rather than running a dedicated frontend container. VPC endpoints could also reduce NAT Gateway traffic and associated costs.

Deployment strategies such as blue/green or canary deployments could be introduced, together with production approval gates and automated rollback.

The result would be a more highly available and scalable architecture, at the cost of increased infrastructure complexity and operational expense.

Use Github Environments in Settings for storing environment variables needed for CI/CD pipeline, instead of Secrets and variables.