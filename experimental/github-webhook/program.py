#!/usr/bin/env python3

import requests
import os
from pprint import pprint
import json

owner = "faizando"
repo = "playground-webhooks"
github_base_url = "https://api.github.com"
token = os.getenv('GITHUB_TOKEN', '...')

hook_url = "https://github.com/faizando/playground-webhooks/settings/hooks/new"
repo_url= f"https://api.github.com/repos/{owner}/{repo}"


def listRepoHooks():
    query_url = f"{repo_url}/hooks"
    headers = {'Authorization': f'token {token}', 'accept': f'application/vnd.github.v3+json' }
    r = requests.get(query_url, headers=headers)
    pprint(r.json())
    
def addHook(repo_url):
    query_url = f"{repo_url}/hooks"
    headers = {'Authorization': f'token {token}', 'accept': f'application/vnd.github.v3+json' }
    body =  {'name' : 'web', 'config' : { 'url':'https://api.github.cop', 'secret' : 'none', 'events' : [ "*" ] }}

    # pprint(json.dumps(body))
    r = requests.post(query_url, headers=headers, data=json.dumps(body))
    pprint(r.json())

# listRepoHooks()
addHook(repo_url)
