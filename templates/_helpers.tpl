{{/* Helper functions for namespace chart */}}

{{- define "namespace.getEnvSuffix" -}}
{{- $env := . -}}
{{- if eq $env "sandbox" -}}
sbox
{{- else -}}
{{ $env }}
{{- end -}}
{{- end -}}

{{/*
Generate namespace name
*/}}
{{- define "namespace.generateName" -}}
{{- $dict := . -}}
{{- $env := $dict.env -}}
{{- $root := $dict.root -}}
{{- printf "%s-%s" (lower $root.Values.snowApmId) $env | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Convert CPU value to millicores
*/}}
{{- define "convertCPUToMillicores" -}}
{{- $cpu := . -}}
{{- if kindIs "string" $cpu -}}
  {{- if hasSuffix "m" $cpu -}}
    {{- trimSuffix "m" $cpu -}}
  {{- else -}}
    {{- mul (float64 $cpu) 1000 | int -}}
  {{- end -}}
{{- else -}}
  {{- mul (float64 $cpu) 1000 | int -}}
{{- end -}}
{{- end -}}

{{/*
Convert CPU value to integer
*/}}
{{- define "convertCPUToInteger" -}}
{{- $cpu := . -}}
{{- if kindIs "string" $cpu -}}
  {{- if hasSuffix "m" $cpu -}}
    {{- div (float64 (trimSuffix "m" $cpu)) 1000 | int -}}
  {{- else -}}
    {{- int $cpu -}}
  {{- end -}}
{{- else -}}
  {{- int $cpu -}}
{{- end -}}
{{- end -}}

{{/*
Convert memory value to Gi
*/}}
{{- define "convertMemoryToGi" -}}
{{- $memory := . -}}
{{- if kindIs "string" $memory -}}
  {{- if hasSuffix "Gi" $memory -}}
    {{- trimSuffix "Gi" $memory -}}
  {{- else if hasSuffix "Mi" $memory -}}
    {{- div (float64 (trimSuffix "Mi" $memory)) 1024 -}}
  {{- else if hasSuffix "Ki" $memory -}}
    {{- div (float64 (trimSuffix "Ki" $memory)) 1048576 -}}
  {{- else -}}
    {{- div (float64 $memory) 1073741824 -}}
  {{- end -}}
{{- else -}}
  {{- $memory -}}
{{- end -}}
{{- end -}}

{{/*
Convert memory value to Mi
*/}}
{{- define "convertMemoryToMi" -}}
{{- $memory := . -}}
{{- if kindIs "string" $memory -}}
  {{- if hasSuffix "Gi" $memory -}}
    {{- mul (float64 (trimSuffix "Gi" $memory)) 1024 | int -}}
  {{- else if hasSuffix "Mi" $memory -}}
    {{- trimSuffix "Mi" $memory -}}
  {{- else if hasSuffix "Ki" $memory -}}
    {{- div (float64 (trimSuffix "Ki" $memory)) 1024 | int -}}
  {{- else -}}
    {{- div (float64 $memory) 1048576 | int -}}
  {{- end -}}
{{- else -}}
  {{- mul (float64 $memory) 1024 | int -}}
{{- end -}}
{{- end -}}

