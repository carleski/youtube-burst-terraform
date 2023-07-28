resource "random_pet" "s3_bucket" {
  prefix = "ytb"
  length = 3
}

resource "aws_s3_bucket" "swarm_storage_bucket" {
  bucket = random_pet.s3_bucket.id
}

output "s3_bucket_name" {
  value   = aws_s3_bucket.swarm_storage_bucket.bucket
}