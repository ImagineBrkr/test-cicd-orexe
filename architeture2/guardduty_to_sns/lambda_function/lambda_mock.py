import boto3
import json

region = 'us-east-1'
cloudwatch = boto3.client('events', region_name=region)

def lambda_handler(event, context):
    put_event(json.dumps(
          {'severity': 1, 
           'accountId': '123',
           'id': '456',
           'type': 'Attack',
           'description': 'There was an attack!',}), 
        'GuardDuty Finding', 
        'GuardDuty', 
        'mock_guarduty', 
        'guardduty_event_bus')

def put_event(detail, detail_type, resource, source, eventbus):
        response = cloudwatch.put_events(
            Entries=[
                {
                    'Detail': detail,
                    'DetailType': detail_type,
                    'Resources': [
                        resource,
                    ],
                    'Source': source,
                    'EventBusName': eventbus
                }
            ]
        )
        print(response['Entries'])
