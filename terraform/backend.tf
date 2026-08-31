# Remote state in S3. Backend blocks can't use variables, so fill in your
# own bucket name/region below (or pass them with `terraform init -backend-config=...`).
#
# One-time setup before `terraform init` (bucket must already exist):
#   aws s3api create-bucket --bucket YOUR-STATE-BUCKET-NAME --region ap-south-1 \
#     --create-bucket-configuration LocationConstraint=ap-south-1
#   aws s3api put-bucket-versioning --bucket YOUR-STATE-BUCKET-NAME \
#     --versioning-configuration Status=Enabled
#   aws s3api put-bucket-encryption --bucket YOUR-STATE-BUCKET-NAME \
#     --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
#
# use_lockfile = true enables S3's native state locking (Terraform 1.10+),
# so a separate DynamoDB table is not needed.
terraform {
  backend "s3" {
    bucket       = "s3-bucket-for-terraform-desk-analytics-state"
    key          = "desk-analytics/terraform.tfstate"
    region       = "eu-north-1"
    encrypt      = true
    use_lockfile = true
  }
}
