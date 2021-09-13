### About

Python program to add webhook to the github to github users's/organizations's repo(s) triggered on all events. Currently, program only add webhooks and does not replace them. If a webhook with same url exists then it will not add any new ones.

### Prerequisites

- Have Python3 installed on machine
- [Created a personal access token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) with enough permissions to list repositories, hooks and add hooks to repositories. (suggestion admin:repo_hook)
- [Authorise personal access token to use with Organisation](https://docs.github.com/en/github/authenticating-to-github/authenticating-with-saml-single-sign-on/authorizing-a-personal-access-token-for-use-with-saml-single-sign-on)

### Initialization

Create python virtual environment

```
python3 -m venv .venv
```

Activate it:

```
. .venv/bin/activate
```

Install into virtual environment

```
pip install -r requirements.txt
```

### Running the program

Following is an example of how to add a webhook to a specific repository using `--repository= ` option

```
python3 program.py --githubtoken=mytoken --owner=NandosUK --repository=fourkeys --webhookurl=https://www.example.com
```

To add a webhook secret add `--webhooksecret=mysecret ` option when running the program.

To add webhook to all the repositories that a github user or organization has, simply omit the `--repository= ` option form the command
```
python3 program.py --githubtoken=mytoken --owner=NandosUK --webhookurl=https://www.example.com
```
