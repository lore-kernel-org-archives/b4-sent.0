From: Yang Li <yang.li@amlogic.com>
Date: Wed, 21 Jan 2026 10:13:09 +0800
Subject: [PATCH BlueZ bluez v2] bap: reduce ISO sync timeout to 3.6 secs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260121-iso_sync_timeout-v2-1-efa52fdba244@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADQ2cGkC/3WNQQ6DIBREr2L+ujQCbaNd9R6NMRY/+hORBpDUG
 u5ewr6ryZvJzBzg0RF6uFcHOIzkya4ZxKkCNQ/rhIzGzCBqcas5F4y87f2+qj6QQbsF1qBEpS9
 ybARCrr0davqUySe8lg2/0GV7Jh+s28tR5CX8vxk546wdJLatuGbVj8EsdiJ1VtZAl1L6AeQDW
 2G5AAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768961593; l=1152;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=1u27ix1kl7OQvyW8a2HLNDg5ot2OEQvP578EPXDjjL0=;
 b=ZimwYJ4/Mrcqvzo5MZA/Dr6vwctNQVs+AZ+jYiGlXXcfLvrL+JQ1eis031pvL9i7qrFRgd1bA
 hM73pFh8z/GAwI+DApubk7WQ0n2mw1j8Fn/WgtYor2Lx6apJJPOwxfF
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ISO sync timeout was previously set to 20 seconds,
which is too long for PA sync. This could leave the userspace
flow pending for an extended period of time.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
Changes in v2:
- Modified the BT_ISO_SYNC_TIMEOUT to 0x0168 (3.6 secs)
- Link to v1: https://patch.msgid.link/20260112-iso_sync_timeout-v1-1-9a3e99259a3f@amlogic.com
---
 lib/bluetooth/bluetooth.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/bluetooth/bluetooth.h b/lib/bluetooth/bluetooth.h
index f9f22c3f7..b9ea34847 100644
--- a/lib/bluetooth/bluetooth.h
+++ b/lib/bluetooth/bluetooth.h
@@ -152,7 +152,7 @@ struct bt_voice {
 #define BT_ISO_QOS_BIG_UNSET	0xff
 #define BT_ISO_QOS_BIS_UNSET	0xff
 
-#define BT_ISO_SYNC_TIMEOUT	0x07d0 /* 20 secs */
+#define BT_ISO_SYNC_TIMEOUT	0x0168 /* 3.6 secs */
 
 /* For an ISO Broadcaster, this value is used to compute
  * the desired Periodic Advertising Interval as a function

---
base-commit: c24f0b487ca3d4e0ca315114a889dad4d2c3bb26
change-id: 20260112-iso_sync_timeout-8e3ecf43d82e

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

