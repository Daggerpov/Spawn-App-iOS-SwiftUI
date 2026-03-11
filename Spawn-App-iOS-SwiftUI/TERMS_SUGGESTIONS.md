# Terms and Conditions — Suggestions & Notes

This document contains suggestions, fixes, and app-related thoughts about the Spawn Terms and Conditions. **Do not copy these into the in-app terms** unless you intentionally adopt them after legal review.

---

## 1. Placeholders to fix in the actual terms

- **Section 7 — [Company Name]:** Replace with your legal entity name (e.g. “Spawn, Inc.” or “Spawn LLC”). Using a placeholder in live terms can create enforceability and clarity issues.
- **Section 5 — “Include link to Privacy Policy”:** This is instruction text, not user-facing wording. Replace with either:
  - A direct link (e.g. “View our Privacy Policy at [URL]”), or  
  - “Our Privacy Policy is available in the app under Settings → Legal → Privacy Policy and at [URL].”

---

## 2. Date

- **“March 2nd 2025”:** Confirm whether this is the intended effective date. If the terms go live in 2026, update the date to avoid confusion and to match your records.

---

## 3. Age & parental consent (Section 2)

- **13+ and under-18 consent:** Align with **COPPA** (US) and any similar rules in your target countries. If you actually allow under-13 users, you’ll need stricter parental consent and data handling; many apps set a minimum of 13 and treat 13–17 as “minor with consent.”
- Consider explicitly stating that **parents/guardians** of users under 18 agree to these Terms on the minor’s behalf and are responsible for the minor’s use.

---

## 4. Location (Section 6)

- The app relies on **real-time location**. Consider adding:
  - That location is used to show activities and presence to friends (and any other uses).
  - That users can control sharing via in-app privacy/location settings.
  - That turning off location may limit certain features (e.g. seeing or joining nearby activities).
- Ensure the **Privacy Policy** describes exactly how location is collected, stored, and shared, and for how long.

---

## 5. Activities and user content

- **Section 4** covers “activities” and “content” at a high level. You may want to clarify:
  - Who owns **user-created content** (e.g. activity descriptions, photos): e.g. user retains ownership but grants Spawn a license to operate the service.
  - That **activity locations and times** may be visible to invited friends (and possibly others, depending on product).
- If users can report or block others, a short reference to **community standards / reporting** can reinforce Section 4 and Section 10.

---

## 6. Missing clauses often found in app terms

- **Governing law and venue:** e.g. “These Terms are governed by the laws of [State/Country]. Any disputes will be resolved in the courts of [jurisdiction].”
- **Arbitration / class action waiver:** If you want to require arbitration (common in US consumer apps), add a clear arbitration clause and, where applicable, class action waiver, and ensure it’s consistent with the rest of the Terms.
- **Severability:** If one provision is invalid, the rest remain in effect.
- **Entire agreement:** These Terms (together with the Privacy Policy) constitute the entire agreement between the user and Spawn regarding the App.

---

## 7. Limitation of liability (Section 8)

- Section 8 is brief. Many apps add:
  - A **cap on liability** (e.g. the amount paid to Spawn in the past 12 months, or a fixed sum).
  - Clarification that Spawn is not liable for **user conduct**, **third-party services**, or **location inaccuracy**.
- **Jurisdiction-dependent:** Some countries do not allow certain liability exclusions; consider a carve-out (e.g. “Some jurisdictions do not allow …; in those jurisdictions our liability is limited to the maximum permitted by law”).

---

## 8. Changes to terms (Section 11)

- Consider specifying **how** you’ll notify users of material changes (e.g. in-app notice, email, or push) and **when** the new terms take effect (e.g. 30 days after notice).
- For material changes, some apps require **re-acceptance** (e.g. checkbox or “I agree” after the next app update). Your onboarding already has acceptance; you could mirror that for major updates.

---

## 9. Contact (Section 12)

- **spawnappmarketing@gmail.com** is listed for “questions about these Terms.” Consider:
  - A dedicated **legal/support** address for terms and privacy (e.g. legal@ or support@) so these requests aren’t mixed only with marketing.
  - Stating a **reasonable response time** (e.g. “We aim to respond within X business days”) to set expectations.

---

## 10. App-specific implementation notes

- **In-app:** Terms are shown in **TermsAndConditionsView** and linked from the onboarding “Terms” link and from **Settings → Legal → Terms and Conditions**. Privacy Policy is currently a placeholder (Settings → Legal → Privacy Policy); once you have a URL or in-app version, replace the placeholder and, in the terms text, replace “Include link to Privacy Policy” with the actual link or reference.
- **Acceptance:** Users accept by checking the box and continuing on the **UserToS** screen; consider logging acceptance (user id + timestamp + terms version) for compliance and dispute purposes.

---

*This file is for internal use only. Have a lawyer review the final Terms and Privacy Policy before release.*
