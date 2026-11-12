From: Marian Poltak <marianpoltak@gmail.com>
Date: Thu, 12 Nov 2026 18:40:54 +0100
Subject: [PATCH bluez 2/2] unit/test-gatt: Add Service Changed registration
 tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-svc-chngd-notify-only-v1-2-c7db7ac47acf@gmail.com>
References: <20261112-svc-chngd-notify-only-v1-0-c7db7ac47acf@gmail.com>
In-Reply-To: <20261112-svc-chngd-notify-only-v1-0-c7db7ac47acf@gmail.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794505252; l=2400;
 i=marianpoltak@gmail.com; s=20261112; h=from:subject:message-id;
 bh=XK5mcZb3G2ELsrp0b6wGWcIGxQMIVDa+IEfTDoVdkJ4=;
 b=fBnyIyAvPzE8qHNURWtPhqm+RBa5se+7agNZkZ4Nsytak5IKgbKsrwBZvDEA5N959cEd+0Ody
 4c00wy/Z1MTA057XFk3TfIl3N0HfuWiPyzJi3xrfbabLNvPWMf2x43U
X-Developer-Key: i=marianpoltak@gmail.com; a=ed25519;
 pk=VPxSnAMaNkyjfVbKo8tQ1gFPwqOoZoPqtVZ8znSiAiA=
X-Endpoint-Received: by B4 Relay for marianpoltak@gmail.com/20261112 with auth_id=1502
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add client tests enabling Service Changed when the characteristic
declares Indicate, and when it declares Notify only.

Assisted-by: Claude:claude-opus-5-5
---
 unit/test-gatt.c | 39 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/unit/test-gatt.c b/unit/test-gatt.c
index bf6074107..45a257ad1 100644
--- a/unit/test-gatt.c
+++ b/unit/test-gatt.c
@@ -303,6 +303,25 @@ struct context {
 		DESCRIPTOR_DISC_SMALL_DB
 
 
+/*
+ * GATT service (0x0001-0x0004) with a Service Changed characteristic
+ * declaring the given properties, value handle 0x0003 and a CCC at 0x0004.
+ */
+#define SVC_CHNGD_DISCOVERY_PDUS(props)					\
+		raw_pdu(0x10, 0x01, 0x00, 0xff, 0xff, 0x00, 0x28),	\
+		raw_pdu(0x11, 0x06, 0x01, 0x00, 0x04, 0x00, 0x01, 0x18),\
+		raw_pdu(0x10, 0x05, 0x00, 0xff, 0xff, 0x00, 0x28),	\
+		raw_pdu(0x01, 0x10, 0x05, 0x00, 0x0a),			\
+		raw_pdu(0x10, 0x01, 0x00, 0xff, 0xff, 0x01, 0x28),	\
+		raw_pdu(0x01, 0x10, 0x01, 0x00, 0x0a),			\
+		raw_pdu(0x08, 0x01, 0x00, 0x04, 0x00, 0x02, 0x28),	\
+		raw_pdu(0x01, 0x08, 0x01, 0x00, 0x0a),			\
+		raw_pdu(0x08, 0x01, 0x00, 0x04, 0x00, 0x03, 0x28),	\
+		raw_pdu(0x09, 0x07, 0x02, 0x00, props, 0x03, 0x00, 0x05,\
+				0x2a),					\
+		raw_pdu(0x08, 0x03, 0x00, 0x04, 0x00, 0x03, 0x28),	\
+		raw_pdu(0x01, 0x08, 0x03, 0x00, 0x0a)
+
 #define SERVER_MTU_EXCHANGE_PDU raw_pdu(0x02, 0x17, 0x00)
 
 static bt_uuid_t uuid_16 = {
@@ -3736,6 +3755,26 @@ int main(int argc, char *argv[])
 			raw_pdu(),
 			raw_pdu(0x1B, 0x03, 0x00, 0x01, 0x02, 0x03));
 
+	/* Service Changed with Indicate: indications are enabled */
+	define_test_client("/robustness/svc-chngd-indicate", test_client,
+			NULL, NULL,
+			CLIENT_INIT_PDUS,
+			SVC_CHNGD_DISCOVERY_PDUS(0x22),
+			raw_pdu(0x12, 0x04, 0x00, 0x02, 0x00),
+			raw_pdu(0x13));
+
+	/*
+	 * Service Changed declaring Notify only (not compliant, seen on
+	 * real devices): notifications are enabled instead of failing the
+	 * client initialization.
+	 */
+	define_test_client("/robustness/svc-chngd-notify-only", test_client,
+			NULL, NULL,
+			CLIENT_INIT_PDUS,
+			SVC_CHNGD_DISCOVERY_PDUS(0x12),
+			raw_pdu(0x12, 0x04, 0x00, 0x01, 0x00),
+			raw_pdu(0x13));
+
 	define_test_server("/TP/GAN/SR/BV-01-C", test_server, ts_small_db,
 			&test_notification_server_1,
 			raw_pdu(0x03, 0x00, 0x02),

-- 
2.56.0

