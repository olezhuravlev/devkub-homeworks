// this file has the param overrides for the default environment
local base = import './base.libsonnet';

{
  ns: 'default',
  backend: {
    replicas: 1,
  },
  frontend: {
    replicas: 1,
  }
}
