# Certification Backend - Terraform Infrastructure

This directory contains the Terraform configuration for deploying the NestJS Certification Backend API to AWS ECS as an **internal service**.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        VPC                                  │
│                                                             │
│  ┌──────────────┐     ┌──────────────┐     ┌─────────────┐ │
│  │     ALB      │────▶│ Certification│────▶│   Cert      │ │
│  │   (Public)   │     │   Webapp     │     │  Backend    │ │
│  └──────────────┘     │  (Frontend)  │     │   (API)     │ │
│                       └──────────────┘     └──────┬──────┘ │
│                              │                     │        │
│                              │      Service        │        │
│                              │     Discovery       │        │
│                              │  (cert-backend.local)        │
│                              │                     │        │
│                              │                     ▼        │
│                              │              ┌─────────────┐ │
│                              └─────────────▶│     RDS     │ │
│                                             │ (PostgreSQL)│ │
│                                             └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

- **ECS Fargate** - Serverless container orchestration (internal, no public access)
- **Service Discovery** - Internal DNS via AWS Cloud Map (`api.cert-backend.local`)
- **RDS PostgreSQL** - Managed relational database
- **ECR** - Container registry for Docker images
- **CloudWatch Logs** - Centralized logging
- **SSM Parameter Store** - Secure secrets management

## Key Points

- ❌ **No ALB** - This is an internal service, not exposed to the internet
- ❌ **No public DNS** - Uses internal service discovery only
- ✅ **Service Discovery** - Frontend connects via `http://api.cert-backend.local:3000`

## Prerequisites

1. **Shared Infrastructure**: Make sure `terraform-shared` is deployed first
2. **Certification Webapp**: Make sure `certification_terraform` is deployed first
3. **AWS CLI**: Configured with the `AdministratorAccess-975232045453` profile
4. **Terraform**: Version >= 1.0

## Deployment Steps

### 1. Create SSM Parameters (Secrets)

```bash
chmod +x create_ssm_params.sh
./create_ssm_params.sh 'YOUR_DB_PASSWORD' 'YOUR_JWT_SECRET'
```

### 2. Configure Terraform Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (especially rds_password)
```

### 3. Initialize and Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Push Initial Docker Image

```bash
# Get ECR login
aws ecr get-login-password --region us-west-1 --profile AdministratorAccess-975232045453 | \
  docker login --username AWS --password-stdin 975232045453.dkr.ecr.us-west-1.amazonaws.com

# Build and push (from the certification_backend directory)
cd /path/to/certification_backend
docker build -t 975232045453.dkr.ecr.us-west-1.amazonaws.com/cert-backend-api:latest .
docker push 975232045453.dkr.ecr.us-west-1.amazonaws.com/cert-backend-api:latest
```

### 5. Update Certification Webapp

Update the frontend's environment to connect to the backend:

```bash
# In certification_terraform/main.tf, add or update:
CERT_BACKEND_URL = "http://api.cert-backend.local:3000"
```

## Outputs

After deployment:

- **Internal API URL**: `http://api.cert-backend.local:3000`
- **RDS Endpoint**: Available in Terraform outputs
- **ECR Repository**: `975232045453.dkr.ecr.us-west-1.amazonaws.com/cert-backend-api`

## Connecting from Frontend

The `certification.webapp` can now call the backend using:

```typescript
const BACKEND_URL = process.env.CERT_BACKEND_URL || 'http://api.cert-backend.local:3000';

// Example API call
const response = await fetch(`${BACKEND_URL}/api/some-endpoint`);
```

## Troubleshooting

### ECS Task Not Starting

1. Check CloudWatch Logs: `/ecs/cert-backend-api`
2. Verify SSM parameters exist
3. Check security group rules

### Service Discovery Not Resolving

1. Ensure both services are in the same VPC
2. Check the namespace: `cert-backend.local`
3. Verify the service name: `api`

### Database Connection Issues

1. Verify RDS security group allows traffic from API security group
2. Check DB credentials in SSM
3. Ensure `DB_SSL=true`
