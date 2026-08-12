from __future__ import annotations

import os
import urllib.error
import urllib.request

import pytest
from botocore.exceptions import ClientError

PROJECT = os.environ.get("PROJECT_NAME", "poc-cloud-foundation-lab")
HEALTH_TIMEOUT_SEC = int(os.environ.get("HEALTH_TIMEOUT_SEC", "90"))


@pytest.mark.aws
def test_vpc_tagged_aws(aws_session) -> None:
    vpcs = aws_session.client("ec2").describe_vpcs(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["aws"]},
        ]
    )["Vpcs"]
    assert vpcs, f"no hay VPC con Project={PROJECT} Environment=aws (¿corriste 02_apply?)"


@pytest.mark.aws
def test_rds_not_public(aws_session) -> None:
    db_id = f"{PROJECT}-pg"
    try:
        db = aws_session.client("rds").describe_db_instances(DBInstanceIdentifier=db_id)["DBInstances"][0]
    except ClientError as exc:
        pytest.fail(f"RDS {db_id}: {exc}")
    assert db["PubliclyAccessible"] is False, "RDS no debe ser publicly_accessible (ADR 007)"
    assert db["DBInstanceClass"] == "db.t4g.micro"


@pytest.mark.aws
def test_asg_and_alb_exist(aws_session) -> None:
    asg_name = f"{PROJECT}-asg"
    groups = aws_session.client("autoscaling").describe_auto_scaling_groups(
        AutoScalingGroupNames=[asg_name]
    )["AutoScalingGroups"]
    assert groups, f"no hay ASG {asg_name}"
    assert groups[0]["DesiredCapacity"] >= 1

    alb_name = f"{PROJECT}-alb"
    try:
        lbs = aws_session.client("elbv2").describe_load_balancers(Names=[alb_name])["LoadBalancers"]
    except ClientError as exc:
        pytest.fail(f"ALB {alb_name}: {exc}")
    assert lbs, f"no hay ALB {alb_name}"


@pytest.mark.aws
def test_alb_health(aws_session) -> None:
    alb_name = f"{PROJECT}-alb"
    try:
        dns = aws_session.client("elbv2").describe_load_balancers(Names=[alb_name])["LoadBalancers"][0][
            "DNSName"
        ]
    except ClientError as exc:
        pytest.fail(f"ALB {alb_name}: {exc}")
    url = f"http://{dns}/health"
    try:
        with urllib.request.urlopen(url, timeout=HEALTH_TIMEOUT_SEC) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        pytest.fail(f"{url}: {exc} (user-data tarda; reintentá o usá 03_verify.py)")
    assert resp.status == 200
    assert "ok" in body.lower()
