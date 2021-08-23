apiVersion: cloud-build-notifiers/v1
kind: HTTPNotifier
metadata:
  name: cloudbuild-http-notifier
spec:
  notification:
    filter: ${filter}
    delivery:
      # The `http(s)://` protocol prefix is required.
      url: ${url}
