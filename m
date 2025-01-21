From: Yang Li <yang.li@amlogic.com>
Date: Tue, 21 Jan 2025 18:04:57 +0800
Subject: [PATCH BlueZ bluez] gatt: expand the max GATT Channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250121-upstream-v1-1-7b6e450747f7@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAEhxj2cC/x3MQQqAIBBA0avErBPUkKCrRIupphooC6ciEu+et
 Hzw+RGEApNAU0QIdLPw7jNMWcCwoJ9J8ZgNVlunjTXqOuQMhJuasNe1rpzBsYKcH4Emfv5VC/1
 60QtdSh9UKOYYYQAAAA==
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1737453905; l=1410;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=2whhUph12UWbt4IQDLgB95XDZYci4SGZ4RN/aFjNA2M=;
 b=1rtdRJBFOV6QCrr1IYnyjOf5XQxxkKr28ZxFFMvYLbaGoq52vYS6xyStxBHaED7uYT7j+FqEj
 Ip7vLASbNSPDWqAG9RwbR4KGFDQets5LQtnmbLetL/7BqBzs2bbxdbS
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixed the problem that Xiaomi K70 mobile phone takes too long to
connect to CIS.

L2CAP CB Connection (PSM=0x0027, MTU=517 bytes, MPS=251 bytes,
 Credits=255, Src=0x0056 › All Connections Refused –
 Insufficient Authorization)

Ref https://github.com/bluez/bluez/issues/1033

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/main.c    | 2 +-
 src/main.conf | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/src/main.c b/src/main.c
index d13ada2af..e2243c824 100644
--- a/src/main.c
+++ b/src/main.c
@@ -1119,7 +1119,7 @@ static void parse_gatt(GKeyFile *config)
 	parse_config_u16(config, "GATT", "ExchangeMTU", &btd_opts.gatt_mtu,
 				BT_ATT_DEFAULT_LE_MTU, BT_ATT_MAX_LE_MTU);
 	parse_config_u8(config, "GATT", "Channels", &btd_opts.gatt_channels,
-				1, 5);
+				1, 10);
 	parse_config_bool(config, "GATT", "Client", &btd_opts.gatt_client);
 	parse_gatt_export(config);
 }
diff --git a/src/main.conf b/src/main.conf
index 60ab60edc..95de56003 100644
--- a/src/main.conf
+++ b/src/main.conf
@@ -264,7 +264,7 @@
 #ExchangeMTU = 517
 
 # Number of ATT channels
-# Possible values: 1-5 (1 disables EATT)
+# Possible values: 1-10 (1 disables EATT)
 # Default to 1
 #Channels = 1
 

---
base-commit: 2ee08ffd4d469781dc627fa50b4a015d9ad68007
change-id: 20250121-upstream-fab070351ad3

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

