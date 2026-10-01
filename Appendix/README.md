# Pawsome — IA Appendix Structure

This appendix is designed as the supporting-evidence section for the IB Computer Science IA. It follows the structure and evidence style of the Grade 7 Clastify Interactive Meal Management System example we used as the main reference, while being adapted to Pawsome's actual features and the current IA structure.

> **Important:** Appendix evidence should support claims made in Criteria A–E. It should not replace explanation in the main IA. Only include evidence that is actually available and relevant; do not invent interviews, feedback, test results, screenshots, or dates.

---

## Appendix A — Initial Stakeholder Interview / Problem Investigation

**Purpose:** Provide primary evidence for the problem identified in Criterion A and show how the proposed solution was derived from the stakeholder's needs.

### A.1 Interview context
- Date:
- Participants:
- Stakeholder role:
- Method:
- Duration:
- Purpose of interview:

### A.2 Full interview transcript
Include the complete transcript or the school's accepted evidence format.

### A.3 Key requirements identified
| Requirement | Evidence from interview | Related success criterion |
|---|---|---|
| Lost-cat reports need to be shared with the community | [insert evidence] | SC-__ |
| Users need to create/login to accounts | [insert evidence] | SC-__ |
| Users need to create cat reports | [insert evidence] | SC-__ |
| Users need to view reports on the home feed | [insert evidence] | SC-__ |
| Users need to contact the person who found/lost a cat | [insert evidence] | SC-__ |
| Users need to manage their profile | [insert evidence] | SC-__ |

### A.4 Evidence references
Insert screenshots/photos of the original interview evidence where appropriate.

---

## Appendix B — Interim Stakeholder Feedback

**Purpose:** Demonstrate that development was reviewed during the process and that feedback affected later design/development decisions.

### B.1 Review context
- Date:
- Product version:
- Features demonstrated:
- Participants:
- Method:
- Duration:

### B.2 Full transcript / meeting evidence
Insert the complete transcript or approved evidence.

### B.3 Feedback and resulting changes
| Feedback | Decision | Resulting change | Criterion affected |
|---|---|---|---|
| [feedback] | [accepted/rejected + reason] | [change] | B/C/E |
| [feedback] | [accepted/rejected + reason] | [change] | B/C/E |
| [feedback] | [accepted/rejected + reason] | [change] | B/C/E |

### B.4 Screenshots of interim product
- Login
- Home/feed
- Cat report creation
- Cat report viewing
- Profile
- Other feature demonstrated

---

## Appendix C — Final Stakeholder Feedback and Evaluation Evidence

**Purpose:** Provide the evidence used when evaluating the finished product in Criterion E.

### C.1 Final demonstration context
- Date:
- Product version/build:
- Platform:
- Features demonstrated:
- Participants:
- Method:

### C.2 Full final feedback transcript
Insert the complete transcript or approved evidence.

### C.3 Success-criterion evidence
| Success criterion | Evidence shown to stakeholder | Stakeholder feedback | Result |
|---|---|---|---|
| SC1 | [screenshot/test] | [feedback] | [met/partially met/not met] |
| SC2 | [screenshot/test] | [feedback] | [result] |
| SC3 | [screenshot/test] | [feedback] | [result] |
| SC4 | [screenshot/test] | [feedback] | [result] |
| SC5 | [screenshot/test] | [feedback] | [result] |
| SC6 | [screenshot/test] | [feedback] | [result] |
| SC7 | [screenshot/test] | [feedback] | [result] |
| SC8 | [screenshot/test] | [feedback] | [result] |
| SC9 | [screenshot/test] | [feedback] | [result] |
| SC10 | [screenshot/test] | [feedback] | [result] |

### C.4 Improvement suggestions
Separate:
1. Minor improvements
2. Major improvements / future extensions
3. Improvements that were implemented
4. Improvements that were not implemented and why

---

## Appendix D — Product Screenshots and Demonstration Evidence

**Purpose:** Keep supporting product visuals that are referenced from Criteria B, C, D, or E.

### D.1 Authentication
- Login screen
- Google/Apple sign-in where applicable
- Invalid-input/error state
- Successful authenticated state

### D.2 Home/feed
- Main home screen
- Lost-cat report displayed on the home feed
- Found-cat report displayed on the home feed
- Like/comment interaction
- Post count/engagement state

### D.3 Cat reporting
- Create Cat Report form
- Validation states
- Image selection
- Image editing/cropping if demonstrated
- Successful submission
- Resulting report on the home feed

### D.4 Report interaction
- Lost-cat report
- Found-cat report
- "I found this cat" interaction
- Existing-chat behaviour after the button has already been used
- Chat screen
- Notification evidence, where actually available

### D.5 Profile
- Profile screen
- Profile editing
- Relevant account information
- Logout

### D.6 Administrative functionality
- Admin screen
- Admin-only controls
- Any moderation/data-management features actually demonstrated

### D.7 Cross-platform evidence
Where relevant, separate evidence for:
- iOS
- Android
- Web

