data "aws_iam_policy_document" "role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.this.account_id)]
    }

    # condition {
    #   test     = "StringLike"
    #   variable = "iam:PassedToService"

    #   values = [
    #     "application-autoscaling.amazonaws.com",
    #     # "application-autoscaling.amazonaws.com.cn",
    #   ]
    # }
  }
}
