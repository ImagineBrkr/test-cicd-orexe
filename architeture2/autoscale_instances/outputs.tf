output "lb_url" {
  description = "Deployment invoke url"
  value       = "http://${aws_lb.hellolb.dns_name}"
}