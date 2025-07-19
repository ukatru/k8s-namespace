{{/* Helper functions for namespace chart */}}

{{- define "namespace.getEnvSuffix" -}}
{{- $env := . -}}
{{- if eq $env "sandbox" -}}
sbox
{{- else -}}
{{ $env }}
{{- end -}}
{{- end -}}

{{- define "namespace.generateName" -}}
{{- $appConfig := index . 0 -}}
{{- $env := index . 1 -}}
{{- $envSuffix := include "namespace.getEnvSuffix" $env -}}
{{ printf "%s-%s" (lower $appConfig.snowAppId) $envSuffix }}
{{- end -}}
