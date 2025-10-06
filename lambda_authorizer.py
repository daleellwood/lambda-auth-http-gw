# ========================
# AWS Lambda Authorizer Function
# ========================

import os
from ipaddress import ip_network, ip_address
import uuid
import ast

def check_ip(ip_addr, ip_ranges):
    """
    Check if an IP address is within the specified IP ranges.
    
    Args:
        ip_addr (str): The IP address to check
        ip_ranges (list): List of IP addresses or CIDR blocks
    
    Returns:
        bool: True if IP is allowed, False otherwise
    """
    valid_ip = False
    
    # Check CIDR blocks first
    cidr_blocks = [element for element in ip_ranges if "/" in element]
    if cidr_blocks:
        for cidr in cidr_blocks:
            try:
                net = ip_network(cidr)
                valid_ip = ip_address(ip_addr) in net
                if valid_ip:
                    break
            except ValueError:
                continue
    
    # Check exact IP matches if not found in CIDR blocks
    if not valid_ip and ip_addr in ip_ranges:
        valid_ip = True

    return valid_ip

def lambda_handler(event, context):
    """
    Lambda authorizer function for API Gateway HTTP API.
    
    Args:
        event: API Gateway request event
        context: Lambda context object
    
    Returns:
        dict: Authorization response with policy document
    """
    # Extract region from event or use default
    region = event["requestContext"].get("region", "us-east-1")
    
    try:
        # Extract request information
        source_ip = event["requestContext"]["http"]["sourceIp"]
        api_id = event["requestContext"]["apiId"]
        account_id = event["requestContext"]["accountId"]
        method = event["requestContext"]["http"]["method"]
        stage = event["requestContext"]["stage"]
        route = event["requestContext"]["http"]["path"]
        
        # Get allowed IP ranges from environment variable
        ip_ranges = ast.literal_eval(os.environ.get("IP_RANGE", "[]"))
        
        # Check if source IP is allowed
        is_allowed = check_ip(source_ip, ip_ranges)
        
        # Log request details
        print(f"Source IP: {source_ip}")
        print(f"Allowed IPs: {ip_ranges}")
        print(f"API ID: {api_id}")
        print(f"Account ID: {account_id}")
        print(f"Method: {method}")
        print(f"Stage: {stage}")
        print(f"Route: {route}")
        print(f"Region: {region}")
        print(f"Authorization result: {'ALLOW' if is_allowed else 'DENY'}\"")
        
        # Generate policy based on authorization result
        if is_allowed:
            print("Request allowed based on IP whitelist")
            effect = "Allow"
            resource = f"arn:aws:execute-api:{region}:{account_id}:{api_id}/{stage}/{method}{route}"
        else:
            print("Request denied - IP not in whitelist")
            effect = "Deny"
            resource = f"arn:aws:execute-api:{region}:{account_id}:{api_id}/*/*/*"
        
        # Return authorization response
        response = {
            "principalId": f"{uuid.uuid4().hex}",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": effect,
                        "Resource": resource,
                    }
                ],
            },
            "context": {
                "sourceIp": source_ip,
                "userAgent": event["requestContext"]["http"].get("userAgent", ""),
            },
        }
        
        return response

    except KeyError as e:
        print(f"KeyError: Missing required field {str(e)}")
        # Return deny policy for malformed requests
        return {
            "principalId": f"{uuid.uuid4().hex}",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Deny",
                        "Resource": f"arn:aws:execute-api:{region}:*:*/*/*/*",
                    }
                ],
            },
            "context": {"error": "Malformed request"},
        }
    
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        # Return deny policy for unexpected errors
        return {
            "principalId": f"{uuid.uuid4().hex}",
            "policyDocument": {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Action": "execute-api:Invoke",
                        "Effect": "Deny",
                        "Resource": f"arn:aws:execute-api:{region}:*:*/*/*/*",
                    }
                ],
            },
            "context": {"error": "Internal error"},
        }