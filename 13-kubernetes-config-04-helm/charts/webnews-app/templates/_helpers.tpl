{{/*
Returns value for namespace.
*/}}
{{- define "ns" -}}
{{- default .Release.Namespace .Values.currentNamespace }}
{{- end }}

{{/*
Returns version number for certain namespace name.
*/}}
{{- define "version-for-ns" -}}
{{- if contains "app1" .Release.Namespace }}
{{- "1.1.3" }}
{{- else if contains "app2" .Release.Namespace }}
{{- "1.1.4" }}
{{- else }}
{{- "1.1.2" }}
{{- end }}
{{- end }}

{{/*
Returns frontend port number for certain namespace name.
*/}}
{{- define "frontend-port-for-ns" -}}
{{- if contains "app1" .Release.Namespace }}
{{- "30000" }}
{{- else if contains "app2" .Release.Namespace }}
{{- "30100" }}
{{- else }}
{{- "30000" }}
{{- end }}
{{- end }}

{{/*
Returns backend port number for certain namespace name.
*/}}
{{- define "backend-port-for-ns" -}}
{{- if contains "app1" .Release.Namespace }}
{{- "30001" }}
{{- else if contains "app2" .Release.Namespace }}
{{- "30101" }}
{{- else }}
{{- "30001" }}
{{- end }}
{{- end }}

{{/*
Returns database port number for certain namespace name.
*/}}
{{- define "database-port-for-ns" -}}
{{- if contains "app1" .Release.Namespace }}
{{- "30002" }}
{{- else if contains "app2" .Release.Namespace }}
{{- "30102" }}
{{- else }}
{{- "30002" }}
{{- end }}
{{- end }}

{{- define "magda.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "webnews-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "webnews-app.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "webnews-app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "webnews-app.labels" -}}
helm.sh/chart: {{ include "webnews-app.chart" . }}
{{ include "webnews-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "webnews-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "webnews-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
