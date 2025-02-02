resource "aws_iam_user" "backup" {
  name = "backup"
  path = "/"
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.backup.name
}

data "aws_iam_policy_document" "backup-user" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject"

    ]
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_user_policy" "this" {
  name   = "backup-policy"
  user   = aws_iam_user.backup.name
  policy = data.aws_iam_policy_document.backup-user.json
}
