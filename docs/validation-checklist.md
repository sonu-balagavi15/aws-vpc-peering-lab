# Validation and Evidence Checklist

Only mark a check complete after you have actually performed it.

## Before deployment
- [ ] Confirm the AWS account plan and available credits.
- [ ] Review current AWS pricing for EC2, EBS, public IPv4, and data transfer.
- [ ] Run `terraform fmt -check`.
- [ ] Run `terraform validate`.
- [ ] Review `terraform plan`; confirm EC2 is disabled unless intentionally needed.

## Network resources
- [ ] VPC A CIDR is `10.10.0.0/16`.
- [ ] VPC B CIDR is `10.20.0.0/16`.
- [ ] VPC peering connection is active.
- [ ] VPC A public route table has `0.0.0.0/0` to the Internet Gateway.
- [ ] VPC A route tables have `10.20.0.0/16` to the peering connection.
- [ ] VPC B private route table has `10.10.0.0/16` to the peering connection.

## Optional EC2 tests
- [ ] Bastion is in the public subnet with a public IP.
- [ ] App-A and App-B have no public IP.
- [ ] SSH to bastion is restricted to your public IP `/32`.
- [ ] App hosts accept SSH from the bastion security group only.
- [ ] App-A and App-B can ping each other after routes and ICMP rules are active.
- [ ] Remove an ICMP rule temporarily and confirm the test fails; restore it afterward.

## Evidence and cleanup
- [ ] Capture screenshots of real AWS resources and tests, if deployed.
- [ ] Do not use mock screenshots as proof of AWS deployment.
- [ ] Run `terraform destroy` after collecting evidence.
- [ ] Confirm no project resources remain in the AWS console.
- [ ] Check billing and usage after cleanup.
