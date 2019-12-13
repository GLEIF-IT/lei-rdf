import os
from base64 import b64decode

import boto3


kms = boto3.client('kms', region_name='us-east-1')

def get_kms_key(env_var: str) -> str:
    if env_var and env_var.startswith('kms::'):
        return kms.decrypt(
            CiphertextBlob=b64decode(env_var.replace('kms::', '')))['Plaintext'].decode()
    else:
        return env_var


decrypted_token = get_kms_key(os.environ.get('DATAWORLD_TOKEN'))
os.environ['DATAWORLD_TOKEN'] = decrypted_token

saxon_license = get_kms_key(os.environ.get('SAXON_LICENSE'))
with open('/root/saxon/bin/saxon_license.lic', 'w') as f:
    f.write(saxon_license)
