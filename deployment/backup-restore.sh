#!/bin/bash

# ==============================================
# Open WebUI Data Backup and Restore Script
# ==============================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ID=${GCP_PROJECT_ID:-"your-project-id"}
BUCKET_NAME="${PROJECT_ID}-open-webui-backups"
SERVICE_NAME="open-webui"
REGION=${GCP_REGION:-"us-central1"}

# Create backup bucket
create_backup_bucket() {
    echo -e "${BLUE}🪣 Creating backup bucket...${NC}"
    
    gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://$BUCKET_NAME" 2>/dev/null || \
    echo -e "${YELLOW}⚠️  Bucket already exists or creation failed${NC}"
    
    # Set lifecycle policy to automatically delete old backups
    cat > lifecycle.json << EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 30}
    }
  ]
}
EOF
    
    gsutil lifecycle set lifecycle.json "gs://$BUCKET_NAME"
    rm lifecycle.json
    
    echo -e "${GREEN}✅ Backup bucket ready: gs://$BUCKET_NAME${NC}"
}

# Backup current data
backup_data() {
    echo -e "${BLUE}💾 Creating backup...${NC}"
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_NAME="open-webui-backup-$TIMESTAMP"
    
    # Get current data from running Cloud Run instance
    # This assumes you have a backup endpoint or can exec into the container
    
    echo -e "${YELLOW}📋 Backup methods available:${NC}"
    echo "1. Manual: Download data from Cloud Run volume"
    echo "2. Database: Export database if using Cloud SQL"
    echo "3. Full: Complete system backup"
    
    read -p "Choose backup method (1-3): " choice
    
    case $choice in
        1)
            backup_manual "$BACKUP_NAME"
            ;;
        2)
            backup_database "$BACKUP_NAME"
            ;;
        3)
            backup_full "$BACKUP_NAME"
            ;;
        *)
            echo -e "${RED}❌ Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# Manual backup method
backup_manual() {
    local backup_name="$1"
    echo -e "${BLUE}📂 Creating manual backup: $backup_name${NC}"
    
    # Create temp directory
    mkdir -p "/tmp/$backup_name"
    
    # Copy local development data for reference
    if [[ -d "../src/backend/data" ]]; then
        cp -r "../src/backend/data" "/tmp/$backup_name/"
        
        # Create metadata
        cat > "/tmp/$backup_name/backup_info.json" << EOF
{
  "backup_name": "$backup_name",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "type": "manual",
  "source": "local_development",
  "project_id": "$PROJECT_ID"
}
EOF
        
        # Create archive and upload
        cd "/tmp"
        tar -czf "$backup_name.tar.gz" "$backup_name"
        gsutil cp "$backup_name.tar.gz" "gs://$BUCKET_NAME/"
        
        # Cleanup
        rm -rf "/tmp/$backup_name" "/tmp/$backup_name.tar.gz"
        
        echo -e "${GREEN}✅ Manual backup uploaded to gs://$BUCKET_NAME/$backup_name.tar.gz${NC}"
    else
        echo -e "${RED}❌ No local data directory found${NC}"
    fi
}

# Database backup method
backup_database() {
    local backup_name="$1"
    echo -e "${BLUE}🗄️  Creating database backup: $backup_name${NC}"
    
    # Get Cloud SQL instance name (you may need to adjust this)
    DB_INSTANCE="open-webui-db"
    
    # Export database
    gcloud sql export sql "$DB_INSTANCE" "gs://$BUCKET_NAME/$backup_name-database.sql" \
        --project="$PROJECT_ID" \
        --database="openwebui"
    
    echo -e "${GREEN}✅ Database backup created: gs://$BUCKET_NAME/$backup_name-database.sql${NC}"
}

# Full backup method
backup_full() {
    local backup_name="$1"
    echo -e "${BLUE}🎯 Creating full backup: $backup_name${NC}"
    
    backup_manual "$backup_name"
    backup_database "$backup_name"
    
    echo -e "${GREEN}✅ Full backup complete${NC}"
}

# List available backups
list_backups() {
    echo -e "${BLUE}📋 Available backups:${NC}"
    gsutil ls "gs://$BUCKET_NAME/" | grep -E "\\.(tar\\.gz|sql)$" | sort -r
}

# Restore from backup
restore_data() {
    echo -e "${BLUE}🔄 Starting restore process...${NC}"
    
    list_backups
    echo ""
    read -p "Enter backup filename to restore (or 'latest' for most recent): " backup_file
    
    if [[ "$backup_file" == "latest" ]]; then
        backup_file=$(gsutil ls "gs://$BUCKET_NAME/" | grep "\\.tar\\.gz$" | sort -r | head -n1 | xargs basename)
        echo -e "${YELLOW}📁 Selected latest backup: $backup_file${NC}"
    fi
    
    if [[ -z "$backup_file" ]]; then
        echo -e "${RED}❌ No backup file specified${NC}"
        exit 1
    fi
    
    # Download and extract backup
    gsutil cp "gs://$BUCKET_NAME/$backup_file" "/tmp/"
    cd "/tmp"
    tar -xzf "$backup_file"
    
    backup_dir=$(basename "$backup_file" .tar.gz)
    
    echo -e "${YELLOW}⚠️  This will replace current data. Continue? (y/N)${NC}"
    read -p "" confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}🚫 Restore cancelled${NC}"
        rm -rf "/tmp/$backup_file" "/tmp/$backup_dir"
        exit 0
    fi
    
    # Here you would implement the actual restore logic
    # This depends on your deployment method and data storage
    
    echo -e "${GREEN}✅ Restore process would be implemented here${NC}"
    echo -e "${YELLOW}💡 For production restore, you may need to:${NC}"
    echo "1. Scale down the Cloud Run service"
    echo "2. Restore database from SQL backup"
    echo "3. Update persistent volumes with file data"
    echo "4. Scale service back up"
    
    # Cleanup
    rm -rf "/tmp/$backup_file" "/tmp/$backup_dir"
}

# Show usage
show_usage() {
    echo "Usage: $0 COMMAND"
    echo ""
    echo "Commands:"
    echo "  create-bucket    Create backup bucket"
    echo "  backup          Create backup"
    echo "  list            List available backups"
    echo "  restore         Restore from backup"
    echo "  help            Show this help"
    echo ""
    echo "Environment variables:"
    echo "  GCP_PROJECT_ID  Your GCP project ID"
    echo "  GCP_REGION      GCP region (default: us-central1)"
}

# Main script
case "$1" in
    create-bucket)
        create_backup_bucket
        ;;
    backup)
        create_backup_bucket
        backup_data
        ;;
    list)
        list_backups
        ;;
    restore)
        restore_data
        ;;
    help|--help)
        show_usage
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac