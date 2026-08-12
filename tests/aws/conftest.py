from __future__ import annotations

import os

import boto3
import pytest
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError, ProfileNotFound

PROJECT = os.environ.get("PROJECT_NAME", "poc-cloud-foundation-lab")
REGION = os.environ.get("AWS_DEFAULT_REGION", "us-east-1")
PROFILE = os.environ.get("AWS_PROFILE", "poc-aws")


def drop_localstack_overlay() -> None:
    os.environ.pop("AWS_ENDPOINT_URL", None)
    if os.environ.get("AWS_ACCESS_KEY_ID") == "test":
        os.environ.pop("AWS_ACCESS_KEY_ID", None)
        os.environ.pop("AWS_SECRET_ACCESS_KEY", None)
        os.environ.pop("AWS_SESSION_TOKEN", None)
    os.environ["AWS_PROFILE"] = PROFILE
    os.environ["AWS_DEFAULT_REGION"] = REGION
    os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")


@pytest.fixture(scope="session")
def aws_session():
    """Session boto3 contra AWS real. Skip si no hay profile/creds (ADR 009)."""
    drop_localstack_overlay()
    try:
        sess = boto3.Session(profile_name=PROFILE, region_name=REGION)
        ident = sess.client("sts").get_caller_identity()
    except (ProfileNotFound, NoCredentialsError, BotoCoreError, ClientError) as exc:
        pytest.skip(f"sin credenciales AWS reales (profile {PROFILE}): {exc}")
    if ident["Account"] == "000000000000":
        pytest.skip("account 000000000000 — LocalStack, no AWS")
    return sess
