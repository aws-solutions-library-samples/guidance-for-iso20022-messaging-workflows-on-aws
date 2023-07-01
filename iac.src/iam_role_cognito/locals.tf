locals {
  external_id = uuidv5("743ac3c0-3bf7-4a5b-9e6c-59360447c757", var.q.name)
  rp2_id = data.terraform_remote_state.s3.outputs.rp2_id
  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSNSFullAccess"
  ]
}
