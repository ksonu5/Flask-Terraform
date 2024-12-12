# output "ecs_service_url" {
#   description = "The URL of the ECS service"
#   value = length(aws_ecs_service.flask_service.load_balancer) > 0 ? "http://${aws_ecs_service.flask_service.load_balancer[0].dns_name}" : "No Load Balancer Found"
# }
output "ecs_service_url" {
  value = length(aws_ecs_service.flask_service.load_balancer) > 0 ? "http://${join("", [for lb in aws_ecs_service.flask_service.load_balancer : lb.dns_name])[0]}" : "No Load Balancer Found"
}
