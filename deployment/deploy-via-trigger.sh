#!/bin/bash

# ==============================================
# Deploy Open WebUI via Cloud Build Trigger
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ID=${GCP_PROJECT_ID:-"popfly-open-webui"}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="open-webui"

echo -e "${GREEN}🚀 Deploying Open WebUI via Cloud Build Trigger${NC}"
echo "Project: $PROJECT_ID"
echo ""

# Push latest changes to GitHub
echo -e "${BLUE}📤 Pushing latest changes to GitHub...${NC}"
cd ..
git add .
git status
read -p "Commit message (or press Enter for default): " commit_msg
if [[ -z "$commit_msg" ]]; then
    commit_msg="Deploy update $(date +%Y-%m-%d\ %H:%M)"
fi

git commit -m "$commit_msg

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>" || echo "No changes to commit"

git push
cd deployment

# Trigger the build
echo -e "${BLUE}🔨 Triggering Cloud Build...${NC}"
gcloud builds triggers run open-webui-deploy \
    --branch=main \
    --project="$PROJECT_ID"

echo ""
echo -e "${YELLOW}🔍 Monitor build progress:${NC}"
echo "https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"

# Wait for build to complete and deploy
echo ""
read -p "Press Enter after build completes to deploy to Cloud Run..."

# Deploy to Cloud Run
echo -e "${BLUE}🚀 Deploying to Cloud Run...${NC}"

# Update the Cloud Run YAML with actual project ID
sed "s/YOUR_PROJECT_ID/$PROJECT_ID/g" cloudrun.yaml > cloudrun-deploy.yaml

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