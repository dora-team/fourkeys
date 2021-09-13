#!/usr/bin/env python3

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
    if len(repository)>0:
        repo = g.get_repo(f'{owner}/{repository}')
        addHook(repo, webhookurl, webhooksecret)
    else:
        for repo in g.get_user().get_repos():
            addHook(repo, webhookurl, webhooksecret)
    
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
    except:
        pass # hook already exists

if __name__ == '__main__':
    cli()
