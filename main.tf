

# ---------------------------------------------------------------------------------
# 1. IAM Delegation (Mimics VRP `GrantServiceAccountPayload`)
# Grants the Cloud Run Service Agent permission to generate tokens for the Vertex P4SA
# ---------------------------------------------------------------------------------
resource "google_service_account_iam_member" "cloudrun_p4sa_token_creator" {
  # The Resource: The Vertex AI P4SA belonging to the Tenant Project
  service_account_id = "projects/${var.tenant_project_id}/serviceAccounts/service-${var.tenant_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
  
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
    # It must run under the Vertex P4SA identity, which is why the token creator grant is required above
    service_account = "service-${var.tenant_project_number}@gcp-sa-aiplatform.iam.gserviceaccount.com"
    
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
