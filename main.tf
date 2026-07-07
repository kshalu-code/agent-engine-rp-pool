# ---------------------------------------------------------------------------------
# 1. IAM Delegation (Mimics VRP `GrantServiceAccountPayload`)
# Grants the Cloud Run Service Agent permission to generate tokens for the Generic SA
# ---------------------------------------------------------------------------------
resource "google_service_account_iam_member" "cloudrun_p4sa_token_creator" {
  # The Resource: A generic SA in the producer project (kshalu-org-1)
  # Ensure this SA is created in the producer project before running!
  service_account_id = "projects/kshalu-org-1/serviceAccounts/generic-vertex-sa@kshalu-org-1.iam.gserviceaccount.com"
  
  role               = "roles/iam.serviceAccountTokenCreator"
  
  # The Member: The Cloud Run Service Agent for the Tenant Project
  member             = "serviceAccount:service-${var.tenant_project_number}@server-gcp-sa-cloudrun.iam.gserviceaccount.com"
}

# ---------------------------------------------------------------------------------
# 2. Offline Initialization Service (Mimics VRP `CreateCloudRunServicePayload` dry-run)
# Forces Cloud Run to initialize the project backend and validate the IAM setup
# ---------------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "prewarmed_init_service" {
  name     = "agent-engine-cloud-run-dry-run-service"
  location = var.location
  project  = var.tenant_project_id

  template {
    # It must run under the generic SA identity
    service_account = "generic-vertex-sa@kshalu-org-1.iam.gserviceaccount.com"
    
    containers {
      image = "us-docker.pkg.dev/cloudrun/container/hello:latest"
    }
  }

  labels = {
    # Exact label injected by VRP
    "managed-by" = "reasoning-engine" 
  }

  depends_on = [
    # Explicit dependency ensures the token creator role exists before Cloud Run tries to validate the Service Account
    google_service_account_iam_member.cloudrun_p4sa_token_creator
  ]
}
