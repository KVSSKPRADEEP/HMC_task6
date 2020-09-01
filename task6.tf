provider  "aws" {
   region  = "ap-south-1"
   profile = "default"
}

provider "kubernetes" {
    config_context_cluster = "minikube"
}

resource "kubernetes_persistent_volume_claim" "PVC" {
  metadata {
    name = "pvc"
    labels = {
        app = "wordpress"
    }
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "MyDeployment" {
depends_on = [kubernetes_persistent_volume_claim.PVC]
    metadata {
        name = "wordpress-deployment"
        labels = {
            type = "frontend_deployment"
        }
    }
    spec {
        replicas = 1
        strategy {
            type = "Recreate"
        }
        selector{
            match_labels = {
                type = "cms"
                env = "prod"
            }
        }
        template {
            metadata {
                labels = {
                    type = "cms"
                    env = "prod"
                }
            }
            spec {
                container {
                  image = "wordpress"
                  name = "wordpress"
                  port {
                    container_port = 80
                  }
	    volume_mount {
                              name = "wordpressvolume"
                              mount_path = "/var/www/html"
                           }
                }
	volume {
                       name = "wordpressvolume"
                      persistent_volume_claim {
                         claim_name = kubernetes_persistent_volume_claim.PVC.metadata.0.name
                       }
          
                     }
            }
        }
    }
}


resource "kubernetes_service" "loadbalancer" {
    depends_on = [kubernetes_deployment.MyDeployment]
    metadata {
        name = "wordpress-service"
    }

    spec {
        type = "NodePort"
        selector = {
          type = "cms"
        }
        port {
            port = 80
            target_port = 80
            protocol = "TCP"
        }
    }

}

resource "aws_db_instance" "RDS" {
    allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "RDS"
  username             = "pradeep"
  password             = "pradeeppass"
  skip_final_snapshot = true
  publicly_accessible = true
  port = 3306


}
output "aws_instance_mysql" {
    value = aws_db_instance.RDS.endpoint 
}