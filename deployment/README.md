# Open WebUI GCP Deployment Guide

This directory contains everything needed to deploy your customized Open WebUI instance to Google Cloud Platform with all your OAuth configurations, functions, and customizations preserved.

## 🗂️ Files Overview

- **`docker-compose.production.yml`** - Production Docker Compose configuration
- **`.env.production`** - Production environment variables template
- **`cloudrun.yaml`** - Cloud Run service definition
- **`deploy.sh`** - Automated deployment script
- **`backup-restore.sh`** - Data backup and restore utilities
- **`README.md`** - This deployment guide

## 🚀 Quick Deployment

### Prerequisites

1. **Google Cloud SDK** installed and authenticated
2. **Docker** installed (for local testing)
3. **Google Cloud Project** with billing enabled
4. **Google OAuth credentials** (Client ID & Secret)

### 1. Set Required Environment Variables

```bash
export GCP_PROJECT_ID="your-project-id"
export GOOGLE_CLIENT_ID="your-google-client-id.googleusercontent.com"
export GOOGLE_CLIENT_SECRET="your-google-client-secret"
export WEBUI_SECRET_KEY=$(openssl rand -base64 32)

# Optional
export OPENAI_API_KEY="your-openai-api-key"
export GCP_REGION="us-central1"
```

### 2. Deploy to Cloud Run

```bash
cd deployment
./deploy.sh
```

### 3. Deploy with Cloud SQL (Recommended for Production)

```bash
./deploy.sh --with-cloudsql
```

## 📋 What Gets Deployed

### ✅ Your Customizations Included:
- **Google OAuth integration** with your client credentials
- **Google Groups support** for automatic role assignment
- **Enhanced OAuth utilities** with Admin SDK API integration
- **User permissions configuration** for model/tool access
- **All environment variables** from your development setup
- **Function caching** and model downloads preserved
- **Database with your users and configurations**

### 🏗️ Infrastructure Created:
- **Cloud Run service** with your customized Open WebUI
- **Secret Manager** for secure credential storage
- **Container Registry** image storage
- **Cloud SQL** (optional) for production database
- **Cloud Storage** for backups and persistent data

## 🔧 Configuration Details

### OAuth Configuration
Your deployment includes:
- Google OAuth with Groups support
- Admin SDK API integration for group fetching
- Automatic role mapping (Google Groups → Open WebUI roles)
- Domain restrictions for security

### User Permissions
All OAuth users get access to:
- Workspace models and tools
- Knowledge bases and prompts
- Web search and code interpreter
- Image generation features

### Security Features
- All secrets stored in Google Secret Manager
- HTTPS-only with Cloud Run
- Domain-restricted OAuth
- Secure cookie settings

## 🔄 Data Management

### Backup Your Data
```bash
# Create backup bucket and backup current data
./backup-restore.sh backup

# List available backups
./backup-restore.sh list
```

### Restore Data
```bash
# Restore from backup
./backup-restore.sh restore
```

## 🛠️ Manual Deployment Steps

If you prefer manual deployment:

### 1. Build and Push Image
```bash
cd ../src
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/open-webui:latest
```

### 2. Create Secrets
```bash
echo "your-secret-key" | gcloud secrets create webui-secret-key --data-file=-
echo "your-client-id" | gcloud secrets create google-client-id --data-file=-
echo "your-client-secret" | gcloud secrets create google-client-secret --data-file=-
```

### 3. Deploy to Cloud Run
```bash
# Update cloudrun.yaml with your PROJECT_ID
gcloud run services replace cloudrun.yaml --region=us-central1
```

## 🎯 Post-Deployment Steps

### 1. Update Google OAuth Settings
In Google Cloud Console → APIs & Credentials:
- Add your new Cloud Run URL to **Authorized redirect URIs**:
  ```
  https://your-service-url/oauth/google/callback
  ```

### 2. Create Google Groups
In Google Admin Console:
- Create `openwebui-admins` group
- Create `openwebui-users` group
- Add users to appropriate groups

### 3. Test Authentication
1. Visit your deployed Open WebUI URL
2. Try signing in with Google OAuth
3. Verify group-based role assignment works
4. Check that models and tools are accessible

## 🔍 Troubleshooting

### Common Issues

**OAuth "Access blocked" errors:**
- Verify redirect URIs in Google Cloud Console
- Check domain restrictions in `.env` file
- Ensure Admin SDK API is enabled

**No models available:**
- Check user permissions in environment variables
- Verify Functions are accessible to OAuth users
- Check OpenAI API key if using OpenAI models

**Deployment failures:**
- Verify all required environment variables are set
- Check GCP project permissions and billing
- Review Cloud Build logs for build errors

### Debugging Commands

```bash
# Check service logs
gcloud run services logs read open-webui --region=us-central1

# Describe service configuration
gcloud run services describe open-webui --region=us-central1

# Test service health
curl https://your-service-url/health
```

## 📊 Monitoring and Scaling

### Cloud Run Metrics
- **CPU/Memory usage** - Monitor in Cloud Console
- **Request latency** - Track response times
- **Error rates** - Monitor failed requests
- **Instance count** - Auto-scaling metrics

### Scaling Configuration
In `cloudrun.yaml`:
- `run.googleapis.com/max-scale: "10"` - Maximum instances
- `run.googleapis.com/min-scale: "1"` - Minimum instances  
- `containerConcurrency: 100` - Requests per instance

## 💰 Cost Optimization

### Cloud Run Costs
- **CPU/Memory** - Pay per use
- **Requests** - First 2M requests/month free
- **Min instances** - Set to 0 for cost savings (cold starts)

### Storage Costs
- **Container images** - Regular cleanup recommended
- **Secrets** - Minimal cost
- **Cloud SQL** - Consider db-f1-micro for development

## 🔐 Security Best Practices

### Implemented Security:
- ✅ Secrets in Secret Manager (not environment variables)
- ✅ HTTPS-only communication
- ✅ Domain-restricted OAuth
- ✅ Secure cookie configuration
- ✅ Regular security updates via container rebuilds

### Additional Recommendations:
- Set up **VPC** for network isolation
- Enable **Cloud Armor** for DDoS protection
- Configure **IAM** with least privilege principle
- Set up **audit logging** for compliance

## 📞 Support

For deployment issues:
1. Check the troubleshooting section above
2. Review GCP documentation for specific services
3. Check Open WebUI GitHub issues for application problems

## 🎉 Success!

Once deployed, your Open WebUI instance will have:
- ✅ Google OAuth authentication
- ✅ Google Groups-based access control
- ✅ All your custom functions and configurations
- ✅ Production-ready infrastructure
- ✅ Automatic scaling and high availability

Your users can now access the system using their Google accounts with automatic role assignment based on Google Groups membership!