# SSM Document

resource "aws_s3_bucket_object" "file_upload_setup" {
  bucket        = var.s3_bucket_name
  key           = "prepare_host_ts.sh"
  source        = "../ts_cluster_ssm/scripts/prepare_host_ts.sh"
}

resource "aws_ssm_document" "ssm_doc_for_tssetup" {
  depends_on    = [aws_s3_bucket_object.file_upload_setup]
  name            = "${var.ssm_document_name}-setup"
  document_type   = "Command"
  document_format = "JSON"
  tags            = merge({ "Name" = "${var.ssm_document_name}-setup" }, var.tags)

  content         = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Prepare node for TS",
  "parameters": {},
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "default",
      "inputs": {
        "runCommand": [
            "mkdir -p /tmp/setup",
            "cd /tmp/setup",
            "aws s3 cp s3://${var.s3_bucket_name}/prepare_host_ts.sh ./prepare_host_ts.sh",
            "chmod +x ./prepare_host_ts.sh",
            "./prepare_host_ts.sh >> /tmp/setup/ssm_doc_setup_log 2>&1"
        ]
      }
    }
  ]
}
DOC
}


# SSM Document association
resource "aws_ssm_association" "default_setup" {
  name    = aws_ssm_document.ssm_doc_for_tssetup.name

  targets {
    key    = "InstanceIds"
    values = aws_instance.ts_cluster_instance.*.id
  }

  output_location {
    s3_bucket_name = var.s3_bucket_name
  }
}


resource "aws_s3_bucket_object" "file_upload_install" {
  bucket        = var.s3_bucket_name
  key           = "install_ts.sh"
  source        = "../ts_cluster_ssm/scripts/install_ts.sh"
}

resource "aws_ssm_document" "ssm_doc_for_tsinstall" {
  depends_on    = [aws_s3_bucket_object.file_upload_install]
  name            = "${var.ssm_document_name}-install"
  document_type   = "Command"
  document_format = "JSON"
  tags            = merge({ "Name" = "${var.ssm_document_name}-install" }, var.tags)

  content         = <<DOC
{
  "schemaVersion": "2.2",
  "description": "Installing TS Cluster",
  "parameters": {},
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "default",
      "inputs": {
        "runCommand": [
            "mkdir -p /tmp/install",
            "cd /tmp/install",
            "aws s3 cp s3://${var.s3_bucket_name}/install_ts.sh ./install_ts.sh",
            "chmod +x ./install_ts.sh",
            "./install_ts.sh >> /tmp/install/ssm_doc_install_log 2>&1"
        ]
      }
    }
  ]
}
DOC
}


# SSM Document association
resource "aws_ssm_association" "default_install" {
  name    = aws_ssm_document.ssm_doc_for_tsinstall.name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.ts_cluster_instance[0].id]
  }

  output_location {
    s3_bucket_name = var.s3_bucket_name
  }
}



output "ts_setup_document_status" {
  value       = aws_ssm_document.ssm_doc_for_tssetup.status
  description = "The current status of the document."
}

output "ts_setup_document_name" {
  value       = aws_ssm_document.ssm_doc_for_tssetup.name
  description = "The name of the document."
}
output "ts_install_document_status" {
  value       = aws_ssm_document.ssm_doc_for_tsinstall.status
  description = "The current status of the document."
}

output "ts_install_document_name" {
  value       = aws_ssm_document.ssm_doc_for_tsinstall.name
  description = "The name of the document."
}
