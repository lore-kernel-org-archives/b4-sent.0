From: Yang Li <yang.li@amlogic.com>
Date: Fri, 19 Dec 2025 10:43:09 +0800
Subject: [PATCH] Bluetooth: hci_sync: enable PA Sync Lost event
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251219-enable_pa_sync_lost_mask-v1-1-2769917f44e2@amlogic.com>
X-B4-Tracking: v=1; b=H4sIALy7RGkC/x3M0QpAQBBA0V/RPNuyK4lfkbbBLBOWdiSSf7d5P
 A/3PiAUmATq5IFAJwtvPkKnCfQT+pEUD9FgMlNooytFHruF7I5Wbt/bZZPDriizQspcV2pnKpd
 DzPdAjq9/3bTv+wG7aJ25agAAAA==
To: Marcel Holtmann <marcel@holtmann.org>, 
 Johan Hedberg <johan.hedberg@gmail.com>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-bluetooth@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766112194; l=1054;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=mCqnwsr5XyKCQ0CWzmE6bWicYgYAfb+tL3ko7n9wlUE=;
 b=iYSjVjzKtKXOsG1Ob0xTT9T561e6gq+W4bQ6pqyS8LJoh84P282BunWYMPj+Zu5NbGHh0Fl8o
 ZHkrfVHF3zfBYSdr+lBZa43PYmMrFuoIhanx4fnjN1c/lvlZCTwP5Q6
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the PA Sync Lost event mask to ensure
PA sync loss is properly reported and handled.

Fixes 59e5396a2579 ("Bluetooth: hci_event: Fix not handling PA Sync Lost event")

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 net/bluetooth/hci_sync.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/bluetooth/hci_sync.c b/net/bluetooth/hci_sync.c
index 5de98be752bc..3f04510b806b 100644
--- a/net/bluetooth/hci_sync.c
+++ b/net/bluetooth/hci_sync.c
@@ -4420,6 +4420,7 @@ static int hci_le_set_event_mask_sync(struct hci_dev *hdev)
 	if (bis_capable(hdev)) {
 		events[1] |= 0x20;	/* LE PA Report */
 		events[1] |= 0x40;	/* LE PA Sync Established */
+		events[1] |= 0x80;	/* LE PA Sync Lost */
 		events[3] |= 0x04;	/* LE Create BIG Complete */
 		events[3] |= 0x08;	/* LE Terminate BIG Complete */
 		events[3] |= 0x10;	/* LE BIG Sync Established */

---
base-commit: 98246938a0e66e4100e95b6b7881843a9a4e4882
change-id: 20251219-enable_pa_sync_lost_mask-ae0fb71f29f3

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

