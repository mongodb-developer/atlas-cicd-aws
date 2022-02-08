output "ssm_paramter_api_public_key_arn" {
  value       = aws_ssm_parameter.api_public_key.arn
}
output "ssm_paramter_api_private_key_arn" {
  value       = aws_ssm_parameter.api_private_key.arn
}
output "ssm_paramter_project_id_arn" {
  value       = aws_ssm_parameter.project_id.arn
}