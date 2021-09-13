
### About

Simple python program to add webhook to the github repo(s) triggered on all events.

### Prerequisites

- have python3 installed on machine
- have generated github access token with enough permissions to list repositories, hooks and add hooks to repositories. (admin:repo_hook)
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
This is an example of how to run it.
npm
  ```sh
  python3 program.py --githubtoken=mytoken --owner=NandosUK --repository=fourkeys --webhookurl=https://www.dora.nandos.dev
  ```
To add webhook to a specific repo use ```--repository= ``` flag.

To add a webhook secret use ```--webhooksecret= ``` flag
