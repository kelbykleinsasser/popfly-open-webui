#!/usr/bin/env python3
"""
Google Groups Setup Helper for Open WebUI
This script helps you set up and test Google Groups integration.
"""

import os
import sys
from pathlib import Path

# Add the backend directory to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

from open_webui.config import (
    ENABLE_OAUTH_GROUP_MANAGEMENT,
    OAUTH_GROUPS_CLAIM,
    OAUTH_ADMIN_ROLES,
    OAUTH_ALLOWED_ROLES,
    GOOGLE_CLIENT_ID
)

def check_configuration():
    """Check if OAuth Group configuration is properly set."""
    print("🔍 Checking Open WebUI OAuth Group Configuration...")
    print(f"   ENABLE_OAUTH_GROUP_MANAGEMENT: {ENABLE_OAUTH_GROUP_MANAGEMENT.value}")
    print(f"   OAUTH_GROUPS_CLAIM: {OAUTH_GROUPS_CLAIM.value}")
    print(f"   OAUTH_ADMIN_ROLES: {OAUTH_ADMIN_ROLES.value}")
    print(f"   OAUTH_ALLOWED_ROLES: {OAUTH_ALLOWED_ROLES.value}")
    print(f"   GOOGLE_CLIENT_ID configured: {'Yes' if GOOGLE_CLIENT_ID.value else 'No'}")
    
    print("\\n📋 Required Google Groups Setup Checklist:")
    print("   □ Enable Admin SDK API in Google Cloud Console")
    print("   □ Add Admin SDK scope to OAuth consent screen")
    print("   □ Set up domain-wide delegation (if using service account)")
    print("   □ Create Google Groups in Google Admin Console:")
    print("     - openwebui-admins (for admin users)")
    print("     - openwebui-users (for regular users)")
    print("     - Any custom groups for your organization")
    
    print("\\n🔧 Next Steps:")
    print("   1. Go to Google Cloud Console > APIs & Credentials")
    print("   2. Enable the Admin SDK API")  
    print("   3. Update OAuth consent screen with required scope:")
    print("      https://www.googleapis.com/auth/admin.directory.group.member.readonly")
    print("   4. Create Google Groups in Google Admin Console")
    print("   5. Restart Open WebUI server")
    print("   6. Test OAuth login - groups should be fetched automatically")

def suggest_group_structure():
    """Suggest a Google Groups structure for Open WebUI."""
    print("\\n🏗️  Suggested Google Groups Structure:")
    print("   openwebui-admins    → Admin role in Open WebUI")
    print("   openwebui-users     → User role in Open WebUI")
    print("   openwebui-readonly  → Read-only access (if needed)")
    print("   openwebui-blocked   → Blocked users (add to OAUTH_BLOCKED_GROUPS)")

if __name__ == "__main__":
    print("=" * 60)
    print("🚀 Open WebUI Google Groups Setup Helper")
    print("=" * 60)
    
    check_configuration()
    suggest_group_structure()
    
    print("\\n" + "=" * 60)
    print("✅ Review the checklist above and configure Google Cloud Console")
    print("📚 Documentation: https://developers.google.com/admin-sdk/directory/")
    print("=" * 60)