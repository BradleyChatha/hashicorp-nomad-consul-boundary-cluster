# Note: This script intentionally only uses the standard library to perform tasks.
#       It's not the cleanest, but removes any friction of having to install dependencies, setting up a venv, etc.

import abc
import subprocess
import sys
import os
from typing import List
import yaml

GRAY='\033[90m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
CLEAR='\033[0m'

def check_commands_exists(cmds : List[str]) -> None:
    print(f'{GRAY}Checking required commands exist...{CLEAR}')
    all_found = True
    for cmd in cmds:
        exists = subprocess.run(['which', cmd], capture_output=True).returncode == 0
        if not exists:
            all_found = False
            print(f'  {RED}NO  {cmd}{CLEAR}')
        else:
            print(f'  {GREEN}YES {cmd}{CLEAR}')
    
    if not all_found:
        print(f'{RED}Please install the missing executables and try again{CLEAR}')
        exit(1)

def get_aws_region() -> str:
    if 'AWS_DEFAULT_REGION' in os.environ:
        return os['AWS_DEFAULT_REGION']
    else:
        return subprocess.run([
            'aws', 'configure', 'get', 'region'
        ], check=True, capture_output=True).stdout.decode(sys.getfilesystemencoding()).strip('\n')

def get_aws_secret(name : str) -> str:
    return subprocess.run([
        'aws', 'secretsmanager', 'get-secret-value', 
        '--secret-id', name, 
        '--output', 'text', 
        '--query', 'SecretString'
    ], check=True, capture_output=True).stdout.decode(sys.getfilesystemencoding()).strip('\n')

config = {}
with open('cluster.yml') as f:
    config = yaml.safe_load(f)

class BaseCommand(abc.ABC):
    @abc.abstractmethod
    def should_run(self) -> bool:
        pass

    @abc.abstractmethod
    def run(self) -> None:
        pass

class CreateTerraformPrerequisitesCommand(BaseCommand):
    s3_bucket_exists = False
    dynamo_table_exists = False

    def should_run(self) -> bool:
        print(f'{GRAY}Checking if prerequisite resources already exist...{CLEAR}')
        s3_result = subprocess.run(['aws', 's3', 'ls', config['s3_backend_bucket']], capture_output=True)
        if s3_result.returncode != 0 and b'(NoSuchBucket)' not in s3_result.stderr:
            raise subprocess.CalledProcessError(s3_result.returncode, s3_result.args, stderr=s3_result.stderr)
        else:
            self.s3_bucket_exists = b'(NoSuchBucket)' not in s3_result.stderr

        if self.s3_bucket_exists:
            print(f'  {GREEN}S3 bucket exists{CLEAR}')
        else:
            print(f'  {RED}S3 bucket doesnt exist, will prompt for creation{CLEAR}')

        dynamo_result = subprocess.run([
            'aws', 'dynamodb', 'describe-table', 
            '--table-name', config['s3_backend_dynamodb'], 
            '--region', config['s3_backend_region'],
        ], capture_output=True)
        if dynamo_result.returncode != 0 and b'(ResourceNotFoundException)' not in dynamo_result.stderr:
            raise subprocess.CalledProcessError(dynamo_result.returncode, dynamo_result.args, stderr=dynamo_result.stderr)
        else:
            self.dynamo_table_exists = b'(ResourceNotFoundException)' not in dynamo_result.stderr

        if self.dynamo_table_exists:
            print(f'  {GREEN}DynamoDB table exists{CLEAR}')
        else:
            print(f'  {RED}DynamoDB table doesnt exist, will prompt for creation{CLEAR}')

        if self.s3_bucket_exists and self.dynamo_table_exists:
            return False
        else:
            return input(f'{YELLOW}Create the missing resources [y/n]: {CLEAR}') == 'y'

    def run(self) -> None:
        print(f'{GRAY}Creating AWS Resources...{CLEAR}')
        
        if not self.s3_bucket_exists:
            subprocess.run([
                'aws', 's3', 'mb', f"s3://{config['s3_backend_bucket']}"
            ], check=True, capture_output=True)
            print(f'  {GREEN}Created S3 Bucket{CLEAR}')

        if not self.dynamo_table_exists:
            subprocess.run([
                'aws', 'dynamodb', 'create-table', 
                '--table-name', config['s3_backend_dynamodb'],
                '--attribute-definitions', 'AttributeName=LockID,AttributeType=S',
                '--key-schema', 'AttributeName=LockID,KeyType=HASH',
                '--table-class', 'STANDARD_INFREQUENT_ACCESS',
                '--billing-mode', 'PAY_PER_REQUEST',
                '--region', config['s3_backend_region'],
            ], check=True, capture_output=True)
            print(f'  {GREEN}Created DynamoDB table{CLEAR}')

