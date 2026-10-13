From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH v3 0/4] cmd: button: add live monitor subcommand
Date: Tue, 13 Oct 2026 18:33:30 +0200
Message-Id: <20261013-b4-button-live-monitor-v3-0-3563b4d3ccdf@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WN0QqCMBhGX0V23R/bHM666j2ii01n/qFONh2F+
 O5tRhCElx+c75yFeOPQeHLOFuJMQI92iCM/ZKRq1XA3gHXchFNeMEo5aAF6niY7QIfBQG8HnKy
 DUmou67IQlS5IPI/ONPjcxNfbZ/tZP0w1JVsiWvTx+NrKgSXuG8n3IoEBg0LxUy6MZI2uL6Ozk
 eoVdsfK9iSVAv9xMbrr4kCBUtEIqYSSmv251nV9A0sf69MfAQAA
X-Change-ID: 20261002-b4-button-live-monitor-87b27d864cb6
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791909215; l=1856;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=kNlqtyYor5NNtuvnwIMILXGjdVWLo5F3H0Psi31EGB4=;
 b=HtsPst38Tfhl0T7FrpM5Oi/qID1j8U6SslwIFSQzLCVgn7OU12qweSKFiVvLoUrIVAJlHsClD
 Vc0Kh9csJ3sDyA7vfW8ei8d3JL5UTI+hbjua2bhYO9zgwRPPtnE3G86
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'button list' only prints the state once and exits which makes it
impractical to verify a button mapping on a mobile device.

Patch 1 moves the state printing into a shared helper.
Patch 2 adds a 'monitor' subcommand which redraws the state
of all buttons every 100ms until Ctrl-C is pressed or a timeout
expires (default 5s, 0 for none).
Patch 3 documents the new subcommand.
Patch 4 adds test for the monitor.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v3:
- Split the show_button_status() refactor out of the monitor patch
- Reword commit messages: mention Ctrl-C and the zero timeout
- Link to v2: https://patch.msgid.link/20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com

Changes in v2:
- Add Ctrl-C handling. Timeout of 0 now runs until Ctrl-C
- Use ANSI_* macros from ansi.h and plain \n instead of raw escapes
- Share state printing with "button list" (on/off/<inactive>/Error N)
  and probe all buttons once before the loop
- Match "monitor" with strcmp() and reject an invalid timeout
- Add documentation and sandbox tests
- Link to v1: https://patch.msgid.link/20261003-b4-button-live-monitor-v1-1-6a2934e71fbd@protonmail.com

---
Petr Hodina (4):
      cmd: button: factor out state printing from 'button list'
      cmd: button: add live monitor subcommand
      doc: button: document monitor subcommand
      test: button: add test for monitor subcommand

 cmd/button.c                 | 104 +++++++++++++++++++++++++++++++++++++++----
 doc/usage/cmd/button.rst     |  16 +++++++
 test/py/tests/test_button.py |  20 +++++++++
 3 files changed, 131 insertions(+), 9 deletions(-)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261002-b4-button-live-monitor-87b27d864cb6

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

