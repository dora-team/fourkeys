#!/usr/bin/env python3

from github import Github
import click

@click.command()
@click.option('--githubtoken', prompt='Github token', help='Github token')
@click.option('--owner', prompt='Owner', help='The username of github user')
@click.option('--repo', prompt='Repository name', help='The name of the repository')
@click.option('--webhookurl', prompt='Webhook url', help='The url of webhook to add')
@click.option('--webhooksecret', default='', prompt=False, help='The secret of webhook to add, leave blank if none')
def cli(githubtoken, owner, repo, webhookurl, webhooksecret):
    """Simple program that adds a webhook to github repo."""
    addHook(githubtoken, owner, repo, webhookurl, webhooksecret)
        
def addHook(githubtoken, owner, repo, webhookurl, webhooksecret):
    g = Github(githubtoken)
    repo = g.get_repo(f'{owner}/{repo}')
    print(repo.name)
    EVENTS = ["*"]
    WEBHOOK_URL=f'{webhookurl}'  
    config = {
        "url": "{webhook_url}".format(webhook_url=WEBHOOK_URL),
        "content_type": "json"
    }
    if len(webhooksecret) >0:
        config["secret"]=webhooksecret
    repo.create_hook("web", config, EVENTS, active=True)

if __name__ == '__main__':
    cli()
