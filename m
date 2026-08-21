From: Markuss Broks <markuss.broks@gmail.com>
Date: Sat, 22 Aug 2026 00:30:16 +0300
Subject: [PATCH 4/5] Input: imagis - add support for the IST40xx touch
 reporting format
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-imagis-40xx-v1-4-73e6d6cdf110@gmail.com>
References: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
In-Reply-To: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787347843; l=4630;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=nhgSejXLaeik0yd9gYDsbPQiM2+SayHHbjInSk+Mj6E=;
 b=7C43MGJhylrJewIzJXjOOWCV8q3FUHf60NP5sZPEmAV/ZaBKvKPCELcF/BeihPZX/gflkBDrV
 V0QHEAQ9cvQDiHgO/vrVQkQfwEo3JR/wYuPMZ4oFwX4jRqsaysdJkns
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Chips of the Imagis IST40xx family share the register interface and the
coordinate format with IST3038C, but report touches differently: the
per-contact records are 8 bytes apart, and instead of pairing the record
index with a "pressed" bitmask from the interrupt message, each record
carries a hardware-assigned touch ID (1-based, bits 31:28) and an event
type (press or release, bits 27:24). The event type occupies the bits
which hold the contact area on IST3038C, and no contact area is
available in the coordinate word.

Add an IMAGIS_PROTOCOL_TOUCH_EVENTS variant for this format: derive the
contact slot from the touch ID instead of the record index, translate
press/release events into the contact state, ignore records with an
out-of-range touch ID or an unknown event type, and do not declare the
ABS_MT_TOUCH_MAJOR axis.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/input/touchscreen/imagis.c | 49 +++++++++++++++++++++++++++++++++-----
 1 file changed, 43 insertions(+), 6 deletions(-)

diff --git a/drivers/input/touchscreen/imagis.c b/drivers/input/touchscreen/imagis.c
index 6552d97efe32..5254cccdd653 100644
--- a/drivers/input/touchscreen/imagis.c
+++ b/drivers/input/touchscreen/imagis.c
@@ -44,11 +44,18 @@
 #define IST3038C_FINGER_STATUS_MASK	GENMASK(9, 0)
 #define IST3032C_KEY_STATUS_MASK	GENMASK(20, 16)
 
+#define IST40XX_TOUCH_ID_MASK		GENMASK(31, 28)
+#define IST40XX_TOUCH_EVENT_MASK	GENMASK(27, 24)
+#define IST40XX_TOUCH_EVENT_PRESS	1
+#define IST40XX_TOUCH_EVENT_RELEASE	2
+
 enum imagis_protocol {
 	/* one coordinate register shared by all contacts */
 	IMAGIS_PROTOCOL_SHARED_REGISTER,
 	/* one coordinate register per contact */
 	IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS,
+	/* one record per contact, carrying a touch ID and an event type */
+	IMAGIS_PROTOCOL_TOUCH_EVENTS,
 };
 
 struct imagis_properties {
@@ -134,9 +141,14 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 	finger_pressed = FIELD_GET(IST3038C_FINGER_STATUS_MASK, intr_message);
 
 	for (i = 0; i < finger_count; i++) {
+		unsigned int slot = i;
 		bool pressed;
 
-		if (ts->tdata->protocol == IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS)
+		if (ts->tdata->protocol == IMAGIS_PROTOCOL_TOUCH_EVENTS)
+			error = imagis_i2c_read_reg(ts,
+						    ts->tdata->touch_coord_cmd + (i * 8),
+						    &finger_status);
+		else if (ts->tdata->protocol == IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS)
 			error = imagis_i2c_read_reg(ts,
 						    ts->tdata->touch_coord_cmd + (i * 4),
 						    &finger_status);
@@ -150,9 +162,31 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 			goto out;
 		}
 
-		pressed = finger_pressed & BIT(i);
+		if (ts->tdata->protocol == IMAGIS_PROTOCOL_TOUCH_EVENTS) {
+			unsigned int id = FIELD_GET(IST40XX_TOUCH_ID_MASK,
+						    finger_status);
+
+			if (!id || id > IST3038C_MAX_FINGER_NUM)
+				continue;
+
+			slot = id - 1;
+
+			switch (FIELD_GET(IST40XX_TOUCH_EVENT_MASK,
+					  finger_status)) {
+			case IST40XX_TOUCH_EVENT_PRESS:
+				pressed = true;
+				break;
+			case IST40XX_TOUCH_EVENT_RELEASE:
+				pressed = false;
+				break;
+			default:
+				continue;
+			}
+		} else {
+			pressed = finger_pressed & BIT(i);
+		}
 
-		input_mt_slot(ts->input_dev, i);
+		input_mt_slot(ts->input_dev, slot);
 		input_mt_report_slot_state(ts->input_dev, MT_TOOL_FINGER, pressed);
 		if (!pressed)
 			continue;
@@ -161,8 +195,10 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 				       FIELD_GET(IST3038C_X_MASK, finger_status),
 				       FIELD_GET(IST3038C_Y_MASK, finger_status),
 				       true);
-		input_report_abs(ts->input_dev, ABS_MT_TOUCH_MAJOR,
-				 FIELD_GET(IST3038C_AREA_MASK, finger_status));
+		if (ts->tdata->protocol != IMAGIS_PROTOCOL_TOUCH_EVENTS)
+			input_report_abs(ts->input_dev, ABS_MT_TOUCH_MAJOR,
+					 FIELD_GET(IST3038C_AREA_MASK,
+						   finger_status));
 	}
 
 	key_pressed = FIELD_GET(IST3032C_KEY_STATUS_MASK, intr_message);
@@ -255,7 +291,8 @@ static int imagis_init_input_dev(struct imagis_ts *ts)
 
 	input_set_capability(input_dev, EV_ABS, ABS_MT_POSITION_X);
 	input_set_capability(input_dev, EV_ABS, ABS_MT_POSITION_Y);
-	input_set_abs_params(input_dev, ABS_MT_TOUCH_MAJOR, 0, 16, 0, 0);
+	if (ts->tdata->protocol != IMAGIS_PROTOCOL_TOUCH_EVENTS)
+		input_set_abs_params(input_dev, ABS_MT_TOUCH_MAJOR, 0, 16, 0, 0);
 	if (ts->tdata->touch_keys_supported) {
 		ts->num_keycodes = of_property_read_variable_u32_array(
 				ts->client->dev.of_node, "linux,keycodes",

-- 
2.55.0

