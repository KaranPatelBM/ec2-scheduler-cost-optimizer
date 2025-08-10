import pytest
from unittest.mock import patch, MagicMock
import os

# Mock boto3 before importing lambda functions
with patch('boto3.client'):
    from start_ec2 import lambda_handler as start_handler
    from stop_ec2 import lambda_handler as stop_handler

class TestLambdaFunctions:
    
    def setup_method(self):
        """Setup test environment"""
        os.environ['INSTANCE_ID'] = 'i-1234567890abcdef0'
        os.environ['REGION'] = 'ap-south-1'
    
    @patch('boto3.client')
    def test_start_ec2_success(self, mock_boto_client):
        """Test successful EC2 start"""
        mock_ec2 = MagicMock()
        mock_boto_client.return_value = mock_ec2
        
        result = start_handler({}, {})
        
        mock_ec2.start_instances.assert_called_once_with(
            InstanceIds=['i-1234567890abcdef0']
        )
    
    @patch('boto3.client')  
    def test_stop_ec2_success(self, mock_boto_client):
        """Test successful EC2 stop"""
        mock_ec2 = MagicMock()
        mock_boto_client.return_value = mock_ec2
        
        result = stop_handler({}, {})
        
        mock_ec2.stop_instances.assert_called_once_with(
            InstanceIds=['i-1234567890abcdef0']
        )
    
    def test_environment_variables(self):
        """Test environment variables are set"""
        assert os.environ.get('INSTANCE_ID') is not None
        assert os.environ.get('REGION') is not None