class BootstrapCommand(BaseCommand):
    def should_run(self) -> bool:
        return not os.path.isfile('ansible/generated/_create_bootstrap_complete')

    def run(self) -> None:
        print(f'{GRAY}Running Terraform to create initial infrastructure...{CLEAR}')

        subprocess.run([
            'terraform', 'init',
            '--backend-config', f'bucket={config["s3_backend_bucket"]}',
            '--backend-config', f'region={config["s3_backend_region"]}',
            '--backend-config', f'dynamodb_table={config["s3_backend_dynamodb"]}',
        ], cwd='terraform/main', check=True)

        try:
            subprocess.run([
                'terraform', 'apply',
                '-auto-approve',
                '-var', 'enable_bootstrap_resources=true',
                '-var', f'root_domain_name={config["root_domain_name"]}',
            ], cwd='terraform/main', check=True)
        except subprocess.CalledProcessError as e:
            print(f'{YELLOW}NOTE: [The below NOTEs only apply if the error is "CertificateNotFound"]')
            print(f'{YELLOW}NOTE: This failure is normal. Please setup the DNS records for the newly-made ACM certificate, and run this script again.{CLEAR}')
            print(f'{YELLOW}NOTE: This cannot be done automatically due to there being way, _way_ too many DNS providers to support.{CLEAR}')
            raise e

        os.environ['ANSIBLE_HOST_KEY_CHECKING'] = 'false'
        subprocess.run([
            'ansible-playbook',
            '-i', f'ansible/generated/cluster-{get_aws_region()}.inventory', # TODO: Needs to be a bit more configurable
            '-i', f'ansible/generated/cluster-{get_aws_region()}_aws_ec2.yaml', # TODO: Needs to be a bit more configurable
            '-e', f'v_boundary_ui_domain=boundary.{config["root_domain_name"]}', # TODO: Needs to be a bit more configurable
            'ansible/bootstrap.ansible.yaml',
        ], check=True)

        open('ansible/generated/_create_bootstrap_complete', "w").close()

class RemoveBootstrapCommand(BaseCommand):
    def should_run(self) -> bool:
        return not os.path.isfile('ansible/generated/_create_remove_bootstrap_complete')

    def run(self) -> None:
        print(f'{GRAY}Running Terraform to remove bootstrap infrastructure...{CLEAR}')

        subprocess.run([
            'terraform', 'apply',
            '-auto-approve',
            '-var', 'enable_bootstrap_resources=false',
            '-var', f'root_domain_name={config["root_domain_name"]}',
        ], cwd='terraform/main', check=True)

        open('ansible/generated/_create_remove_bootstrap_complete', "w").close()

class PackerCommand(BaseCommand):
    def should_run(self) -> bool:
        return not os.path.isfile('ansible/generated/_create_packer_complete')

    def run(self) -> None:
        print(f'{GRAY}Running Packer to generate Golden AMI...{CLEAR}')

        subprocess.run([
            'packer', 'build',
            '-var', f'ansible_extra_arguments=["--extra-vars", "root_domain_name={config["root_domain_name"]}"]',
            '-var', f'region={get_aws_region()}',
            'golden.pkr.hcl'
        ], cwd='packer', check=True)

        open('ansible/generated/_create_packer_complete', "w").close()

class ShowHelpMessageCommand(BaseCommand):
    def should_run(self) -> bool:
        return True

    def run(self) -> None:
        lb_dns_name = subprocess.run([
            'terraform', 'output', 'lb_dns_name'
        ], cwd='terraform/main', capture_output=True).stdout.decode(sys.getfilesystemencoding()).strip('\n"')
        consul_admin_token = get_aws_secret('cluster-consul-bootstrap-token')
        nomad_admin_token = get_aws_secret('cluster-nomad-bootstrap-token')
        boundary_admin_password = get_aws_secret('cluster-boundary-admin-password')

        print('------------------------------')
        print(f'{GREEN}Completed!{CLEAR}')
        print(f'{YELLOW}To finish off:{CLEAR}')
        print(f'  {YELLOW}Set this DNS Record:{CLEAR} CNAME boundary.{config["root_domain_name"]} {lb_dns_name}')
        print(f'  {YELLOW}Log into Boundary:{CLEAR} User=admin Pass={boundary_admin_password}')
        print(f'    {RED}!! Download the Boundary Desktop Client so you can connect to Nomad and Consul easily !!{CLEAR}')
        print(f'  {YELLOW}Log into Nomad:{CLEAR} Token={nomad_admin_token}')
        print(f'  {YELLOW}Log into Consul:{CLEAR} Token={consul_admin_token}')

if input(f'{YELLOW}Do you acknowledge that this will create billable AWS resources [y/n]: {CLEAR}') != 'y':
    exit(0)

check_commands_exists([
    'aws',
    'terraform',
    'ansible-playbook',
    'packer',
])

commands : List[BaseCommand] = [
    CreateTerraformPrerequisitesCommand(),
    PackerCommand(),
    BootstrapCommand(),
    RemoveBootstrapCommand(),
    ShowHelpMessageCommand(),
]

for command in commands:
    try:
        if command.should_run():
            command.run()
    except subprocess.CalledProcessError as e:
        print(f'{RED}Exit code {e.returncode} from command {e.args}\n{CLEAR}')
        if e.stderr is not None:
            print('stderr: {}'.format(e.stderr.decode(sys.getfilesystemencoding())))
        exit(1)