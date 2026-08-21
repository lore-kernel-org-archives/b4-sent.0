From: Markuss Broks <markuss.broks@gmail.com>
Date: Sat, 22 Aug 2026 00:30:14 +0300
Subject: [PATCH 2/5] Input: imagis - do not report coordinates of released
 contacts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-imagis-40xx-v1-2-73e6d6cdf110@gmail.com>
References: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
In-Reply-To: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787347843; l=1815;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=/89QleBijrj8h5epT76LuQ4gCzsyr6Wpor71MQ0Dksk=;
 b=WLXIrjwJPs3d2Z4zlM11Ew5aCBf3PVpRFXqhiA2baum1Dmyb8XqOjM3KcPsvPDi3BhRSRxI68
 wX0r8R52Mh7CXL0qcIHse3c1+kpKqLqk1Zp3VlFemqNRZ1VhaJmsHvq
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The position and the contact area are currently reported even for
contacts which are being released. The slot has already been deactivated
at that point, so these events carry no information for userspace.
Report the position and the contact area only for active contacts.

This also prepares the driver for the IST40xx family: its per-contact
records carry an event type in the bits which hold the contact area on
the currently supported chips, so release records must not be parsed for
coordinates or the contact area.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/input/touchscreen/imagis.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/input/touchscreen/imagis.c b/drivers/input/touchscreen/imagis.c
index 7bbb00beec3b..7cc91f97c06e 100644
--- a/drivers/input/touchscreen/imagis.c
+++ b/drivers/input/touchscreen/imagis.c
@@ -127,6 +127,8 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 	finger_pressed = FIELD_GET(IST3038C_FINGER_STATUS_MASK, intr_message);
 
 	for (i = 0; i < finger_count; i++) {
+		bool pressed;
+
 		if (ts->tdata->protocol_b)
 			error = imagis_i2c_read_reg(ts,
 						    ts->tdata->touch_coord_cmd + (i * 4),
@@ -141,9 +143,13 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 			goto out;
 		}
 
+		pressed = finger_pressed & BIT(i);
+
 		input_mt_slot(ts->input_dev, i);
-		input_mt_report_slot_state(ts->input_dev, MT_TOOL_FINGER,
-					   finger_pressed & BIT(i));
+		input_mt_report_slot_state(ts->input_dev, MT_TOOL_FINGER, pressed);
+		if (!pressed)
+			continue;
+
 		touchscreen_report_pos(ts->input_dev, &ts->prop,
 				       FIELD_GET(IST3038C_X_MASK, finger_status),
 				       FIELD_GET(IST3038C_Y_MASK, finger_status),

-- 
2.55.0

