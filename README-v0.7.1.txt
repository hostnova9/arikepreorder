ArikePreorder v0.7.1 - Auth Experience

Changes:
- Redesigned Login, Register, Forgot Password and Reset Password as one consistent auth experience.
- Preserved the branded side-panel copy and restyled it around Protected Orders, Help Pay My Cart and Shop Nearby.
- Registration is now a compact 3-step flow: Account -> Location -> Security.
- Added password confirmation and a clear post-registration route to Login.
- Dashboard remains protected by the registered-account JWT flow.
- Added a session-check screen so protected dashboard content does not flash before authentication is confirmed.
- Existing v0.7 marketplace, cart, Help Pay, geographic discovery and database features remain intact.

Keep your existing backend/.env when replacing the project.
