import json
import os
import logging

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ec2 = boto3.client("ec2")
sns = boto3.client("sns")

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
ALLOWED_GROUP_ID = os.environ["ALLOWED_GROUP_ID"]


def publish_alert(message):
    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject="DEPI Security Group Auto-Remediation",
        Message=message,
    )


def lambda_handler(event, context):
    logger.info("Received event: %s", json.dumps(event))

    detail = event.get("detail", {})
    parameters = detail.get("requestParameters", {})

    group_id = parameters.get("groupId")

    if not group_id:
        message = "Remediation skipped: event contains no security group ID."
        logger.warning(message)
        publish_alert(message)
        return {"status": "skipped", "reason": "missing_group_id"}

    if group_id != ALLOWED_GROUP_ID:
        message = (
            f"Remediation skipped for unexpected security group: {group_id}"
        )
        logger.warning(message)
        publish_alert(message)
        return {"status": "skipped", "reason": "group_not_allowed"}

    logger.info("Inspecting security group: %s", group_id)

    try:
        response = ec2.describe_security_groups(
            GroupIds=[group_id]
        )
    except ClientError:
        logger.exception("Failed to describe security group %s", group_id)
        raise

    revoked_rules = []

    for group in response.get("SecurityGroups", []):
        for permission in group.get("IpPermissions", []):
            protocol = permission.get("IpProtocol")
            from_port = permission.get("FromPort")
            to_port = permission.get("ToPort")

            # Only handle explicit TCP SSH/RDP rules.
            if protocol != "tcp":
                continue

            if from_port not in (22, 3389) or to_port != from_port:
                continue

            for ip_range in permission.get("IpRanges", []):
                if ip_range.get("CidrIp") != "0.0.0.0/0":
                    continue

                revoke_permission = {
                    "IpProtocol": "tcp",
                    "FromPort": from_port,
                    "ToPort": to_port,
                    "IpRanges": [{"CidrIp": "0.0.0.0/0"}],
                }

                try:
                    ec2.revoke_security_group_ingress(
                        GroupId=group_id,
                        IpPermissions=[revoke_permission],
                    )
                    revoked_rules.append(
                        f"TCP/{from_port} from 0.0.0.0/0"
                    )
                    logger.warning(
                        "Revoked public ingress rule: group=%s port=%s",
                        group_id,
                        from_port,
                    )
                except ClientError:
                    logger.exception(
                        "Failed to revoke public rule on %s port %s",
                        group_id,
                        from_port,
                    )
                    raise

    if revoked_rules:
        message = (
            f"Auto-remediation completed for security group {group_id}.\n"
            "Revoked rules:\n- " + "\n- ".join(revoked_rules)
        )
    else:
        message = (
            f"Security group {group_id} was inspected. "
            "No matching public TCP/22 or TCP/3389 rule was found."
        )

    logger.info("%s", message)
    publish_alert(message)

    return {
        "status": "completed",
        "security_group_id": group_id,
        "revoked_rules": revoked_rules,
    }