{{/*
Validate and apply resource quota limits
*/}}
{{- define "validateResourceQuota" -}}
{{- $quota := . -}}
hard:
  {{- if hasKey $quota "hard" }}
  {{- if hasKey $quota.hard "limits.cpu" }}
  limits.cpu: {{ min (int (get $quota.hard "limits.cpu")) 100 | max 50 | quote }}
  {{- else }}
  limits.cpu: "50"
  {{- end }}
  {{- if hasKey $quota.hard "limits.memory" }}
  {{- $memValue := get $quota.hard "limits.memory" | toString }}
  {{- $memNumber := regexReplaceAll "Gi$" $memValue "" | int }}
  limits.memory: {{ min $memNumber 200 | max 100 }}Gi
  {{- else }}
  limits.memory: 100Gi
  {{- end }}
  {{- if hasKey $quota.hard "requests.cpu" }}
  requests.cpu: {{ min (int (get $quota.hard "requests.cpu")) 100 | max 50 | quote }}
  {{- else }}
  requests.cpu: "50"
  {{- end }}
  {{- if hasKey $quota.hard "requests.memory" }}
  {{- $memValue := get $quota.hard "requests.memory" | toString }}
  {{- $memNumber := regexReplaceAll "Gi$" $memValue "" | int }}
  requests.memory: {{ min $memNumber 200 | max 100 }}Gi
  {{- else }}
  requests.memory: 100Gi
  {{- end }}
  {{- if hasKey $quota.hard "pods" }}
  pods: {{ min (int (get $quota.hard "pods")) 100 | quote }}
  {{- else }}
  pods: "30"
  {{- end }}
  {{- else }}
  limits.cpu: "50"
  limits.memory: 100Gi
  requests.cpu: "50"
  requests.memory: 100Gi
  pods: "30"
  {{- end }}
{{- end -}}

