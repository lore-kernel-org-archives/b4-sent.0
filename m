From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 14:27:53 +0200
Subject: [PATCH v2 2/3] doc: button: document monitor subcommand
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-button-live-monitor-v2-2-004f47a4a7b1@protonmail.com>
References: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
In-Reply-To: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791635298; l=1710;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=V1QHc3j+E+u6j39lWYuquKXtDVoLT3DspVc7Br8oKdQ=;
 b=el7dK8xFlZBrZucJ96yK0qIkvmxaiEEJkKUB8dGoqMr8BBO6jMTO5kQUuiSaNWIypi975G86K
 Byj5Vd3jAcXBRXn22A9qS+95x0/q5TC8Uz6X/pF6fJjJCeXrEwcnSiT
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the monitor subcommand to the synopsis, description and return
value table of the button command page.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 doc/usage/cmd/button.rst | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/doc/usage/cmd/button.rst b/doc/usage/cmd/button.rst
index 6c6794f31b8..49bc373b5d3 100644
--- a/doc/usage/cmd/button.rst
+++ b/doc/usage/cmd/button.rst
@@ -12,6 +12,7 @@ Synopsis
 ::
 
     button list
+    button monitor [timeout_ms]
     button <name>
 
 Description
@@ -43,6 +44,19 @@ A list of all available buttons and their status can be displayed using
 If a button device has not been probed yet, its status will be shown as
 *<inactive>* in the list.
 
+To watch the buttons live, for example to verify wiring on a device, use
+
+::
+
+    button monitor [timeout_ms]
+
+This probes all buttons, clears the screen and shows a table of their status
+in the same format as *button list* (*on*, *off*, *<inactive>* if probing failed,
+or an error code), refreshed every 100ms together with the remaining time. The
+command exits when *timeout_ms* milliseconds have elapsed or when Ctrl-C is
+pressed. The default is 5000ms. A *timeout_ms* of 0 means to run until Ctrl-C
+is pressed.
+
 Configuration
 -------------
 
@@ -61,6 +75,8 @@ The variable *$?* takes the following values
 +---+-----------------------------+
 | 0 | button list was shown       |
 +---+-----------------------------+
+| 0 | button monitor ended        |
++---+-----------------------------+
 | 1 | button not found            |
 +---+-----------------------------+
 | 1 | invalid arguments           |

-- 
2.55.0

