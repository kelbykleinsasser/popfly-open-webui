#!/bin/bash

# ==============================================
# Set up Cloud Build Trigger for GitHub Integration
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

echo -e "${GREEN}🔗 Setting up Cloud Build Trigger for GitHub${NC}"
echo "Project: $PROJECT_ID"
echo "Repository: https://github.com/kelbykleinsasser/popfly-open-webui"
echo ""

# Create the Cloud Build trigger
echo -e "${BLUE}⚙️  Creating Cloud Build trigger...${NC}"

gcloud builds triggers create github \
    --name="open-webui-deploy" \
    --repo-name="popfly-open-webui" \
    --repo-owner="kelbykleinsasser" \
    --branch-pattern="main" \
    --build-config="cloudbuild.yaml" \
    --description="Deploy Open WebUI on push to main branch" \
    --project="$PROJECT_ID"

echo ""
echo -e "${GREEN}✅ Cloud Build Trigger created successfully!${NC}"
echo ""
echo -e "${YELLOW}🚀 Next Deployment Options:${NC}"
echo "1. Push to GitHub main branch (triggers automatic deployment)"
echo "2. Manual trigger: gcloud builds triggers run open-webui-deploy --branch=main --project=$PROJECT_ID"
echo ""
echo -e "${BLUE}💡 Benefits:${NC}"
echo "- No more local file uploads"
echo "- Only Git changes are pulled"
echo "- Automatic deployments on push"
echo "- Much faster subsequent builds"