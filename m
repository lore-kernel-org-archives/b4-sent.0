From: Marian Poltak <marianpoltak@gmail.com>
Date: Fri, 13 Nov 2026 17:53:40 +0100
Subject: [PATCH bluez v2 1/2] shared/gatt-client: Fix init when Service
 Changed lacks Indicate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-svc-chngd-notify-only-v2-1-e07cc198f32b@gmail.com>
References: <20261113-svc-chngd-notify-only-v2-0-e07cc198f32b@gmail.com>
In-Reply-To: <20261113-svc-chngd-notify-only-v2-0-e07cc198f32b@gmail.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588819; l=2178;
 i=marianpoltak@gmail.com; s=20261112; h=from:subject:message-id;
 bh=1/TTqObs78ywj9niQGB3b4pnlfDX7RjHY1NjRlkW48Q=;
 b=YhT2CvZTV1HFWzD1xmJFdXb2XhFWwwJ/gg0jZmbcXGPSDww0BbPWBR+ktmzaipSCVVWyVi60o
 HPR+cK1f7UVCGuvB39gzMFEIZNBhgE8pWjfSm28YpRV8xTasu2jsTiv
X-Developer-Key: i=marianpoltak@gmail.com; a=ed25519;
 pk=VPxSnAMaNkyjfVbKo8tQ1gFPwqOoZoPqtVZ8znSiAiA=
X-Endpoint-Received: by B4 Relay for marianpoltak@gmail.com/20261112 with auth_id=1502
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

register_service_changed() requests indications explicitly and
register_notify() rejects this when the characteristic does not declare
the Indicate property. Some devices, e.g. the Aqara Presence Sensor P2
in Matter commissioning mode, declare Service Changed as Read | Notify
only, so the client initialization fails and no services are exported,
although ServicesResolved is set.

Request indications only when they are supported, and otherwise pick
the CCC value from the properties as before.

Fixes: 52fdca35b8e7 ("shared/gatt-client: Allow registering notify with explicit CCC value")
Assisted-by: Claude:claude-opus-5-5
---
 src/shared/gatt-client.c | 15 ++++++++++++++-
 1 file changed, 14 insertions(+), 1 deletion(-)

diff --git a/src/shared/gatt-client.c b/src/shared/gatt-client.c
index 7bebc50dc..ea9f7167c 100644
--- a/src/shared/gatt-client.c
+++ b/src/shared/gatt-client.c
@@ -1887,6 +1887,8 @@ static bool register_service_changed(struct bt_gatt_client *client)
 {
 	bt_uuid_t uuid;
 	struct gatt_db_attribute *attr = NULL;
+	uint8_t properties;
+	uint16_t ccc_value = 0;
 
 	bt_uuid16_create(&uuid, SVC_CHNGD_UUID);
 
@@ -1898,6 +1900,17 @@ static bool register_service_changed(struct bt_gatt_client *client)
 	if (!attr)
 		return true;
 
+	/*
+	 * "Service Changed" shall be indicated, but some devices only
+	 * declare the notify property. Request indications only when they
+	 * are supported, otherwise let register_notify() pick the CCC value
+	 * from the properties.
+	 */
+	if (gatt_db_attribute_get_char_data(attr, NULL, NULL, &properties,
+							NULL, NULL) &&
+				(properties & BT_GATT_CHRC_PROP_INDICATE))
+		ccc_value = 0x0002;
+
 	/*
 	 * Register an indication handler for the "Service Changed"
 	 * characteristic and report ready only if the handler is registered
@@ -1905,7 +1918,7 @@ static bool register_service_changed(struct bt_gatt_client *client)
 	 */
 	client->svc_chngd_ind_id = register_notify(client,
 					gatt_db_attribute_get_handle(attr),
-					0x0002,
+					ccc_value,
 					service_changed_register_cb,
 					service_changed_cb,
 					client, NULL);

-- 
2.56.0

