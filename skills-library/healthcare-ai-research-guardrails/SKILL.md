---
name: healthcare-ai-research-guardrails
description: Use this skill when researching, drafting, reviewing, or building healthcare, wellness, clinical, medical-device, patient-support, health-content, or health-data AI workflows that require source quality, privacy, non-diagnostic boundaries, human review, and regulated-domain guardrails.
---

# Healthcare AI Research Guardrails

Support healthcare work with evidence handling and safety boundaries; do not act as a clinician or medical-device authority.

## Workflow

1. Classify the task: general health content, patient education, clinical workflow support, medical-device/software concern, privacy/data handling, or operational healthcare tooling.
2. Identify the audience and risk level: consumer, patient, caregiver, clinician, admin staff, developer, regulator, or internal reviewer.
3. Prefer primary and authoritative sources: official regulators, public-health bodies, clinical guidelines, peer-reviewed evidence, and product documentation.
4. Separate facts, assumptions, uncertainty, and user-specific advice. Avoid diagnosis, treatment selection, medication changes, or emergency triage decisions.
5. Check privacy boundaries before using any health data: minimum necessary data, consent, de-identification, retention, access controls, audit logs, and local policy.
6. For AI workflows, define human review, escalation, fallback, disclaimers, model limitations, source citations, and post-deployment monitoring.
7. For medical-device-adjacent functionality, flag that regulatory review may be required before claims, deployment, or user-facing decisions.
8. Deliver a concise risk review with sources checked, unresolved evidence gaps, required human owner, and safe next step.

## Checklist

- Include emergency and urgent-care escalation language when user harm could result from delay.
- Cite current sources for medical, regulatory, or public-health claims.
- Avoid personalized medical advice unless the user has explicitly provided clinician-approved context and the output remains drafting/support.
- Validate accessibility and plain-language readability for patient-facing content.
- Log neither PHI nor sensitive health details unless the system is explicitly designed and approved for that purpose.
- Treat model outputs as suggestions for qualified humans, not final clinical decisions.

## Guardrails

- Do not diagnose, prescribe, interpret test results for a patient, or recommend changing treatment.
- Do not claim HIPAA, FDA, CE, or other compliance status without legal/regulatory evidence.
- Do not process or expose protected health information outside approved systems.
- Do not present AI-generated healthcare output as clinician-reviewed unless it actually was.
