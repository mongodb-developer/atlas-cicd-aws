
output "codecommit_cloneurl_http" {
  value     = aws_codecommit_repository.base-repo.clone_url_http
}
output "codecommit_cloneurl_ssh" {
  value     = aws_codecommit_repository.base-repo.clone_url_ssh
}