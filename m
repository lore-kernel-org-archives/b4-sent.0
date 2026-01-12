From: Yang Li <yang.li@amlogic.com>
Date: Mon, 12 Jan 2026 14:42:11 +0800
Subject: [PATCH BlueZ bluez] bap: reduce ISO sync timeout to 2s
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260112-iso_sync_timeout-v1-1-9a3e99259a3f@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAMKXZGkC/x3MQQqDMBBG4avIrBtIooh4lVJE468dqEnJqKjBu
 zd0+S3eSySIDKG2SBSxs3DwGeZRkHv3fobiMZustrU2xiqW0MnpXbfygrCtqkEJN1Xl2FhQzr4
 REx//5ZOGz4aLXvf9A0jW/fxpAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768200132; l=976;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=y2BRDsP3/C+MiSJUsfUZeWSpftDfagbVB+7mlzikP/A=;
 b=r8OAJ2HTOV3R/+MHRLvk8Kwys7+swGAzL9Um4Pufeiw0zAd3SYb1bcLw2k97+C3zBWrvYO7oj
 nUCsLPZiZMYAhsBXx69n6bifRwv12NKpW3Ni9t8Sb/gzb0Ip+BPAuQI
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ISO sync timeout was previously set to 20 seconds,
which is too long for PA sync. This could leave the userspace
flow pending for an extended period of time.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 lib/bluetooth/bluetooth.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/lib/bluetooth/bluetooth.h b/lib/bluetooth/bluetooth.h
index f9f22c3f7..572009e75 100644
--- a/lib/bluetooth/bluetooth.h
+++ b/lib/bluetooth/bluetooth.h
@@ -152,7 +152,7 @@ struct bt_voice {
 #define BT_ISO_QOS_BIG_UNSET	0xff
 #define BT_ISO_QOS_BIS_UNSET	0xff
 
-#define BT_ISO_SYNC_TIMEOUT	0x07d0 /* 20 secs */
+#define BT_ISO_SYNC_TIMEOUT	0x00c8 /* 2 secs */
 
 /* For an ISO Broadcaster, this value is used to compute
  * the desired Periodic Advertising Interval as a function

---
base-commit: a94f994201a69a36753abda65cc51937de9cd3e3
change-id: 20260112-iso_sync_timeout-8e3ecf43d82e

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

