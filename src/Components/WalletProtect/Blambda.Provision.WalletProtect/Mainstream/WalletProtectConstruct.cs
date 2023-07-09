using Amazon.CDK;
using Amazon.CDK.AWS.Budgets;
using Amazon.CDK.AWS.IAM;
using Amazon.CDK.AWS.Lambda;
using Amazon.CDK.AWS.Logs;
using Amazon.CDK.AWS.SNS;
using Amazon.CDK.AWS.SNS.Subscriptions;
using Constructs;
using System;
using System.Collections.Generic;
using static Amazon.CDK.AWS.Budgets.CfnBudget;

namespace BLambda.Provision.Mainstream
{
    internal sealed class WalletProtectConstruct : Construct
    {
        private const double DEF_BUDGER = 1; //USD
        private const double DEF_LOCK_THRESHOLD = 0.01;

        public WalletProtectConstruct(Construct scope, string id, ComponentStackProps props) : base(scope, id)
        {
            var lambdaPackage = @$"{(string)this.Node.TryGetContext("package")}" ?? "BLambda.ProtectWallet.zip";
            var logLevel = props.LogLevel ?? (string)this.Node.TryGetContext("log-level") ?? "Warning";
            
            var emails = this.Node.TryGetContext("emails");
            var budget = double.Parse((string)this.Node.TryGetContext("budget") ?? DEF_BUDGER.ToString());
            var threshold = double.Parse((string)this.Node.TryGetContext("threshold") ?? DEF_LOCK_THRESHOLD.ToString());

            // LOCK Function
            //
            var lockFunction = new Function(this, "LockLambdasFunction", new FunctionProps
            {
                Runtime = Runtime.PROVIDED,
                Code = Code.FromAsset(lambdaPackage),
                Handler = "not_required_for_custom_runtime",
                MemorySize = 128,
                Timeout = Duration.Seconds(20),
                
                Role = null,

                Environment = new Dictionary<string, string>
                {
                    ["AWS_LAMBDA_HANDLER_LOG_LEVEL"] = logLevel,
                    ["ReservedConcurrentExecutions"] = "", //Unlock value 
                }
            });
			
			var log = new LogGroup(this, "LockLambdasFunctionLog", new LogGroupProps
			{
				LogGroupName = $"/aws/lambda/{lockFunction.FunctionName}",
				Retention = RetentionDays.ONE_MONTH
			});

            var allowLockFunctionPolicy = new PolicyStatement()
            {
                Effect = Effect.ALLOW
            };
            allowLockFunctionPolicy.AddActions(
                "lambda:ListFunctions",
                "lambda:PutFunctionConcurrency",
                "lambda:DeleteFunctionConcurrency"
                );
            allowLockFunctionPolicy.AddResources("*");
            lockFunction.AddToRolePolicy(allowLockFunctionPolicy);


            // Budget + SNS
            //
            var snstopic = new Topic(this, "WalletProtectSNSTopic", new TopicProps
            {
                TopicName = "WalletProtectTopic",
                DisplayName = "WalletProtectTopic",
                Fifo = false
            });

            snstopic.AddSubscription(new LambdaSubscription(lockFunction));

            var allowPublishPolicy = new PolicyStatement()
            {
                Effect = Effect.ALLOW
            };
            allowPublishPolicy.AddServicePrincipal("budgets.amazonaws.com");
            allowPublishPolicy.AddActions("SNS:Publish");
            allowPublishPolicy.AddResources(snstopic.TopicArn);
            snstopic.AddToResourcePolicy(allowPublishPolicy);


            // BUDGET
            //
            var notifyTo = new List<SubscriberProperty> 
            {
                new SubscriberProperty {
                    Address = snstopic.TopicArn,
                    SubscriptionType = "SNS"
                }
            };

            if (emails is not null)
            {
                foreach(var email in ((string)emails).Split(' '))
                {
                    notifyTo.Add(new SubscriberProperty
                    {
                        Address = email,
                        SubscriptionType = "EMAIL"
                    });
                }                
            }

            new CfnBudget(this, "MonthlyBudget", new CfnBudgetProps
            {
                Budget = new BudgetDataProperty
                {
                    BudgetName = $"Zero-Waste Budget",
                    TimeUnit = "MONTHLY",
                    TimePeriod = new TimePeriodProperty
                    {
                        Start = null,
                        End = null //"06/15/87 00:00 UTC"
                    },

                    BudgetType = "COST",
                    BudgetLimit = new SpendProperty
                    {
                        Amount = budget,
                        Unit = "USD"
                    },
                    CostTypes = new CostTypesProperty
                    {
                        IncludeTax = true,
                        IncludeSubscription = true,
                        UseBlended = false,
                        IncludeRefund = false,
                        IncludeCredit = false,
                        IncludeUpfront = true,
                        IncludeRecurring = true,
                        IncludeOtherSubscription = true,
                        IncludeDiscount = true,
                        IncludeSupport = true,
                        UseAmortized = false
                    }
                },
                NotificationsWithSubscribers = new[]
                {
                    new NotificationWithSubscribersProperty
                    {
                        Notification = new NotificationProperty {
                            ComparisonOperator = "GREATER_THAN", //EQUAL_TO | GREATER_THAN | LESS_THAN
                            NotificationType = "ACTUAL", //FORECASTED
                            Threshold = threshold,

                            // the properties below are optional
                            ThresholdType = "PERCENTAGE" //ABSOLUTE_VALUE 
                        },
                        Subscribers = notifyTo.ToArray()
                    }
                }
            });

            new CfnOutput(scope, "WalletProtectTopic", new CfnOutputProps
            {
                Value = snstopic.TopicArn
            });
        }
    }
}
