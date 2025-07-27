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
{{- $appId := index . 2 | default "" -}}
{{- $env := index . 1 -}}
{{- $envSuffix := include "namespace.getEnvSuffix" $env -}}
{{- if $appConfig.snowAppId -}}
{{ printf "%s-%s" (lower $appConfig.snowAppId) $envSuffix }}
{{- else -}}
{{ printf "%s-%s" (lower $appId) $envSuffix }}
{{- end -}}
{{- end -}}
