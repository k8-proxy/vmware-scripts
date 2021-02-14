import boto3
import datetime
import random
import json
import os
from botocore.exceptions import ClientError
from elasticsearch import Elasticsearch
from flatten_json import flatten
from dotenv import load_dotenv

def lambda_handler(event, context):
    load_dotenv()
    AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
    AWS_DEFAULT_REGION = os.getenv('AWS_DEFAULT_REGION')
    ELASTICSEARCH_HOST = os.getenv('ELASTICSEARCH_HOST')
    ELASTICSEARCH_PORT = os.getenv('ELASTICSEARCH_PORT')
    ELASTICSEARCH_USERNAME = os.getenv('ELASTICSEARCH_USERNAME')
    ELASTICSEARCH_PASSWORD = os.getenv('ELASTICSEARCH_PASSWORD')
    AWS_AGGREGATOR_NAME = os.getenv('AWS_AGGREGATOR_NAME')

    es_host = 'https://' + ELASTICSEARCH_USERNAME + ':' + ELASTICSEARCH_PASSWORD + '@' + ELASTICSEARCH_HOST + ':' + ELASTICSEARCH_PORT    

    config = boto3.client('config')
    es = Elasticsearch([es_host], verify_certs=False)
    arr_result = []
    try:
        response = config.select_aggregate_resource_config(
            Expression="SELECT configuration, relationships, tags, awsRegion,  availabilityZone, resourceCreationTime,  resourceId, resourceName, resourceType WHERE resourceType = 'AWS::EC2::Instance'",
            ConfigurationAggregatorName=AWS_AGGREGATOR_NAME,
            Limit=100
        )    
        results = response["Results"]
        for result in results:        
            ts = datetime.datetime.utcnow().isoformat()
            payload = json.loads(result)
            payload['@timestamp'] = ts
            flat_payload = flatten(payload, '.')
            print(flat_payload)        
            arr_result.append(flat_payload)
            es.index(index='awsconfig', body=flat_payload)
    except ClientError as e:
        print(e)
    return {
        'statusCode': 200,
        'body': json.dumps(arr_result)
    }

if __name__ == "__main__":
    lambda_handler("test", "test")    