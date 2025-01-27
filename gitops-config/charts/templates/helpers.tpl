{{/*
Expand the name of the chart.
*/}}
{{- define "phonebook.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "phonebook.labels" -}}
helm.sh/chart: {{ include "phonebook.name" . }}
app.kubernetes.io/name: {{ include "phonebook.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}