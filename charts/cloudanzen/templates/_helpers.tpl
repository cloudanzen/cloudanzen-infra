{{/* Resource name prefix; one release per namespace. */}}
{{- define "cloudanzen.name" -}}cloudanzen{{- end -}}

{{- define "cloudanzen.labels" -}}
app.kubernetes.io/name: cloudanzen
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: cloudanzen
app.kubernetes.io/managed-by: {{ .Release.Service }}
cloudanzen.io/environment: {{ .Values.environment }}
{{- end -}}

{{- define "cloudanzen.selector" -}}
app.kubernetes.io/name: cloudanzen
app.kubernetes.io/instance: {{ .root.Release.Name }}
app.kubernetes.io/component: {{ .component }}
{{- end -}}

{{/* registry/image@sha256:... */}}
{{- define "cloudanzen.image" -}}
{{ .root.Values.images.registry }}/{{ .name }}@{{ .digest }}
{{- end -}}

{{/* Hostname of an https URL. */}}
{{- define "cloudanzen.host" -}}
{{ trimPrefix "https://" . }}
{{- end -}}

{{- define "cloudanzen.podSecurityContext" -}}
runAsNonRoot: true
seccompProfile:
  type: RuntimeDefault
{{- end -}}

{{- define "cloudanzen.containerSecurityContext" -}}
allowPrivilegeEscalation: false
capabilities:
  drop: ["ALL"]
{{- end -}}

{{/* Environment shared by the API and worker (same image and configuration). */}}
{{- define "cloudanzen.backendEnvFrom" -}}
- configMapRef:
    name: {{ include "cloudanzen.name" . }}-backend-env
- secretRef:
    name: {{ .Values.connectionSecrets.runtime }}
{{- if .Values.backend.secretEnv }}
- secretRef:
    name: {{ include "cloudanzen.name" . }}-backend-secrets
{{- end }}
{{- end -}}

{{- define "cloudanzen.backendPodEnv" -}}
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
{{- end -}}
