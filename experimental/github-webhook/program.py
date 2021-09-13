#!/usr/bin/env python3

from typing import get_origin
from github import Github
import click

@click.command()
@click.option('--githubtoken', prompt='Github token', help='Github token')
@click.option('--owner', prompt='Owner', help='The username of github user')
@click.option('--repository', default='', prompt=False, help='The name of the repository')
@click.option('--webhookurl', prompt='Webhook url', help='The url of webhook to add')
@click.option('--webhooksecret', default='', prompt=False, help='The secret of webhook to add, leave blank if none')
def cli(githubtoken, owner, repository, webhookurl, webhooksecret):
    """Simple program that adds a webhook to github repo."""
    g = Github(githubtoken)
    organizationOrUser = getOrganizationOrUser(owner, g)
    if len(repository)>0:
        repo = organizationOrUser.get_repo(f'{repository}')
        addHook(repo, webhookurl, webhooksecret)
    else:
        for repo in organizationOrUser.get_repos():
            addHook(repo, webhookurl, webhooksecret)

def getOrganizationOrUser(owner, g):
    try: 
        return g.get_organization(f'{owner}')
    except:
        return g.get_user(f'{owner}')

def addHook(repo, webhookurl, webhooksecret):
    EVENTS = ["*"]
    WEBHOOK_URL=f'{webhookurl}'  
    config = {
        "url": "{webhook_url}".format(webhook_url=WEBHOOK_URL),
        "content_type": "json"
    }
    if len(webhooksecret) >0:
        config["secret"]=webhooksecret
    try:
        repo.create_hook("web", config, EVENTS, active=True)
    except Exception as e:
        if (e.status == 422):        
            pass # hook already exists
        else:
            raise e

if __name__ == '__main__':
    cli()
