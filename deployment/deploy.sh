#!/bin/bash

# ==============================================
# Open WebUI GCP Deployment Script
# ==============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
REGION=${GCP_REGION:-"us-central1"}
SERVICE_NAME="open-webui"
IMAGE_NAME="open-webui"

# Validate required environment variables
check_env_vars() {
    echo -e "${BLUE}🔍 Checking required environment variables...${NC}"
    
    required_vars=("GCP_PROJECT_ID" "GOOGLE_CLIENT_ID" "GOOGLE_CLIENT_SECRET" "WEBUI_SECRET_KEY")
    missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required environment variables:${NC}"
        printf '   %s\n' "${missing_vars[@]}"
        echo ""
        echo -e "${YELLOW}💡 Set these variables before running deployment:${NC}"
        echo "   export GCP_PROJECT_ID=your-project-id"
        echo "   export GOOGLE_CLIENT_ID=your-client-id"
        echo "   export GOOGLE_CLIENT_SECRET=your-client-secret"
        echo "   export WEBUI_SECRET_KEY=your-secret-key"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All required environment variables are set${NC}"
}

# Enable required GCP APIs
enable_apis() {
    echo -e "${BLUE}🔧 Enabling required GCP APIs...${NC}"
    
    apis=(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "secretmanager.googleapis.com"
        "sqladmin.googleapis.com"
        "storage.googleapis.com"
    )
    
    for api in "${apis[@]}"; do
        echo "   Enabling $api..."
        gcloud services enable "$api" --project="$PROJECT_ID"
    done
    
    echo -e "${GREEN}✅ APIs enabled${NC}"
}

# Create secrets in Secret Manager
create_secrets() {
    echo -e "${BLUE}🔐 Creating secrets in Secret Manager...${NC}"
    
    # Create secrets
    echo "$WEBUI_SECRET_KEY" | gcloud secrets create webui-secret-key --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
    echo "$WEBUI_SECRET_KEY" | gcloud secrets versions add webui-secret-key --data-file=- --project="$PROJECT_ID"
    
    echo "$GOOGLE_CLIENT_ID" | gcloud secrets create google-client-id --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
    echo "$GOOGLE_CLIENT_ID" | gcloud secrets versions add google-client-id --data-file=- --project="$PROJECT_ID"
    
    echo "$GOOGLE_CLIENT_SECRET" | gcloud secrets create google-client-secret --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
    echo "$GOOGLE_CLIENT_SECRET" | gcloud secrets versions add google-client-secret --data-file=- --project="$PROJECT_ID"
    
    # OpenAI API Key (optional)
    if [[ -n "$OPENAI_API_KEY" ]]; then
        echo "$OPENAI_API_KEY" | gcloud secrets create openai-api-key --data-file=- --project="$PROJECT_ID" 2>/dev/null || \
        echo "$OPENAI_API_KEY" | gcloud secrets versions add openai-api-key --data-file=- --project="$PROJECT_ID"
    fi
    
    echo -e "${GREEN}✅ Secrets created${NC}"
}

# Build and push Docker image
build_and_push() {
    echo -e "${BLUE}🏗️  Building and pushing Docker image...${NC}"
    
    # Build with Cloud Build using custom configuration (from deployment directory)
    gcloud builds submit \
        --config="cloudbuild.yaml" \
        --project="$PROJECT_ID" \
        ../
    
    echo -e "${GREEN}✅ Image built and pushed to gcr.io/$PROJECT_ID/$IMAGE_NAME:latest${NC}"
}

# Deploy to Cloud Run
deploy_cloud_run() {
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
}

# Optional: Set up Cloud SQL
setup_cloud_sql() {
    if [[ "$1" == "--with-cloudsql" ]]; then
        echo -e "${BLUE}🗄️  Setting up Cloud SQL...${NC}"
        
        DB_INSTANCE="open-webui-db"
        DB_NAME="openwebui"
        DB_USER="openwebui"
        DB_PASSWORD=$(openssl rand -base64 32)
        
        # Create Cloud SQL instance
        gcloud sql instances create "$DB_INSTANCE" \
            --database-version="POSTGRES_15" \
            --tier="db-f1-micro" \
            --region="$REGION" \
            --project="$PROJECT_ID"
        
        # Create database and user
        gcloud sql databases create "$DB_NAME" --instance="$DB_INSTANCE" --project="$PROJECT_ID"
        gcloud sql users create "$DB_USER" --instance="$DB_INSTANCE" --password="$DB_PASSWORD" --project="$PROJECT_ID"
        
        # Create database URL secret
        DATABASE_URL="postgresql://$DB_USER:$DB_PASSWORD@/$DB_NAME?host=/cloudsql/$PROJECT_ID:$REGION:$DB_INSTANCE"
        echo "$DATABASE_URL" | gcloud secrets create database-url --data-file=- --project="$PROJECT_ID"
        
        echo -e "${GREEN}✅ Cloud SQL setup complete${NC}"
        echo -e "${YELLOW}💡 Database URL stored in Secret Manager as 'database-url'${NC}"
    fi
}

# Main deployment flow
main() {
    echo -e "${GREEN}🚀 Starting Open WebUI GCP Deployment${NC}"
    echo "=================================="
    
    check_env_vars
    enable_apis
    create_secrets
    setup_cloud_sql "$1"
    build_and_push
    deploy_cloud_run
    
    echo ""
    echo -e "${GREEN}✅ Deployment Complete!${NC}"
    echo -e "${YELLOW}🔧 Next Steps:${NC}"
    echo "1. Update your Google OAuth redirect URIs to include the new service URL"
    echo "2. Create Google Groups (openwebui-admins, openwebui-users) in Google Admin Console"
    echo "3. Add users to appropriate groups for role assignment"
    echo "4. Test the OAuth login flow"
    echo ""
    echo -e "${BLUE}📱 Access your Open WebUI at: $SERVICE_URL${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --with-cloudsql    Set up Cloud SQL PostgreSQL database (optional)"
    echo "  --help            Show this help message"
    echo ""
    echo "Required environment variables:"
    echo "  GCP_PROJECT_ID      Your GCP project ID"
    echo "  GOOGLE_CLIENT_ID    Google OAuth client ID"
    echo "  GOOGLE_CLIENT_SECRET Google OAuth client secret" 
    echo "  WEBUI_SECRET_KEY    Secret key for Open WebUI (generate with: openssl rand -base64 32)"
    echo ""
    echo "Optional environment variables:"
    echo "  OPENAI_API_KEY      OpenAI API key (if using OpenAI models)"
    echo "  GCP_REGION          GCP region (default: us-central1)"
}

# Parse command line arguments
case "$1" in
    --help)
        show_usage
        exit 0
        ;;
    *)
        main "$1"
        ;;
esac