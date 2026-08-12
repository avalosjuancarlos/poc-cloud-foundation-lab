#!/usr/bin/env python3
"""Verifica el stack AWS real: tags, RDS privada, ALB /health. Aborta si es LocalStack."""

from __future__ import annotations

import os
import sys
import time
import urllib.error
import urllib.request

import boto3
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError, ProfileNotFound

PROJECT = os.environ.get("PROJECT_NAME", "poc-cloud-foundation-lab")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
PROFILE = os.environ.get("AWS_PROFILE", "poc-aws")
HEALTH_TIMEOUT_SEC = int(os.environ.get("HEALTH_TIMEOUT_SEC", "420"))
HEALTH_INTERVAL_SEC = int(os.environ.get("HEALTH_INTERVAL_SEC", "15"))


def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


def drop_localstack_overlay() -> None:
    os.environ.pop("AWS_ENDPOINT_URL", None)
    if os.environ.get("AWS_ACCESS_KEY_ID") == "test":
        os.environ.pop("AWS_ACCESS_KEY_ID", None)
        os.environ.pop("AWS_SECRET_ACCESS_KEY", None)
        os.environ.pop("AWS_SESSION_TOKEN", None)
    os.environ["AWS_PROFILE"] = PROFILE
    os.environ["AWS_DEFAULT_REGION"] = REGION
    os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")


def session() -> boto3.Session:
    try:
        return boto3.Session(profile_name=PROFILE, region_name=REGION)
    except ProfileNotFound:
        fail(f"no existe el profile {PROFILE}. aws configure --profile {PROFILE}")


def main() -> None:
    drop_localstack_overlay()
    print(f"==> 03_verify: profile={PROFILE} region={REGION} project={PROJECT}")
    print("Criterio: API AWS real + HTTP /health en el ALB (phpinfo es extra).")

    sess = session()
    try:
        ident = sess.client("sts").get_caller_identity()
    except (NoCredentialsError, BotoCoreError, ClientError) as exc:
        fail(f"sts: {exc}")

    account = ident["Account"]
    if account == "000000000000":
        fail("account 000000000000 — seguís en LocalStack. Unset AWS_ENDPOINT_URL y usá poc-aws.")
    print(f"OK  cuenta {account} arn={ident['Arn']}")

    ec2 = sess.client("ec2")
    vpcs = ec2.describe_vpcs(
        Filters=[
            {"Name": "tag:Project", "Values": [PROJECT]},
            {"Name": "tag:Environment", "Values": ["aws"]},
        ]
    )["Vpcs"]
    if not vpcs:
        fail(f"no hay VPC con tag Project={PROJECT} Environment=aws")
    print(f"OK  VPC {vpcs[0]['VpcId']}")

    rds = sess.client("rds")
    db_id = f"{PROJECT}-pg"
    try:
        db = rds.describe_db_instances(DBInstanceIdentifier=db_id)["DBInstances"][0]
    except ClientError as exc:
        fail(f"RDS {db_id}: {exc}")
    if db.get("PubliclyAccessible"):
        fail(f"RDS {db_id} está publicly_accessible (ADR 007)")
    if db.get("MultiAZ"):
        print(f"WARN RDS Multi-AZ=true (el default del lab es false, ADR 008)")
    print(f"OK  RDS {db_id} {db['DBInstanceClass']} public={db['PubliclyAccessible']}")

    asg_name = f"{PROJECT}-asg"
    asg = sess.client("autoscaling")
    groups = asg.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])["AutoScalingGroups"]
    if not groups:
        fail(f"no hay ASG {asg_name}")
    print(f"OK  ASG {asg_name} desired={groups[0]['DesiredCapacity']}")

    elbv2 = sess.client("elbv2")
    alb_name = f"{PROJECT}-alb"
    try:
        lbs = elbv2.describe_load_balancers(Names=[alb_name])["LoadBalancers"]
    except ClientError as exc:
        fail(f"ALB {alb_name}: {exc}")
    dns = lbs[0]["DNSName"]
    print(f"OK  ALB {alb_name} dns={dns}")

    health_url = f"http://{dns}/health"
    deadline = time.time() + HEALTH_TIMEOUT_SEC
    last_err = "timeout"
    while time.time() < deadline:
        try:
            with urllib.request.urlopen(health_url, timeout=10) as resp:
                body = resp.read().decode("utf-8", errors="replace")
                if resp.status == 200 and "ok" in body.lower():
                    print(f"OK  HTTP {health_url} → {resp.status} {body.strip()!r}")
                    break
                last_err = f"status={resp.status} body={body[:80]!r}"
        except (urllib.error.URLError, TimeoutError, OSError) as exc:
            last_err = str(exc)
        print(f"... esperando /health ({last_err})")
        time.sleep(HEALTH_INTERVAL_SEC)
    else:
        fail(f"{health_url} no respondió 200 ok en {HEALTH_TIMEOUT_SEC}s ({last_err})")

    php_url = f"http://{dns}/phpinfo.php"
    try:
        with urllib.request.urlopen(php_url, timeout=10) as resp:
            php = resp.read().decode("utf-8", errors="replace")
            if resp.status == 200 and "phpinfo" in php.lower():
                print(f"OK  HTTP {php_url} (phpinfo)")
            else:
                print(f"WARN {php_url} status={resp.status} (health ya alcanzó)")
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        print(f"WARN {php_url}: {exc} (health ya alcanzó)")

    print("Stack aws verificado. Segunda corrida de este script debe dar el mismo resultado.")
    print("Destroy hoy: terraform -chdir=iac/aws destroy")


if __name__ == "__main__":
    main()
