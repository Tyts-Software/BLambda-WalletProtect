using Amazon.CDK;
using BLambda.Provision.Mainstream;
using Constructs;

namespace BLambda.Provision;

public class ComponentStack : Stack
{
    internal ComponentStack(Construct scope, string id, ComponentStackProps props = null) : base(scope, id, props)
    {
        var _ = new WalletProtectConstruct(this, nameof(WalletProtectConstruct), props);
    }
}
