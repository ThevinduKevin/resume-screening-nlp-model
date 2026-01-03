provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_instance" "ml" {
  name         = "ml-benchmark-gcp"
  machine_type = "e2-micro"
  zone         = "asia-south1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}
