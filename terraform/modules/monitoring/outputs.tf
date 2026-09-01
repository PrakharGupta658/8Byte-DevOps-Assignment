output "iam_instance_profile_name" { value = aws_iam_instance_profile.cloudwatch_agent.name }
output "infra_dashboard_url"  { value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.infrastructure.dashboard_name}" }
output "app_dashboard_url"    { value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.application.dashboard_name}" }
