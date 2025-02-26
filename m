From: Ye He <ye.he@amlogic.com>
Date: Wed, 26 Feb 2025 09:52:06 +0800
Subject: [PATCH bluez v2] adapter: Prepend the new added device to the
 adapter devices list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250226-leaudio-no-media-v2-1-8d4dd95513ed@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAMVzvmcC/3WNzQ6DIBCEX8XsudsgIP059T0aDxS2uomKgWraG
 t69xHuP30zmmw0SRaYE12qDSCsnDlMBeajA9XbqCNkXBilkI6RscCC7eA44BRzJs0WjtJZKnA1
 ZDWU2R3rye1fe4TEs9IW2xD2nV4if/Wit9/K/c62xRuPtRTdamJNXNzsOoWN3dGGENuf8Aw9xV
 f65AAAA
X-Change-ID: 20250225-leaudio-no-media-634423086ea4
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>, "ye.he" <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740534731; l=1417;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=9JsiHCZlCs1D1DvtBuitQVccssm2fR/XGb53thZYVIg=;
 b=9EUdayr3IkVnxQI/LXm+4Hux/gRp9UC29tJ2pTA41aAG3dD9ltIEwzuYAszzOA6Ildcxcgo6e
 f0ew38HEoBoDm+VJ7sgfRcXgPLefzVtrIyQRGKLLgNXJ+qKTx5lhV1A
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the DUT is paired with a mobile phone using RPA multiple times,
multiple device contexts with the same bdaddr will be cached.
When we query the device context through bdaddr, we always get the
context at the head of adapter->devices, but its status is inactive.

https://github.com/bluez/bluez/issues/1095

Signed-off-by: Ye He <ye.he@amlogic.com>
---
Signed-off-by: ye.he <ye.he@amlogic.com>
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://patch.msgid.link/20250225-leaudio-no-media-v1-1-6da9454067d3@amlogic.com
---
 src/adapter.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/src/adapter.c b/src/adapter.c
index 2bb94cf1673e85710abf1e619fdeee9c9fa0f087..d675f0b1575a21bc345cbdb003411cf188fdd314 100644
--- a/src/adapter.c
+++ b/src/adapter.c
@@ -5243,7 +5243,7 @@ void device_resolved_drivers(struct btd_adapter *adapter,
 static void adapter_add_device(struct btd_adapter *adapter,
 						struct btd_device *device)
 {
-	adapter->devices = g_slist_append(adapter->devices, device);
+	adapter->devices = g_slist_prepend(adapter->devices, device);
 	device_added_drivers(adapter, device);
 }
 

---
base-commit: 0845b8f6ef2ac004b1c953cf4fe4ca3458cd8e36
change-id: 20250225-leaudio-no-media-634423086ea4

Best regards,
-- 
Ye He <ye.he@amlogic.com>

