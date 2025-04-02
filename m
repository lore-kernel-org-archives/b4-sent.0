From: Yang Li <yang.li@amlogic.com>
Date: Wed, 02 Apr 2025 15:32:54 +0800
Subject: [PATCH BlueZ bluez] bass: Clear the temporary flag of the BIS
 source device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-bass-v1-1-3e753841faa5@amlogic.com>
X-B4-Tracking: v=1; b=H4sIACXo7GcC/x3M0QpAQBBA0V/RPNsaG6v8ijzsMJjS0k4k2n+3e
 Tx1uy8oR2GFrngh8iUqe8ioygLG1YeFjUzZYNE2WKM15FWNcxaRqGXyFeT0iDzL/W96oO3kB4a
 UPh8Hc5hdAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1743579174; l=922;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=QSfYmm2mgc8SYKsTlpsDr1wat08xLba+iuzY6AJMKU4=;
 b=7xWSjt34nTUaIld//3ahEY+YUCh57SaFo1rGnPpwGz6tKjU/LntePK0pJglWX7MCiUjDfKGjL
 YstMXAXn4ZQB3BdXtYndBpAtOXUfbsSvc8CAjZKXObIC2+YvLvoJhsI
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When BIG sync succeeds, remove the temporary timer. Otherwise,
the device will timeout and be removed, triggering the automatic
termination of BIG.

issue: https://github.com/bluez/bluez/issues/1144

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 profiles/audio/bass.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/profiles/audio/bass.c b/profiles/audio/bass.c
index c36f43277..99f1decce 100644
--- a/profiles/audio/bass.c
+++ b/profiles/audio/bass.c
@@ -565,6 +565,9 @@ static void confirm_cb(GIOChannel *io, void *user_data)
 	g_io_channel_ref(io);
 	dg->io = io;
 
+	/* Clear temporary flag*/
+	btd_device_set_temporary(dg->device, false);
+
 	/* Update Broadcast Receive State characteristic value and notify
 	 * peers.
 	 */

---
base-commit: 6d20a300642f312290af0bc9869a0e1b416c58dc
change-id: 20250402-bass-66200bb7eba1

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

