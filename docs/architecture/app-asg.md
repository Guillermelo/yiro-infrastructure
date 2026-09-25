The security groups of the alb is edited here, so that the alb module wont depend of the app-asg
app-asg already depends on the ALB

at the moment the egress is allowed 0.0.0.0/0 so the ec2 can write to everyone, but only alb can write to it

in the future maybe i would only allow egress to db cache and alb