---

## Appendix E — Test Evidence

**Purpose:** Preserve supporting evidence for Criterion C/D/E testing without putting the entire test process into the main IA.

### E.1 Test environment
Record only the environments actually used:
- iOS device/simulator
- Android device/emulator
- Windows/web environment
- Firebase/backend environment

### E.2 Functional test evidence
For each important test:
- Test ID
- Input/action
- Expected result
- Actual result
- Pass/fail
- Screenshot/log evidence
- Related success criterion

### E.3 Validation and error testing
Examples to document only if actually tested:
- Empty required fields
- Invalid values
- Invalid authentication
- Failed image upload
- Network/backend failure
- Duplicate interaction
- Unauthorized access
- Chat/report edge cases

### E.4 Regression testing
Document important tests repeated after major changes.

---

## Appendix F — Development / Debugging Evidence

**Purpose:** Provide supporting evidence for development decisions and problem solving when referenced in Criterion C.

### F.1 Major implementation milestones
- Authentication
- Firebase integration
- Firestore data handling
- Storage/image handling
- Cat reports
- Home feed
- Likes/comments
- Profile
- Chat
- Notifications
- Admin functionality
- Web version
- Cross-platform functionality

### F.2 Significant debugging evidence
For each major issue:
1. Problem
2. Evidence of the problem
3. Investigation
4. Change made
5. Evidence after the fix

### F.3 Before/after evidence
Use paired screenshots where a change is important enough to demonstrate development.

---

## Appendix G — Technical Supporting Evidence

**Purpose:** Store concise supporting material for technical explanations in Criterion C.

### G.1 Data model evidence
- Firestore collections
- Important document fields
- Relationships/references
- Authentication/user data structure

### G.2 Algorithms / computational processes
Include only the algorithms actually explained in Criterion C, such as:
- Searching/filtering
- Sorting
- Validation
- Conditional decision logic
- State handling
- Chat/report matching logic
- Image-processing workflow

### G.3 External services / libraries
Document relevant services actually used:
- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Firebase Cloud Messaging, if actually implemented
- Google Sign-In
- Apple Sign-In
- Firebase App Check
- Other libraries used in the final product

Do not include credentials, private keys, access tokens, API secrets, or other sensitive configuration.

---

## Appendix H — Design Evidence Archive

**Purpose:** Keep supporting design evidence referenced by Criterion B.

### H.1 Initial sketches
Insert original sketches/mockups.

### H.2 Revised designs
Show meaningful revisions rather than every tiny change.

### H.3 Final designs
Include the final design visuals that correspond to the implemented product.

### H.4 Design decision evidence
For important decisions:
- Original approach
- Problem/limitation
- Revised approach
- Reason for the change
- Effect on the final product

---

## Appendix I — Record-of-Tasks Supporting Evidence

**Purpose:** Preserve evidence that supports the development chronology in the Record of Tasks.

### I.1 Development chronology
Use the actual dates from the project history.

### I.2 GitHub evidence
Where useful, reference:
- Commit dates
- Commit messages
- Pull requests
- Major feature merges
- Bug fixes
- Release/build milestones

### I.3 Development task evidence
Link each major task to:
- Criterion
- Planned outcome
- Actual outcome
- Evidence

Do not use GitHub history as a substitute for the required Record of Tasks; use it as supporting evidence.

---

## Appendix J — Source / Attribution Evidence

### J.1 External resources
Record external resources that materially contributed to the product or research.

### J.2 Code/library attribution
Record libraries, frameworks, APIs, or adapted material that must be attributed.

### J.3 AI/tool usage evidence
If required by the school's academic-integrity rules, document relevant AI/tool assistance accurately and transparently.

---

# Appendix Index

1. **Appendix A — Initial Stakeholder Interview / Problem Investigation**
2. **Appendix B — Interim Stakeholder Feedback**
3. **Appendix C — Final Stakeholder Feedback and Evaluation Evidence**
4. **Appendix D — Product Screenshots and Demonstration Evidence**
5. **Appendix E — Test Evidence**
6. **Appendix F — Development / Debugging Evidence**
7. **Appendix G — Technical Supporting Evidence**
8. **Appendix H — Design Evidence Archive**
9. **Appendix I — Record-of-Tasks Supporting Evidence**
10. **Appendix J — Source / Attribution Evidence**

## Evidence-linking convention

Use explicit references in the main IA, for example:

- `(See Appendix A)`
- `(See Appendix B, Fig. B.2)`
- `(See Appendix C, Table C.1)`
- `(See Appendix E, Test E.4)`

Every appendix item should therefore have a stable label such as **Fig. D.3**, **Table C.1**, **Test E.4**, or **Transcript B.1**.

## Clastify-style principle

The main IA should contain the explanation and justification. The appendix should contain the supporting evidence that makes those claims verifiable. This keeps the structure similar to the Grade 7 example without copying its wording or forcing Pawsome into the example's older terminology.
