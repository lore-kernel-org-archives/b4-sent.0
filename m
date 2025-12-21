From: Peter Hutterer <peter.hutterer@who-t.net>
Date: Mon, 22 Dec 2025 09:43:34 +1000
Subject: [PATCH v2 1/4] HID: multitouch: set INPUT_PROP_PRESSUREPAD based
 on Digitizer/Button Type
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-wip-hid-pressurepad-v2-1-054ac9689bb7@who-t.net>
References: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
In-Reply-To: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 linux-input@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vadim Klishko <vadim@cirque.com>, 
 Peter Hutterer <peter.hutterer@who-t.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766360621; l=2040;
 i=peter.hutterer@who-t.net; s=20251222; h=from:subject:message-id;
 bh=dMjDzKSeawsZaA/hN50AyJBSpCTU67tb7j/TTV1AREQ=;
 b=BTVFx0y3GbBgjF0Ne37a5wMKd6c7q0RVpqzBIyXM+0p+CNu1JARK3+Rtta4OVHxmwlR8oJxaZ
 /H7N8K9RNhOA3LEZPn23PoXieS5b9kMwB+MtobwchLj8i2Ud6YWxExS
X-Developer-Key: i=peter.hutterer@who-t.net; a=ed25519;
 pk=QoL66HDbFudb9Xt36p2XxsSohZSHVHesRR9c0pI28a4=
X-Endpoint-Received: by B4 Relay for peter.hutterer@who-t.net/20251222 with auth_id=582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A Digitizer/Button Type value of 1 indicates the device is a
pressurepad, see
https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/touchpad-windows-precision-touchpad-collection#device-capabilities-feature-report

Signed-off-by: Peter Hutterer <peter.hutterer@who-t.net>
---
 drivers/hid/hid-multitouch.c | 12 +++++++++++-
 1 file changed, 11 insertions(+), 1 deletion(-)

diff --git a/drivers/hid/hid-multitouch.c b/drivers/hid/hid-multitouch.c
index 179dc316b4b518d78bdc900d9fd15756c5eba83e..382e6f50c4f7e663af7d028abb8be7cb2e6e7b8e 100644
--- a/drivers/hid/hid-multitouch.c
+++ b/drivers/hid/hid-multitouch.c
@@ -81,6 +81,7 @@ MODULE_LICENSE("GPL");
 #define MT_INPUTMODE_TOUCHPAD		0x03
 
 #define MT_BUTTONTYPE_CLICKPAD		0
+#define MT_BUTTONTYPE_PRESSUREPAD	1
 
 enum latency_mode {
 	HID_LATENCY_NORMAL = 0,
@@ -179,6 +180,7 @@ struct mt_device {
 	__u8 inputmode_value;	/* InputMode HID feature value */
 	__u8 maxcontacts;
 	bool is_buttonpad;	/* is this device a button pad? */
+	bool is_pressurepad;	/* is this device a pressurepad? */
 	bool is_haptic_touchpad;	/* is this device a haptic touchpad? */
 	bool serial_maybe;	/* need to check for serial protocol */
 
@@ -530,8 +532,14 @@ static void mt_feature_mapping(struct hid_device *hdev,
 		}
 
 		mt_get_feature(hdev, field->report);
-		if (field->value[usage->usage_index] == MT_BUTTONTYPE_CLICKPAD)
+		switch (field->value[usage->usage_index]) {
+		case MT_BUTTONTYPE_CLICKPAD:
 			td->is_buttonpad = true;
+			break;
+		case MT_BUTTONTYPE_PRESSUREPAD:
+			td->is_pressurepad = true;
+			break;
+		}
 
 		break;
 	case 0xff0000c5:
@@ -1393,6 +1401,8 @@ static int mt_touch_input_configured(struct hid_device *hdev,
 
 	if (td->is_buttonpad)
 		__set_bit(INPUT_PROP_BUTTONPAD, input->propbit);
+	if (td->is_pressurepad)
+		__set_bit(INPUT_PROP_PRESSUREPAD, input->propbit);
 
 	app->pending_palm_slots = devm_kcalloc(&hi->input->dev,
 					       BITS_TO_LONGS(td->maxcontacts),

-- 
2.51.1

