local pv_rwo_1gi = import 'templates/json/pv-rwo-1gi.libsonnet';
local deploy_backend_svc = import 'templates/json/deploy-backend-svc.libsonnet';
local deploy_backend = import 'templates/json/deploy-backend.libsonnet';
local deploy_frontend_svc = import 'templates/json/deploy-frontend-svc.libsonnet';
local deploy_frontend = import 'templates/json/deploy-frontend.libsonnet';
local sts_pg_svc = import 'templates/json/sts-pg-svc.libsonnet';
local sts_pg = import 'templates/json/sts-pg.libsonnet';

local ns = std.extVar("namespace");

{
  apiVersion: 'v1',
  kind: "List",
  namespace: ns,
  metadata: {
    resourceVersion: ""
  },
  items: [
    pv_rwo_1gi.get(ns),
    deploy_backend_svc.get(ns),
    deploy_frontend_svc.get(ns),
    sts_pg_svc.get(ns),
    deploy_frontend.get(ns),
    deploy_backend.get(ns),
    sts_pg.get(ns),
  ]
}