{{/*
Validate and apply limit range limits
*/}}
{{- define "validateLimitRange" -}}
{{- $limitRange := . -}}
limits:
- type: Container
  default:
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "default") (hasKey (index $limitRange.limits 0).default "cpu") }}
    {{- $cpuValue := (index $limitRange.limits 0).default.cpu | toString }}
    {{- if hasSuffix "m" $cpuValue }}
    {{- $cpuNumber := trimSuffix "m" $cpuValue | int }}
    cpu: {{ min $cpuNumber 8000 | max 50 }}m
    {{- else }}
    {{- $cpuNumber := mul (float64 $cpuValue) 1000 | int }}
    cpu: {{ min $cpuNumber 8000 | max 50 }}m
    {{- end }}
    {{- else }}
    cpu: 50m
    {{- end }}
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "default") (hasKey (index $limitRange.limits 0).default "memory") }}
    {{- $memValue := (index $limitRange.limits 0).default.memory | toString }}
    {{- if hasSuffix "Gi" $memValue }}
    {{- $memNumber := trimSuffix "Gi" $memValue | float64 }}
    memory: {{ min $memNumber 16 | max 0.5 }}Gi
    {{- else if hasSuffix "Mi" $memValue }}
    {{- $memNumber := div (trimSuffix "Mi" $memValue | float64) 1024 }}
    memory: {{ min $memNumber 16 | max 0.5 }}Gi
    {{- else }}
    memory: 0.5Gi
    {{- end }}
    {{- else }}
    memory: 0.5Gi
    {{- end }}
  defaultRequest:
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "defaultRequest") (hasKey (index $limitRange.limits 0).defaultRequest "cpu") }}
    {{- $cpuValue := (index $limitRange.limits 0).defaultRequest.cpu | toString }}
    {{- if hasSuffix "m" $cpuValue }}
    {{- $cpuNumber := trimSuffix "m" $cpuValue | int }}
    cpu: {{ min $cpuNumber 8000 | max 50 }}m
    {{- else }}
    {{- $cpuNumber := mul (float64 $cpuValue) 1000 | int }}
    cpu: {{ min $cpuNumber 8000 | max 50 }}m
    {{- end }}
    {{- else }}
    cpu: 50m
    {{- end }}
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "defaultRequest") (hasKey (index $limitRange.limits 0).defaultRequest "memory") }}
    {{- $memValue := (index $limitRange.limits 0).defaultRequest.memory | toString }}
    {{- if hasSuffix "Gi" $memValue }}
    {{- $memNumber := trimSuffix "Gi" $memValue | float64 }}
    memory: {{ min $memNumber 16 | max 0.5 }}Gi
    {{- else if hasSuffix "Mi" $memValue }}
    {{- $memNumber := div (trimSuffix "Mi" $memValue | float64) 1024 }}
    memory: {{ min $memNumber 16 | max 0.5 }}Gi
    {{- else }}
    memory: 0.5Gi
    {{- end }}
    {{- else }}
    memory: 0.5Gi
    {{- end }}
  max:
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "max") (hasKey (index $limitRange.limits 0).max "cpu") }}
    {{- $cpuValue := (index $limitRange.limits 0).max.cpu | toString }}
    {{- if hasSuffix "m" $cpuValue }}
    {{- $cpuNumber := div (trimSuffix "m" $cpuValue | float64) 1000 }}
    cpu: {{ min $cpuNumber 8 }}
    {{- else }}
    cpu: {{ min (float64 $cpuValue) 8 }}
    {{- end }}
    {{- else }}
    cpu: 8
    {{- end }}
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "max") (hasKey (index $limitRange.limits 0).max "memory") }}
    {{- $memValue := (index $limitRange.limits 0).max.memory | toString }}
    {{- if hasSuffix "Gi" $memValue }}
    {{- $memNumber := trimSuffix "Gi" $memValue | float64 }}
    memory: {{ min $memNumber 16 }}Gi
    {{- else if hasSuffix "Mi" $memValue }}
    {{- $memNumber := div (trimSuffix "Mi" $memValue | float64) 1024 }}
    memory: {{ min $memNumber 16 }}Gi
    {{- else }}
    memory: 16Gi
    {{- end }}
    {{- else }}
    memory: 16Gi
    {{- end }}
  min:
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "min") (hasKey (index $limitRange.limits 0).min "cpu") }}
    {{- $cpuValue := (index $limitRange.limits 0).min.cpu | toString }}
    {{- if hasSuffix "m" $cpuValue }}
    {{- $cpuNumber := trimSuffix "m" $cpuValue | int }}
    cpu: {{ max $cpuNumber 50 }}m
    {{- else }}
    {{- $cpuNumber := mul (float64 $cpuValue) 1000 | int }}
    cpu: {{ max $cpuNumber 50 }}m
    {{- end }}
    {{- else }}
    cpu: 50m
    {{- end }}
    {{- if and (hasKey $limitRange "limits") (gt (len $limitRange.limits) 0) (hasKey (index $limitRange.limits 0) "min") (hasKey (index $limitRange.limits 0).min "memory") }}
    {{- $memValue := (index $limitRange.limits 0).min.memory | toString }}
    {{- if hasSuffix "Mi" $memValue }}
    {{- $memNumber := trimSuffix "Mi" $memValue | int }}
    memory: {{ max $memNumber 10 }}Mi
    {{- else if hasSuffix "Gi" $memValue }}
    {{- $memNumber := mul (trimSuffix "Gi" $memValue | float64) 1024 | int }}
    memory: {{ max $memNumber 10 }}Mi
    {{- else }}
    memory: 10Mi
    {{- end }}
    {{- else }}
    memory: 10Mi
    {{- end }}
{{- end -}}

{{/*
Determine if an environment should be deployed based on clusterEnv setting
*/}}
{{- define "shouldDeployEnvironment" -}}
{{- $env := .env -}}
{{- $clusterEnv := .clusterEnv | default "all" -}}

{{- if eq $clusterEnv "all" -}}
  {{- true -}}
{{- else if eq $clusterEnv "non-prod" -}}
  {{- if ne $env "prod" -}}
    {{- true -}}
  {{- else -}}
    {{- false -}}
  {{- end -}}
{{- else if eq $clusterEnv "prod" -}}
  {{- if eq $env "prod" -}}
    {{- true -}}
  {{- else -}}
    {{- false -}}
  {{- end -}}
{{- else if eq $clusterEnv "dev" -}}
  {{- if or (eq $env "dev") (eq $env "sbox") -}}
    {{- true -}}
  {{- else -}}
    {{- false -}}
  {{- end -}}
{{- else if eq $clusterEnv "test" -}}
  {{- if eq $env "test" -}}
    {{- true -}}
  {{- else -}}
    {{- false -}}
  {{- end -}}
{{- else -}}
  {{- true -}}
{{- end -}}
{{- end -}}
