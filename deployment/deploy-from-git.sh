#!/bin/bash

# ==============================================
# Deploy Open WebUI from Git Repository
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"popfly-open-webui"}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="open-webui"
REPO_URL="https://github.com/kelbykleinsasser/popfly-open-webui"

echo -e "${GREEN}🚀 Deploying Open WebUI from Git Repository${NC}"
echo "Repository: $REPO_URL"
echo "Project: $PROJECT_ID"
echo ""

# Clone from Git and build
echo -e "${BLUE}📥 Building from Git repository...${NC}"
gcloud builds submit \
    --config="deployment/cloudbuild.yaml" \
    --project="$PROJECT_ID" \
    "$REPO_URL"

# Deploy to Cloud Run
echo -e "${BLUE}🚀 Deploying to Cloud Run...${NC}"

# Update the Cloud Run YAML with actual project ID
sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" deployment/cloudrun.yaml > cloudrun-deploy.yaml

# Deploy using gcloud
gcloud run services replace cloudrun-deploy.yaml \
    --region="$REGION" \
    --project="$PROJECT_ID"

# Make service publicly accessible
gcloud run services add-iam-policy-binding "$SERVICE_NAME" \
    --member="allUsers" \
    --role="roles/run.invoker" \
    --region="$REGION" \
    --project="$PROJECT_ID"

# Get the service URL
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --format="value(status.url)")

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${GREEN}🌐 Service URL: $SERVICE_URL${NC}"

# Clean up temporary file
rm -f cloudrun-deploy.yaml

echo ""
echo -e "${YELLOW}🔧 Next Steps:${NC}"
echo "1. Update your Google OAuth redirect URIs to include: $SERVICE_URL/oauth/google/callback"
echo "2. Create Google Groups (openwebui-admins, openwebui-users) in Google Admin Console"
echo "3. Add users to appropriate groups for role assignment"
echo "4. Test the OAuth login flow"