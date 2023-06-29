# ISO 20022 Payments Processing

ISO 20022 Payments Processing is an AWS Solution designed to receive, process
and release ISO 20022 payment messages. You can deploy this solution as a proxy
in front of your existing payments infrastructure, on-prem or in the cloud, or
use it as the foundational building block to modernize existing payments
systems.

This solution provides multi-region tunable consistency with decision making
process managed by the API consumer that allows for the acceptance, rejection,
cancellation, and re-drive of data processing workflows with failover across
AWS regions.

![Architecture Diagram](./docs/architecture.png "Event Driven Architecture")

## Getting Started

### Pre-requisites

* an [AWS account](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-creating.html)
* already installed [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html),
[Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git),
[Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and
[Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)
* [AWS access keys](https://docs.aws.amazon.com/accounts/latest/reference/credentials-access-keys-best-practices.html)
used by AWS CLI
* allowed AWS CLI permissions to create
[AWS Identity and Access Management (IAM) roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create.html)
and [AWS CodeBuild project](https://docs.aws.amazon.com/codebuild/latest/userguide/planning.html) (e.g.,
[IAMFullAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/IAMFullAccess.html) and
[AWSCodeBuildAdminAccess](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AWSCodeBuildAdminAccess.html))
* an [Amazon Simple Storage Service (S3) bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)
used by Terraform remote state
* a custom domain (e.g., *example.com*)
* configured
[AWS Certificate Manager public certificate](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
(e.g., nested *example.com* and wildcarded **.example.com*)

> NOTE: If you select the AWS target region something else than *us-east-1*,
please make sure to create public certificates in both your target region
and *us-east-1*. The reason: Amazon Cognito custom domain deploys hosted UI
using Amazon CloudFront distribution under the hood which requires the public
certificate to be pre-configured in *us-east-1* region.

### Validate Pre-requisites

Starting at the ROOT level of this repository, run the following command:

  ```sh
  /bin/bash ./bin/validate.sh -q example.com -r us-east-1 -t rp2-backend-us-east-1
  ```

> NOTE: Make sure to replace *example.com* with your custom domain, *us-east-1*
with your target AWS region and *rp2-backend-us-east-1* with your S3 bucket.

Review output logs for any potential errors and warnings before moving forward
to the next step.

### Create CI/CD Pipeline

Starting at the ROOT level of this repository, run the following command:

  ```sh
  /bin/bash ./bin/cicd.sh -q example.com -r us-east-1 -t rp2-backend-us-east-1
  ```

> NOTE: Make sure to replace *example.com* with your custom domain, *us-east-1*
with your target AWS region and *rp2-backend-us-east-1* with your S3 bucket.

Once the execution is successful, you should be able to login to AWS Management
Console, navigate to AWS CodeBuild service and see the newly created project
named *rp2-cicd-pipeline*.

### Terragrunt Commands

Starting at ROOT level of this repository, run the following three commands:

1/ Execute the terragrunt cli from below to run corresponding `terraform init`
for all components / subdirectories in `iac.src/` directory

  ```sh
  terragrunt run-all init \
    -backend-config="bucket=rp2-backend-us-east-1" \
    -backend-config="region=us-east-1"
  ```

2/ Execute the terragrunt cli from below to run corresponding `terraform plan`
for all components / subdirectories in `iac.src/` directory

  ```sh
  terragrunt run-all plan -var-file default.tfvars
  ```

3/ Execute the terragrunt cli from below to run corresponding `terraform apply`
for all components / subdirectories in `iac.src/` directory

  ```sh
  terragrunt run-all apply -var-file default.tfvars -auto-approve
  ```

### Docker Commands

Starting at ROOT level of this repository, run the following two commands:

1/ Change the current working directory to `bin/`

  ```sh
  cd bin/
  ```

2/ Execute the docker script to create image from Dockerfile and push into
container registry by passing your ECR repository name and AWS region

  ```sh
  /bin/bash docker.sh -q rp2-health -r us-east-1
  ```

### Testing Commands

Starting at ROOT level of this repository, run the following three commands:

1/ Change the current working directory to `bin/`

  ```sh
  cd bin/
  ```

2/ Execute the test script to run an end-to-end payment workflow

  ```sh
  /bin/bash test.sh -q example.com -r us-east-1
  ```

## Security

See [CONTRIBUTING](./CONTRIBUTING.md#security-issue-notifications) for more
information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](./LICENSE)
file.
