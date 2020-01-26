provider "aws" {
  profile = "default"
  region = "us-east-1"
}

resource "aws_s3_bucket" "my-portfolio-bucket" {
  bucket = "my-portfolio-bucket-uni"
  acl    = "private"
}


resource "aws_iam_role" "my-portfolio-role" {
    name                  = "my-portfolio-role"
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "codepipeline.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
}

resource "aws_iam_role" "my-portfolio-build-role" {
    name                  = "my-portfolio-build-role"
    assume_role_policy    = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "codebuild.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
}

resource "aws_iam_role" "my-portfolio-function-role" {
    name                  = "my-portfolio-function-role"
    assume_role_policy    = jsonencode(
            {
                Statement = [
                    {
                        Action    = "sts:AssumeRole"
                        Effect    = "Allow"
                        Principal = {
                            Service = "lambda.amazonaws.com"
                        }
                    }
                ],
                Version   = "2012-10-17"
            }
    )
}

resource "aws_iam_role_policy" "my-portfolio-function-policy" {
  role = aws_iam_role.my-portfolio-function-role.name
  name = "my-portfolio-function-policy"
  policy = jsonencode(
    {
    "Statement": [
        {
            "Action": [
                "codepipeline:AcknowledgeJob",
                "codepipeline:GetJobDetails",
                "codepipeline:PollForJobs",
                "codepipeline:PutJobFailureResult",
                "codepipeline:PutJobSuccessResult"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::*"
        },
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": "arn:aws:sns:us-east-1:315089025365:deployPortfolioTopic"
        }
    ],
    "Version": "2012-10-17"
    }
  )
}


resource "aws_iam_role_policy" "my-portfolio-policy" {
  role = aws_iam_role.my-portfolio-role.name
  name = "my-portfolio-policy"
  policy = jsonencode(
    {
    "Version": "2012-10-17",
    "Statement": [
        {
      "Effect": "Allow",
      "Resource": [
          aws_s3_bucket.my-portfolio-bucket.arn,
          "${aws_s3_bucket.my-portfolio-bucket.arn}/*"
            ],
      "Action": [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObject"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ]

    },
    {
      "Sid": "Invoke",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
            ],
      "Resource": [
        "*"
        ]
    }
    ]
}
)
}

resource "aws_iam_role_policy" "my-portfolio-build-policy" {
  role = aws_iam_role.my-portfolio-build-role.name
  name = "my-portfolio-build-policy"

  policy = jsonencode(
  {
"Version": "2012-10-17",
"Statement": [
  {
    "Sid": "CloudWatchLogsPolicy",
    "Effect": "Allow",
    "Action": [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "CodeCommitPolicy",
    "Effect": "Allow",
    "Action": [
      "codecommit:GitPull"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "S3GetObjectPolicy",
    "Effect": "Allow",
    "Action": [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "S3PutObjectPolicy",
    "Effect": "Allow",
    "Action": [
      "s3:PutObject"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "ECRPullPolicy",
    "Effect": "Allow",
    "Action": [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "ECRAuthPolicy",
    "Effect": "Allow",
    "Action": [
      "ecr:GetAuthorizationToken"
    ],
    "Resource": [
      "*"
    ]
  },
  {
    "Sid": "S3BucketIdentity",
    "Effect": "Allow",
    "Action": [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation"
    ],
    "Resource": [
      "*"
      ]
  },
  {
    "Sid": "Invoke",
    "Effect": "Allow",
    "Action": [
      "lambda:InvokeFunction"
          ],
    "Resource": [
      "*"
      ]
  }
]
}
)
}

resource "aws_codepipeline" "my-portfolio-pipeline" {
  name     = "my-portfolio-pipeline"
  role_arn = aws_iam_role.my-portfolio-role.arn

  artifact_store {
    location = aws_s3_bucket.my-portfolio-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        Owner  = "ayuspin"
        Repo   = "my-portfolio"
        Branch = "master"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.my-portfolio-build.name
      }
    }
  }

    stage {
      name = "Deploy"
      action {
          name             = "Deploy"
          category         = "Invoke"
          configuration    = {
              "FunctionName" = "my-portfolio-function"
          }
          input_artifacts  = ["build_output"]
          output_artifacts = []
          owner            = "AWS"
          provider         = "Lambda"
          run_order        = 1
          version          = "1"
      }
  }
}

resource "aws_codebuild_project" "my-portfolio-build" {
  name          = "my-portfolio-build"
  service_role  = aws_iam_role.my-portfolio-build-role.arn
  source {
                  type                   = "CODEPIPELINE"
          }
  artifacts {
                  type                   = "CODEPIPELINE"
            }
  environment {
      compute_type                = "BUILD_GENERAL1_SMALL"
      image                       = "aws/codebuild/standard:1.0"
      image_pull_credentials_type = "CODEBUILD"
      privileged_mode             = false
      type                        = "LINUX_CONTAINER"
  }
}

resource "aws_lambda_function" "my-portfolio-function" {
    function_name                  = "my-portfolio-function"
    handler                        = "upload-portfolio-lambda.lambda_handler"
    filename                       = "lambda_function_payload.zip"
    role                           = "aws_iam_role.my-portfolio-function-role.arn"
    runtime                        = "python3.8"
    timeout                        = 30
}
