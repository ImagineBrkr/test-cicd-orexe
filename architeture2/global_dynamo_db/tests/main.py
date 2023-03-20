import boto3
import random
import pytest
import os

@pytest.fixture(scope="session")
def get_table():
    table_name = os.getenv("dynamo_table_name")
    dynamo_client = boto3.resource('dynamodb')
    table = dynamo_client.Table(table_name)
    return table

def test_dynamo_table(get_table):
    table = get_table
    print(table.replicas)
    assert len(get_table.replicas) > 0

def test_add_item(get_table):
    table = get_table
    table.put_item(
        Item={
            'ClientId': random.randint(1,10000),
            'Last_Name': 'Perez',
            'First_Name': 'Carlos'
        }
    )

# test_dynamo_table()