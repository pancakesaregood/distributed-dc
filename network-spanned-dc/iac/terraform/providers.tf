provider "aws" {
  alias   = "site_a"
  region  = var.aws_site_a_region
  profile = var.aws_profile
}

provider "aws" {
  alias   = "site_b"
  region  = var.aws_site_b_region
  profile = var.aws_profile
}

provider "google" {
  alias       = "site_c"
  project     = var.gcp_project_id
  region      = var.gcp_site_c_region
  credentials = var.gcp_credentials_json
}

provider "google" {
  alias       = "site_d"
  project     = var.gcp_project_id
  region      = var.gcp_site_d_region
  credentials = var.gcp_credentials_json
}
