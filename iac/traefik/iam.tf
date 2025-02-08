resource "aws_iam_user" "this" {
  name = var.user
  path = "/"
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

data "aws_iam_policy_document" "this" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ListResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${var.zoneid}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/${var.zoneid}"]

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsNormalizedRecordNames"
      values   = ["_acme-challenge.oscarcorner.com"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "route53:ChangeResourceRecordSetsRecordTypes"
      values   = ["TXT"]
    }
  }
}


resource "aws_iam_user_policy" "this" {
  name   = "${var.user}-policy"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.this.json
}
