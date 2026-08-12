from __future__ import annotations

import json
from pathlib import Path
from string import Template

REPO = Path(__file__).resolve().parents[2]
IAM = REPO / "iam" / "aws"


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _render_tftpl(path: Path, **values: str) -> dict:
    rendered = Template(path.read_text(encoding="utf-8")).substitute(**values)
    return json.loads(rendered)


def _assert_policy_shape(doc: dict) -> None:
    assert doc["Version"] == "2012-10-17"
    assert isinstance(doc["Statement"], list)
    assert doc["Statement"]
    for stmt in doc["Statement"]:
        assert stmt["Effect"] in {"Allow", "Deny"}
        assert "Action" in stmt


def test_trust_policy_allows_ec2_assume() -> None:
    doc = _load_json(IAM / "trust_policy.json")
    _assert_policy_shape(doc)
    stmt = doc["Statement"][0]
    assert stmt["Effect"] == "Allow"
    assert stmt["Principal"]["Service"] == "ec2.amazonaws.com"
    assert stmt["Action"] == "sts:AssumeRole"


def test_ec2_app_policy_is_least_privilege_on_one_bucket() -> None:
    doc = _render_tftpl(
        IAM / "ec2_app_policy.json.tftpl",
        bucket_name="poc-cloud-foundation-lab-111111111111-app",
    )
    _assert_policy_shape(doc)
    resources = []
    for stmt in doc["Statement"]:
        assert stmt["Effect"] == "Allow"
        assert stmt["Action"] != "*"
        actions = stmt["Action"] if isinstance(stmt["Action"], list) else [stmt["Action"]]
        assert "s3:*" not in actions
        res = stmt["Resource"]
        resources.extend(res if isinstance(res, list) else [res])
    assert all("poc-cloud-foundation-lab-111111111111-app" in r for r in resources)
    assert not any(r == "*" for r in resources)


def test_bucket_policy_denies_insecure_transport() -> None:
    role_arn = "arn:aws:iam::111111111111:role/poc-cloud-foundation-lab-ec2"
    doc = _render_tftpl(
        IAM / "bucket_policy.json.tftpl",
        bucket_name="poc-cloud-foundation-lab-111111111111-app",
        role_arn=role_arn,
    )
    _assert_policy_shape(doc)
    allow = next(s for s in doc["Statement"] if s["Effect"] == "Allow")
    deny = next(s for s in doc["Statement"] if s["Effect"] == "Deny")
    assert allow["Principal"]["AWS"] == role_arn
    assert deny["Condition"]["Bool"]["aws:SecureTransport"] == "false"
    assert deny["Action"] == "s3:*"
    assert deny["Principal"] == "*"
