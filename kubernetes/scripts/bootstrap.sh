#!/usr/bin/env bash
# Run from the repository root:
#   op run --env-file=kubernetes/scripts/bootstrap.env -- ./kubernetes/scripts/bootstrap.sh
set -euo pipefail

# The Turing Pi cluster, not the k3d staging cluster
kubectl config use-context k3s-production
flux check --pre

flux bootstrap github \
  --owner="andrewdavidbell" \
  --repository=homelab \
  --branch=main \
  --path=kubernetes/clusters/production \
  --personal

# The one secret not in Git: ESO's 1Password token, kept beside Flux's deploy key
printf '%s' "$ESO_OP_TOKEN" \
  | kubectl -n flux-system create secret generic onepassword-sa-token \
      --from-file=token=/dev/stdin --dry-run=client -o yaml \
  | kubectl apply -f -
