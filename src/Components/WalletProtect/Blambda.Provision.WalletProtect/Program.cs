using Amazon.CDK;
using System;

namespace BLambda.Provision;

public sealed class ComponentStackProps : StackProps
{
    public string ComponentName { get; set; }
    public string Domain { get; set; }
    public string SubDomain { get; set; }
    public string LogLevel { get; set; }
}


sealed class Program
{
    public static void Main(string[] args)
    {
        var app = new App();
        var componentName = ((string)app.Node.TryGetContext("component") ?? "WalletProtect").ToLower();
        var domain = ((string)app.Node.TryGetContext("domain") ?? "").ToLower();
        var componentStackName = $"{componentName}{domain}Stack";

        var account = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_ACCOUNT");
        //?? throw new ArgumentNullException("CDK_DEFAULT_ACCOUNT");

        var region = System.Environment.GetEnvironmentVariable("CDK_DEFAULT_REGION");
        //?? throw new ArgumentNullException("CDK_DEFAULT_REGION");

        Console.WriteLine($"account: {account}");
        Console.WriteLine($"region: {region}");
        Console.WriteLine($"component: {componentName}");
        Console.WriteLine($"domain: {domain}");
        Console.WriteLine($"stack: {componentStackName}");

        new ComponentStack(app, componentStackName, new ComponentStackProps
        {
            ComponentName = componentName,
            Domain = domain,


            // For more information, see https://docs.aws.amazon.com/cdk/latest/guide/environments.html
            Env = new Amazon.CDK.Environment
            {
                Account = account,
                Region = region
            }
        });

        Tags.Of(app).Add("APP", componentName);

        if (!string.IsNullOrEmpty(domain))
        {
            Tags.Of(app).Add("APP-DOMAIN", $"{componentName}-{domain}");
        }

        app.Synth();
    }
}
