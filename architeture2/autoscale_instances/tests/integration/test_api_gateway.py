import os

import pytest
import requests
import time

"""
Make sure env variable AWS_SAM_STACK_NAME exists with the name of the stack we are going to test. 
"""


class TestApiGateway:

    @pytest.fixture()
    def lb_url(self):
        # """ Get the API Gateway URL from Cloudformation Stack outputs """
        # stack_name = os.environ.get("AWS_SAM_STACK_NAME")

        # if stack_name is None:
        #     raise ValueError('Please set the AWS_SAM_STACK_NAME environment variable to the name of your stack')

        # client = boto3.client("cloudformation")

        # try:
        #     response = client.describe_stacks(StackName=stack_name)
        # except Exception as e:
        #     raise Exception(
        #         f"Cannot find stack {stack_name} \n" f'Please make sure a stack with the name "{stack_name}" exists'
        #     ) from e

        # stacks = response["Stacks"]
        # stack_outputs = stacks[0]["Outputs"]
        # api_outputs = [output for output in stack_outputs if output["OutputKey"] == "TestFunctionApi"]

        # if not api_outputs:
        #     raise KeyError(f"TestFunctionApi not found in stack {stack_name}")

        # return api_outputs[0]["OutputValue"]  # Extract url from stack outputs
        return os.environ.get("LB_URL")

    def test_api_gateway(self, lb_url):
        """ Call the Load Balancer and assert the response (May take some time) """
        for i in range(10):
            response = requests.get(lb_url)
            if response.status_code == 200:
                break
            time.wait(30)

        assert response.status_code == 200
        # assert response.json() == {"message": "hello world"}
