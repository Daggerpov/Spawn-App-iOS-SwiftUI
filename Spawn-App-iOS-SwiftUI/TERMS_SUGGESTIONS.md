# Terms and Conditions — Suggestions & Notes

This document contains suggestions, fixes, and app-related thoughts about the Spawn Terms and Conditions. **Do not copy these into the in-app terms** unless you intentionally adopt them after legal review.

---

## 1. Placeholders / unincorporated (Section 7)

- **Section 7 — Unincorporated:** You are **not** incorporated, so do not use "Spawn, Inc." or "Spawn LLC." The in-app terms now use "the operators of Spawn." If you prefer to name individuals, you can use:
  - The **operators' names** (e.g. "Spawn is operated by [Founder A] and [Founder B]").
  - A **DBA / trade name** if you have one (e.g. "Spawn" as a trade name used by [Your Name(s)]).
  Using a company name when you are not incorporated can be misleading; the current wording keeps the terms accurate.
- **Section 5 — Privacy Policy:** The app now links to your Privacy Policy (see **Section 6** below). The URL is set in `ServiceConstants.URLs.privacyPolicy`.

---

## 2. Location (Section 6)

- The in-app terms have been aligned with your **Info.plist** usage description: location is used to show nearby activities on the map and as the initial location for new activities you create and share with friends. Ensure the **Privacy Policy** describes how location is collected, stored, and shared, and for how long.

---

## 3. Missing clauses often found in app terms

- **Governing law and venue:** e.g. "These Terms are governed by the laws of [State/Country]. Any disputes will be resolved in the courts of [jurisdiction]."
- **Arbitration / class action waiver:** If you want to require arbitration (common in US consumer apps), add a clear arbitration clause and, where applicable, class action waiver, and ensure it's consistent with the rest of the Terms.
- **Severability:** If one provision is invalid, the rest remain in effect.
- **Entire agreement:** These Terms (together with the Privacy Policy) constitute the entire agreement between the user and Spawn regarding the App.

---

## 4. Limitation of liability (Section 8)

- Section 8 is brief. Many apps add:
  - A **cap on liability** (e.g. the amount paid to Spawn in the past 12 months, or a fixed sum).
  - Clarification that Spawn is not liable for **user conduct**, **third-party services**, or **location inaccuracy**.
- **Jurisdiction-dependent:** Some countries do not allow certain liability exclusions; consider a carve-out (e.g. "Some jurisdictions do not allow …; in those jurisdictions our liability is limited to the maximum permitted by law").

---

## 5. Changes to terms (Section 11)

- Consider specifying **how** you'll notify users of material changes (e.g. in-app notice, email, or push) and **when** the new terms take effect (e.g. 30 days after notice).
- For material changes, some apps require **re-acceptance** (e.g. checkbox or "I agree" after the next app update). Your onboarding already has acceptance; you could mirror that for major updates.

---

## 6. App-specific implementation notes

- **In-app:** Terms are shown in **TermsAndConditionsView** and linked from the onboarding "Terms" link and from **Settings → Legal → Terms and Conditions**. The Privacy Policy is linked from **Settings → Legal → Privacy Policy** and from the terms (Section 5); the app opens the URL defined in `ServiceConstants.URLs.privacyPolicy` (your Flycricket-hosted policy).
- **Acceptance:** Users accept by checking the box and continuing on the **UserToS** screen; consider logging acceptance (user id + timestamp + terms version) for compliance and dispute purposes.

---

*This file is for internal use only. Have a lawyer review the final Terms and Privacy Policy before release.*
