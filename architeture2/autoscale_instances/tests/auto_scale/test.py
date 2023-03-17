import boto3

import os

import pytest
import requests
import time
from datetime import datetime,timedelta, timezone
from subprocess import CalledProcessError
import subprocess


def getInstanceDetails(InstanceId):
    ec2_client = boto3.client('ec2')
    response = ec2_client.describe_instances()
    instances = response['Reservations']
    for i in instances:
        for j in i['Instances']:
            if j['InstanceId'] == InstanceId:
                return j

def getNameConnect(InstanceId):
    instance = getInstanceDetails(InstanceId)
    return "admin@"+instance['PublicIpAddress']


def getInstanceConnect(InstanceId):
    instance = getInstanceDetails(InstanceId)
    connect = "ssh -o StrictHostKeyChecking=no -i \"%s.pem\" %s" % (instance['KeyName'], getNameConnect(InstanceId))
    return connect

@pytest.fixture(scope='session')
def get_ssh_key():
    secrets_client = boto3.client(service_name='secretsmanager')
    get_secret_value_response = secrets_client.get_secret_value(
            SecretId='keypair_customkey'
        )
    key = get_secret_value_response['SecretString']
    print(key)
    f = open("customkey.pem", "w")
    f.write(key)
    f.close()
    # subprocess.call('cat customkey.pem', shell = True)
    subprocess.call('chmod 400 customkey.pem', shell = True)    

def test_scale(get_ssh_key):
        
        ec2_client = boto3.client('ec2')
        auto_scaling_instances = []
        def get_auto_scaling_instances():
            instances = []
            response = ec2_client.describe_instances()
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    if instance['State']['Name'] == 'running' or instance['State']['Name'] == 'pending':
                        if 'Tags' in instance:
                            for tag in instance['Tags']:
                                if tag['Key'] == 'aws:autoscaling:groupName' and tag['Value'] == 'autoscale_group':
                                    instances.append(instance['InstanceId'])
                                
            return instances
            
        auto_scaling_instances = get_auto_scaling_instances()
        num_instances = len(auto_scaling_instances)
        print(len(auto_scaling_instances))
        num_tries = 0
        while num_instances == 0:
            num_tries += 1
            if num_tries == 5:
                raise Exception("No instances detected")
            time.sleep(30)
            auto_scaling_instances = get_auto_scaling_instances()
            num_instances = len(auto_scaling_instances)           

        for i in auto_scaling_instances:
            subprocess.call(getInstanceConnect(i) + ' \"sudo stress --cpu 1500 --timeout 180 \"', shell = True)

        time.sleep(10)
        for i in range(2):
            
            if num_instances < len(auto_scaling_instances):
                break
            time.sleep(10)
            auto_scaling_instances = get_auto_scaling_instances()

        assert num_instances < len(auto_scaling_instances)

def test_ansible(get_ssh_key):
        ec2_client = boto3.client('ec2')
        auto_scaling_instances = []
        def get_auto_scaling_instances():
            instances = []
            response = ec2_client.describe_instances()
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    if instance['State']['Name'] == 'running':
                        if 'Tags' in instance:
                            for tag in instance['Tags']:
                                if tag['Key'] == 'aws:autoscaling:groupName' and tag['Value'] == 'autoscale_group':
                                    instances.append(instance['InstanceId'])
            return instances

        auto_scaling_instances = get_auto_scaling_instances()
        num_instances = len(auto_scaling_instances)
        num_tries = 0
        while num_instances == 0:
            num_tries += 1
            if num_tries == 5:
                raise Exception("No instances detected")
            time.sleep(30)
            auto_scaling_instances = get_auto_scaling_instances()
            num_instances = len(auto_scaling_instances)   
        try:
            result = subprocess.check_output(getInstanceConnect(auto_scaling_instances[0]) + ' \"ansible --version\"', shell = True)
        except CalledProcessError:
            raise Exception("Ansible not found")
