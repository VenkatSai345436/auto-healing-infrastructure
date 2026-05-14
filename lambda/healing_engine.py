import boto3
import json
import os
import urllib.request
import urllib.parse
from datetime import datetime

# AWS clients
ssm = boto3.client('ssm')
ec2 = boto3.client('ec2')
cloudwatch = boto3.client('cloudwatch')

# Environment variables
INSTANCE_ID   = os.environ.get('INSTANCE_ID', 'i-1234567890abcdef0')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN', '')
SLACK_WEBHOOK = os.environ.get('SLACK_WEBHOOK', '')


def lambda_handler(event, context):
    """
    Self-Healing Decision Engine
    Triggered by EventBridge when CloudWatch alarm fires.
    Decides what action to take based on alarm name.
    """
    print(f"Event received: {json.dumps(event)}")

    # Extract alarm name from EventBridge event
    alarm_name = event.get('detail', {}).get('alarmName', '')
    print(f"Alarm triggered: {alarm_name}")

    # Decision Engine — decides action based on alarm
    if 'nginx' in alarm_name.lower():
        issue  = "Nginx service stopped"
        action = "systemctl restart nginx"
        result = execute_command(action)

    elif 'docker' in alarm_name.lower():
        issue  = "Docker service stopped"
        action = "systemctl restart docker"
        result = execute_command(action)

    elif 'cpu' in alarm_name.lower():
        issue  = "CPU utilization critical (>90%)"
        action = "reboot"
        result = execute_command(action)

    elif 'healthcheck' in alarm_name.lower():
        issue  = "EC2 health check failed"
        action = "systemctl restart nginx && systemctl restart docker"
        result = execute_command(action)

    else:
        # Unknown issue — DO NOT automate, escalate to human
        issue  = f"Unknown alarm: {alarm_name}"
        action = "No automated action — escalated to human"
        result = "ESCALATED"
        notify_slack(issue, action, result)
        return {
            'statusCode': 200,
            'body': 'Unknown alarm — escalated to human'
        }

    # Notify team via Slack
    notify_slack(issue, action, result)

    return {
        'statusCode': 200,
        'body': json.dumps({
            'alarm'  : alarm_name,
            'issue'  : issue,
            'action' : action,
            'result' : result
        })
    }


def execute_command(command):
    """
    Execute shell command on EC2 via SSM SendCommand.
    No SSH needed — secure through AWS internal network.
    This is where AccessDeniedException was hit and fixed:
    Added ssm:SendCommand to Lambda IAM policy.
    """
    try:
        response = ssm.send_command(
            InstanceIds=[INSTANCE_ID],
            DocumentName='AWS-RunShellScript',
            Parameters={'commands': [command]},
            Comment=f'Auto-heal: {command}'
        )

        command_id = response['Command']['CommandId']
        print(f"SSM Command sent: {command_id}")
        return "SUCCESS"

    except Exception as e:
        print(f"SSM Error: {str(e)}")
        return f"FAILED: {str(e)}"


def notify_slack(issue, action, result):
    """
    Send Slack notification after every heal action.
    On-call engineers see what happened without waking up.
    """
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    status_emoji = "✅" if result == "SUCCESS" else "❌"

    message = {
        "text": f"""
🚨 *AUTO-HEAL EVENT*
━━━━━━━━━━━━━━━━━━━━
*Instance:*  `{INSTANCE_ID}`
*Issue:*     {issue}
*Action:*    `{action}`
*Status:*    {status_emoji} {result}
*Time:*      {timestamp}
━━━━━━━━━━━━━━━━━━━━
        """
    }

    if not SLACK_WEBHOOK:
        print("Slack webhook not configured")
        print(f"Would send: {message['text']}")
        return

    try:
        data = json.dumps(message).encode('utf-8')
        req  = urllib.request.Request(
            SLACK_WEBHOOK,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        urllib.request.urlopen(req)
        print("Slack notification sent successfully")

    except Exception as e:
        print(f"Slack notification failed: {str(e)}")


# ── Local testing ──────────────────────────────────────────
if __name__ == "__main__":
    # Simulate CloudWatch alarm event
    test_event = {
        "detail": {
            "alarmName": "cpu-critical"
        }
    }
    result = lambda_handler(test_event, None)
    print(f"\nResult: {json.dumps(result, indent=2)}")
