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

{{/* The backend image declares USER isms by name; runAsNonRoot needs the
numeric IDs (isms is uid 1001, group nodejs gid 1001 in the Dockerfile). */}}
{{- define "cloudanzen.backendUser" -}}
runAsUser: 1001
runAsGroup: 1001
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
- name: DATABASE_TLS
  value: {{ .Values.database.tls | quote }}
{{- if eq .Values.database.tls "verify-full" }}
- name: DATABASE_CA_CERT_PATH
  value: /etc/cloudanzen/db-ca/ca.crt
{{- end }}
{{- end -}}

{{/* Database CA volume and mount. Only the public CA certificate is
projected; the CA key in the same Secret is not mounted. */}}
{{- define "cloudanzen.dbCaVolumeMounts" -}}
{{- if eq .Values.database.tls "verify-full" }}
volumeMounts:
  - name: db-ca
    mountPath: /etc/cloudanzen/db-ca
    readOnly: true
{{- end }}
{{- end -}}

{{- define "cloudanzen.dbCaVolumes" -}}
{{- if eq .Values.database.tls "verify-full" }}
volumes:
  - name: db-ca
    secret:
      secretName: {{ required "database.caSecret is required for verify-full" .Values.database.caSecret }}
      items:
        - key: ca.crt
          path: ca.crt
{{- end }}
{{- end -}}
