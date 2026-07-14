# # Target group

# resource "yandex_alb_target_group" "target-group" {
#   name = "my-target-group"

#   target {
#     subnet_id  = yandex_vpc_subnet.project_a.id
#     ip_address = yandex_compute_instance.web_1.network_interface.0.ip_address
#   }

#   target {
#     subnet_id  = yandex_vpc_subnet.project_b.id
#     ip_address = yandex_compute_instance.web_2.network_interface.0.ip_address
#   }
# }


# # Backend group

# resource "yandex_alb_backend_group" "alb_bg" {
#   name = "my-backend-group"

  
#   http_backend {
#     name             = "http-backend"
#     weight           = 1
#     port             = 80
#     target_group_ids = ["${yandex_alb_target_group.target-group.id}"]
#     healthcheck {
#       timeout  = "1s"
#       interval = "1s"
#       http_healthcheck {
#         path = "/"
#       }
#     }
#   }
# }

# # HTTP router

# resource "yandex_alb_http_router" "tf-router" {
#   name = "my-http-router"
# }

# resource "yandex_alb_virtual_host" "my-vhost" {
#   name           = "my-virtual-host"
#   http_router_id = yandex_alb_http_router.tf-router.id
#   route {
#     name = "my-route"
#     http_route {
#       http_route_action {
#         backend_group_id = yandex_alb_backend_group.alb_bg.id
#         timeout          = "3s"
#       }
#     }
#   }
# }


# #  Application load balancer

# resource "yandex_alb_load_balancer" "my_alb" {
#   name = "my-load-balancer"

#   network_id = yandex_vpc_network.project_net.id

#   allocation_policy {
#     location {
#       zone_id   = "ru-central1-a"
#       subnet_id = yandex_vpc_subnet.project_a.id
#     }
#   }

#   listener {
#     name = "my-listener"
#     endpoint {
#       address {
#         external_ipv4_address {
#         }
#       }
#       ports = [80]
#     }
#     http {
#       handler {
#         http_router_id = yandex_alb_http_router.tf-router.id
#       }
#     }
#   }
# }