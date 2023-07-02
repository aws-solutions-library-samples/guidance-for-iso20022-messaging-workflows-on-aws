q = {
  name                 = "rp2-mq-writer"
  force_delete         = true
  image_tag_mutability = "MUTABLE"
  encryption_type      = "KMS"
  scan_on_push         = true
}
