apiVersion: cloud-build-notifiers/v1
kind: HTTPNotifier
metadata:
  name: cloudbuild-http-notifier-for-${name}
spec:
  notification:
    filter: ${filter}
    delivery:
      url: ${url}
