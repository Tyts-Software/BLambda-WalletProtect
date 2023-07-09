using Amazon.Lambda;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Amazon.Lambda.SNSEvents;
using System.Text.Json.Serialization;

namespace BLambda.Functions.LockLambdas;

public class Function
{
    private static async Task Main()
    {
        Func<SNSEvent, ILambdaContext, Task> handler = FunctionHandler;
        await LambdaBootstrapBuilder.Create(handler, new SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>())
            .Build()
            .RunAsync();
    }

    public static async Task FunctionHandler(SNSEvent evnt, ILambdaContext context)
    {
        foreach (var record in evnt.Records)
        {
            await ProcessRecordAsync(record, context);
        }
    }

    private static async Task ProcessRecordAsync(SNSEvent.SNSRecord record, ILambdaContext context)
    {
        var lockWallet = record.Sns.Message != "UNLOCK";
        context.Logger.LogWarning($"[WalletProtect]: {record.Sns.Message}");

        IAmazonLambda client = new AmazonLambdaClient();
        var functions = await client.ListFunctionsAsync();

        if (functions != null)
        {
            foreach (var function in functions.Functions)
            {
                if (function.FunctionName != context.FunctionName)
                {
                    if (lockWallet) // restore Concurrency - Unlock
                    {
                        await client.PutFunctionConcurrencyAsync(new()
                        {
                            FunctionName = function.FunctionName,
                            ReservedConcurrentExecutions = 0
                        });
                    }
                    else
                    {
                        if (function.Environment.Variables.TryGetValue("ReservedConcurrentExecutions", out var reservedString)
                            && int.TryParse(reservedString, out var reserved))
                        {
                            await client.PutFunctionConcurrencyAsync(new()
                            {
                                FunctionName = function.FunctionName,
                                ReservedConcurrentExecutions = reserved
                            });
                        }
                        else
                        {
                            await client.DeleteFunctionConcurrencyAsync(new()
                            {
                                FunctionName = function.FunctionName
                            });
                        }
                    }

                    context.Logger.LogInformation($"[WalletProtect]: {(lockWallet ? "lock" : "unlock")} '{function.FunctionName}'");
                }
            }
        }
    }
}

[JsonSerializable(typeof(SNSEvent))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
    // By using this partial class derived from JsonSerializerContext, we can generate reflection free JSON Serializer code at compile time
    // which can deserialize our class and properties. However, we must attribute this class to tell it what types to generate serialization code for.
    // See https://docs.microsoft.com/en-us/dotnet/standard/serialization/system-text-json-source-generation
}