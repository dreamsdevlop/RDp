#!/bin/bash
# ==============================================================================
# 🚀 Deploy 24/7 RDP to Google Cloud Platform (Compute Engine)
# ==============================================================================
# This script creates a Google Compute Engine instance that runs the RDP setup.
# This is the recommended way to run "24/7" on Google Cloud (Firebase's parent).
#
# PREREQUISITES:
# 1. Google Cloud SDK (gcloud) installed and authenticated.
# 2. A Google Cloud Project with billing enabled.
# ==============================================================================

# Configuration
INSTANCE_NAME="win11-rdp-24-7"
ZONE="us-central1-a"  # Change if needed
MACHINE_TYPE="n2-standard-4" # Requires 'n2' or similar for Nested Virtualization
IMAGE_FAMILY="ubuntu-2204-lts"
IMAGE_PROJECT="ubuntu-os-cloud"

# Get current project ID
PROJECT_ID=$(gcloud config get-value project)

if [ -z "$PROJECT_ID" ]; then
  echo "❌ No Google Cloud Project selected."
  echo "Run: gcloud config set project [YOUR_PROJECT_ID]"
  exit 1
fi

echo "=== 🚀 Deploying to Google Cloud Project: $PROJECT_ID ==="
echo "    Instance: $INSTANCE_NAME"
echo "    Zone: $ZONE"
echo "    Machine: $MACHINE_TYPE (Nested Virtualization Enabled)"
echo

# Check if instance exists
if gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE > /dev/null 2>&1; then
  echo "⚠️  Instance $INSTANCE_NAME already exists."
  read -p "Do you want to delete it and recreate? (y/N): " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE --quiet
  else
    echo "Aborting."
    exit 1
  fi
fi

echo "=== 🛠️  Creating Instance... ==="
# We use --enable-nested-virtualization to allow KVM inside the VM (Crucial for speed)
gcloud compute instances create $INSTANCE_NAME \
    --project=$PROJECT_ID \
    --zone=$ZONE \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=60GB \
    --boot-disk-type=pd-ssd \
    --enable-nested-virtualization \
    --metadata-from-file startup-script=rdp.sh \
    --tags=http-server,https-server

echo
echo "=== ✅ Instance Created! ==="
echo "The startup script is now running in the background. It takes about 5-10 minutes to install Docker and Windows."
echo
echo "To check the progress and get the Cloudflare URLs:"
echo "👉 Run: gcloud compute instances tail-serial-port-output $INSTANCE_NAME --zone=$ZONE"
echo
echo "Look for the 'trycloudflare.com' links in the output."
