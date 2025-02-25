From: "ye.he" <ye.he@amlogic.com>
Date: Tue, 25 Feb 2025 17:04:07 +0800
Subject: [PATCH bluez] adapter: Prepend the new added device to the adapter
 devices list
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250225-leaudio-no-media-v1-1-6da9454067d3@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAIaHvWcC/x3MQQqDMBBG4avIrB2IY5TiVcRFav62AzaRBEUq3
 t3Q5bd476SMpMg0VCcl7Jo1hoKmrmj+uPAGqy8mMdIZkY4XuM1r5BD5C6+O+9Zaac2jh7NUsjX
 hpcd/OdJz2fCj6bpu5WJMnGkAAAA=
X-Change-ID: 20250225-leaudio-no-media-634423086ea4
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: "ye.he" <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740474272; l=1144;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=LiGBECn3b0Rk/VUHLXhxHMcVkP8VTGA2MyBmfyfM1r0=;
 b=ZlRx8DI8XcFeJtepjZzxZcknAdYqlWYb2doFr922Erxr6lH23dmsY/LWa+RjQtpeq8HmeU8Sh
 Fc5Dbs+9oUuDBiNZYB3PEXnQI2Xywt+qksll71d6CMmWqfE3JtqP+6V
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the DUT is paired with a mobile phone using RPA multiple times,
multiple device contexts with the same bdaddr will be cached.
When we query the device context through bdaddr, we always get the
context at the head of adapter->devices, but its status is inactive.

https://github.com/bluez/bluez/issues/1095

Signed-off-by: ye.he <ye.he@amlogic.com>
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
ye.he <ye.he@amlogic.com>

