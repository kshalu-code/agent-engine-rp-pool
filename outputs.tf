output "cloud_run_service_name" {
  description = "The name of the pre-warmed Cloud Run service"
  value       = google_cloud_run_v2_service.prewarmed_init_service.name
}

output "cloud_run_service_uri" {
  description = "The URI of the pre-warmed Cloud Run service"
  value       = google_cloud_run_v2_service.prewarmed_init_service.uri
}

output "tenant_project_id" {
  description = "The project ID where the resources were deployed"
  value       = var.tenant_project_id
}
