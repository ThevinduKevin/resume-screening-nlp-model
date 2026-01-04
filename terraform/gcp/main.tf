provider "google" {
  project = var.project_id
  region  = var.region
}

# Firewall rule for SSH
resource "google_compute_firewall" "ssh" {
  name    = "ml-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ml-benchmark"]
}

# Firewall rule for ML API
resource "google_compute_firewall" "ml_api" {
  name    = "ml-allow-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ml-benchmark"]
}

resource "google_compute_instance" "ml" {
  name         = "ml-benchmark-gcp"
  machine_type = var.machine_type
  zone         = "${var.region}-a"

  tags = ["ml-benchmark"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  metadata_startup_script = file("${path.module}/startup.sh")
}
