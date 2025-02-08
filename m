From: Yang Li <yang.li@amlogic.com>
Date: Sat, 08 Feb 2025 19:40:12 +0800
Subject: [PATCH BlueZ bluez] client: Set the feature when initializing the
 client
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250208-client_eatt-v1-1-17932786b2cf@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJtCp2cC/x3M0QpAMBiG4VvRf2y1TSK3Imnmw18abSORe7ccP
 gfv+1CAZwRqsoc8Tg68uQSVZ2QX42YIHpNJS11KLWthV4aLPUyMwlaqHFHUhdITpWL3mPj6by0
 N64Gbuvf9AGEVC9NkAAAA
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739014815; l=2912;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=NjeN/W6SMOhbUw5onPZ37ZDUR1czSasHWD76p2hBMRU=;
 b=Y6dL81o54s4ApBMTKiSaGaua5LtgVWFFMFxNnwZJw1fqwLTNP55P8jYINLLQ1D5GPX9KEIeHD
 rDnJ47GnzGfBsDNwmsHqlbECniW87FBxRTYd0WHdlvIJwyDP2FsV/5K
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When writing Client Features feature values, it needs
to determine whether local eatt is enabled.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 src/device.c             | 9 ++++++++-
 src/gatt-database.c      | 3 ++-
 src/shared/gatt-client.c | 8 +++++---
 3 files changed, 15 insertions(+), 5 deletions(-)

diff --git a/src/device.c b/src/device.c
index e8bff718c..dfa8b277e 100644
--- a/src/device.c
+++ b/src/device.c
@@ -5628,6 +5628,8 @@ static void gatt_debug(const char *str, void *user_data)
 
 static void gatt_client_init(struct btd_device *device)
 {
+	uint8_t features;
+
 	gatt_client_cleanup(device);
 
 	if (!device->connect && !btd_opts.reverse_discovery) {
@@ -5639,8 +5641,13 @@ static void gatt_client_init(struct btd_device *device)
 		return;
 	}
 
+	features =  BT_GATT_CHRC_CLI_FEAT_ROBUST_CACHING
+				| BT_GATT_CHRC_CLI_FEAT_NFY_MULTI;
+	if (btd_opts.gatt_channels > 1)
+		features |= BT_GATT_CHRC_CLI_FEAT_EATT;
+
 	device->client = bt_gatt_client_new(device->db, device->att,
-							device->att_mtu, 0);
+							device->att_mtu, features);
 	if (!device->client) {
 		DBG("Failed to initialize");
 		return;
diff --git a/src/gatt-database.c b/src/gatt-database.c
index a5a01add4..1056b9797 100644
--- a/src/gatt-database.c
+++ b/src/gatt-database.c
@@ -1245,7 +1245,8 @@ static void server_feat_read_cb(struct gatt_db_attribute *attrib,
 		goto done;
 	}
 
-	value |= BT_GATT_CHRC_SERVER_FEAT_EATT;
+	if (btd_opts.gatt_channels > 1)
+		value |= BT_GATT_CHRC_SERVER_FEAT_EATT;
 
 done:
 	gatt_db_attribute_read_result(attrib, id, ecode, &value, sizeof(value));
diff --git a/src/shared/gatt-client.c b/src/shared/gatt-client.c
index 9db3f5211..41a5c6f9c 100644
--- a/src/shared/gatt-client.c
+++ b/src/shared/gatt-client.c
@@ -2043,7 +2043,7 @@ static void write_client_features(struct bt_gatt_client *client)
 
 	handle = gatt_db_attribute_get_handle(attr);
 
-	client->features = BT_GATT_CHRC_CLI_FEAT_ROBUST_CACHING;
+	client->features |= BT_GATT_CHRC_CLI_FEAT_ROBUST_CACHING;
 
 	bt_uuid16_create(&uuid, GATT_CHARAC_SERVER_FEAT);
 
@@ -2055,10 +2055,12 @@ static void write_client_features(struct bt_gatt_client *client)
 		gatt_db_attribute_read(attr, 0, BT_ATT_OP_READ_REQ,
 						NULL, server_feat_read_value,
 						&feat);
-		if (feat && feat[0] & BT_GATT_CHRC_SERVER_FEAT_EATT)
-			client->features |= BT_GATT_CHRC_CLI_FEAT_EATT;
+		if (!(feat && feat[0] & BT_GATT_CHRC_SERVER_FEAT_EATT)
+			|| !(client->features & BT_GATT_CHRC_CLI_FEAT_EATT))
+			client->features &= ~BT_GATT_CHRC_CLI_FEAT_EATT;
 	}
 
+
 	client->features |= BT_GATT_CHRC_CLI_FEAT_NFY_MULTI;
 
 	DBG(client, "Writing Client Features 0x%02x", client->features);

---
base-commit: 2ee08ffd4d469781dc627fa50b4a015d9ad68007
change-id: 20250208-client_eatt-c715de38312f

Best regards,
-- 
Yang Li <yang.li@amlogic.com>

