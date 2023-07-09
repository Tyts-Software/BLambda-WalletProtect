# Blazor + AWS Lambda = BLambda

Modular, serverless aproach to build Progressive Web Applications (PWA) and not only, presented by WebAssembly hosted Blazor and served by AWS.

## Tools

Install or update the [latest tooling](https://github.com/aws/aws-extensions-for-dotnet-cli), this lets you deploy and run Lambda functions.

`dotnet tool install -g Amazon.Lambda.Tools`
`dotnet tool update -g Amazon.Lambda.Tools`

Install or update the latest [Lambda function templates](https://github.com/aws/aws-lambda-dotnet/).

`dotnet new --install Amazon.Lambda.Templates

### [CDK](https://docs.aws.amazon.com/cdk/v2/guide/cli.html)

`cdk --version`


CLI is not compatible with the CDK library

`npm uninstall -g aws-cdk && npm install -g aws-cdk`

#### Bootstrap
Deploys the CDK Toolkit staging stack
`cdk bootstrap 1111111111/eu-central-1` 



- [Blazor component library for FluentUI](https://github.com/microsoft/fast-blazor)
- [NSwag](https://github.com/RicoSuter/NSwag)
- [Bundler & Minifier](https://marketplace.visualstudio.com/items?itemName=MadsKristensen.ExtensibilityTools)


**IMPORTANT NOTE:** *Playing around with this POCs your AWS account will create and consume AWS resources, which **will cost money**. Be sure to shut down/remove all resources once you are finished to avoid ongoing charges to your AWS account (see instructions in delete-stack.ps1).*
