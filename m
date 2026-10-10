From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH v2 0/3] cmd: button: add live monitor subcommand
Date: Sat, 10 Oct 2026 14:27:51 +0200
Message-Id: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQ6CMBAFf4X07BpaSEFP/ofhQMsia6AlbWk0h
 H+3YDx6nGTem5V5dISeXbOVOYzkyZoE4pQxPbTmgUBdYiZyIXmeC1AlqCUEa2CkiDBZQ8E6qCs
 lqq6WpVaSpfHssKfXcXxvvuwX9UQd9rfdGMin4fsoR757v0jxLxI5cJCtuBQlVrxX3W12NllTS
 +NZ24k127Z9AKw53gnTAAAA
X-Change-ID: 20261002-b4-button-live-monitor-87b27d864cb6
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791635298; l=1306;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=1LQfVsgm+hZoA03oCSkgKiJqmrPzLuZNQnEW6UVJDQI=;
 b=Fa8ytRsn5eG5DTfk9a2STDCDwb7ezzL/5qH+PQkkc/tB7SuYwxGh9LsUUsDRNX8P5iNPjKDVh
 2VKoV6EOZUhDimWWe4ebo+Yjk3mMNAvBqftZQmhei6ddZ7gQqmyIIHP
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'button list' only prints state once and exits so verifying a
button mapping on a mobile device is not practical. Therefore 
the new subcommand loops the input states and prints it live.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Changes in v2:
- Add Ctrl-C handling. Timeout of 0 now runs until Ctrl-C
- Use ANSI_* macros from ansi.h and plain \n instead of raw escapes
- Share state printing with "button list" (on/off/<inactive>/Error N)
  and probe all buttons once before the loop
- Match "monitor" with strcmp() and reject an invalid timeout
- Add documentation and sandbox tests
- Link to v1: https://patch.msgid.link/20261003-b4-button-live-monitor-v1-1-6a2934e71fbd@protonmail.com

---
Petr Hodina (3):
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

