Make sure you have credentials set up locally:

```bash
aws configure --profile my-profile
```

To verify the profile works, run `aws sts get-caller-identity --profile my-profile`.

## Permissions Required
The script uses AWS CLI calls under the hood. The IAM principal used by the AWS CLI profile should allow the following actions. If you only run specific sections, you can scope permissions to those services.

### Cost section:
- `ce:GetCostAndUsage`

### IAM section:
- `sts:GetCallerIdentity`
- `iam:GetAccountSummary`
- `iam:ListUsers`
- `iam:ListRoles`
- `iam:GetLoginProfile`
- `iam:ListMFADevices`
- `iam:ListAccessKeys`
- `iam:GetAccessKeyLastUsed`
- `iam:ListAttachedRolePolicies`
- `iam:GetPolicy`
- `iam:GetPolicyVersion`
- `cloudtrail:DescribeTrails`
- `guardduty:ListDetectors`
- `securityhub:GetEnabledStandards`

## Network section:
- `ec2:DescribeVpcs`
- `ec2:DescribeSubnets`
- `ec2:DescribeRouteTables`
- `ec2:DescribeNatGateways`
- `ec2:DescribeSecurityGroups`
- `resourcegroupstaggingapi:GetResources`
- `wafv2:GetWebACLForResource`
- `wafv2:GetWebACL`
- `wafv2:GetIPSet`
