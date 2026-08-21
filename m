From: Markuss Broks <markuss.broks@gmail.com>
Date: Sat, 22 Aug 2026 00:30:15 +0300
Subject: [PATCH 3/5] Input: imagis - replace the protocol_b flag with a
 protocol enum
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260822-imagis-40xx-v1-3-73e6d6cdf110@gmail.com>
References: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
In-Reply-To: <20260822-imagis-40xx-v1-0-73e6d6cdf110@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Henrik Rydberg <rydberg@bitmath.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Markuss Broks <markuss.broks@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787347843; l=3691;
 i=markuss.broks@gmail.com; s=20260803; h=from:subject:message-id;
 bh=kllTREbKM7MPt6EgqVJAPrfjFuWKJEaN3O2mls6UtuE=;
 b=QYzkDd9z2iAFsYaVTIAB9W+xbs2cVUPDasvPtIbc9ySO3G5gxnRyUirYatexynCkNRm4b+uS+
 xI4lgZNEmxfBS8rcNWOg4ENDy/QUWD7phfbln3k3W3MKeQtuDBDxPV2
X-Developer-Key: i=markuss.broks@gmail.com; a=ed25519;
 pk=oKzGUTm30BCDqinRMpiHQqByOx1mp2mwmhg80Mv7Zg4=
X-Endpoint-Received: by B4 Relay for markuss.broks@gmail.com/20260803 with auth_id=911
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The driver tells the two supported touch reporting formats apart with
the protocol_b flag. The naming is unfortunate: "protocol B" is the
format of the IST30XXC series, while the B-suffixed chips use the
unnamed other format. Adding support for the IST40xx family is about to
introduce a third format, at which point a collection of booleans gets
easy to misuse.

Replace the flag with an enum which describes each reporting format:
IMAGIS_PROTOCOL_SHARED_REGISTER for the single coordinate register
shared by all contacts (IST3038, IST3038B and IST3038H), and
IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS for one coordinate register per
contact (IST3032C and IST3038C).

No functional change intended.

Signed-off-by: Markuss Broks <markuss.broks@gmail.com>
---
 drivers/input/touchscreen/imagis.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/drivers/input/touchscreen/imagis.c b/drivers/input/touchscreen/imagis.c
index 7cc91f97c06e..6552d97efe32 100644
--- a/drivers/input/touchscreen/imagis.c
+++ b/drivers/input/touchscreen/imagis.c
@@ -44,12 +44,19 @@
 #define IST3038C_FINGER_STATUS_MASK	GENMASK(9, 0)
 #define IST3032C_KEY_STATUS_MASK	GENMASK(20, 16)
 
+enum imagis_protocol {
+	/* one coordinate register shared by all contacts */
+	IMAGIS_PROTOCOL_SHARED_REGISTER,
+	/* one coordinate register per contact */
+	IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS,
+};
+
 struct imagis_properties {
 	unsigned int interrupt_msg_cmd;
 	unsigned int touch_coord_cmd;
 	unsigned int whoami_cmd;
 	unsigned int whoami_val;
-	bool protocol_b;
+	enum imagis_protocol protocol;
 	bool touch_keys_supported;
 };
 
@@ -129,7 +136,7 @@ static irqreturn_t imagis_interrupt(int irq, void *dev_id)
 	for (i = 0; i < finger_count; i++) {
 		bool pressed;
 
-		if (ts->tdata->protocol_b)
+		if (ts->tdata->protocol == IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS)
 			error = imagis_i2c_read_reg(ts,
 						    ts->tdata->touch_coord_cmd + (i * 4),
 						    &finger_status);
@@ -410,8 +417,8 @@ static const struct imagis_properties imagis_3032c_data = {
 	.touch_coord_cmd = IST3038C_REG_TOUCH_COORD,
 	.whoami_cmd = IST3038C_REG_CHIPID,
 	.whoami_val = IST3032C_WHOAMI,
+	.protocol = IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS,
 	.touch_keys_supported = true,
-	.protocol_b = true,
 };
 
 static const struct imagis_properties imagis_3038_data = {
@@ -419,6 +426,7 @@ static const struct imagis_properties imagis_3038_data = {
 	.touch_coord_cmd = IST30XX_REG_STATUS,
 	.whoami_cmd = IST30XX_REG_CHIPID,
 	.whoami_val = IST3038_WHOAMI,
+	.protocol = IMAGIS_PROTOCOL_SHARED_REGISTER,
 	.touch_keys_supported = true,
 };
 
@@ -427,6 +435,7 @@ static const struct imagis_properties imagis_3038b_data = {
 	.touch_coord_cmd = IST30XX_REG_STATUS,
 	.whoami_cmd = IST3038B_REG_CHIPID,
 	.whoami_val = IST3038B_WHOAMI,
+	.protocol = IMAGIS_PROTOCOL_SHARED_REGISTER,
 };
 
 static const struct imagis_properties imagis_3038c_data = {
@@ -434,7 +443,7 @@ static const struct imagis_properties imagis_3038c_data = {
 	.touch_coord_cmd = IST3038C_REG_TOUCH_COORD,
 	.whoami_cmd = IST3038C_REG_CHIPID,
 	.whoami_val = IST3038C_WHOAMI,
-	.protocol_b = true,
+	.protocol = IMAGIS_PROTOCOL_PER_CONTACT_REGISTERS,
 };
 
 static const struct imagis_properties imagis_3038h_data = {
@@ -442,6 +451,7 @@ static const struct imagis_properties imagis_3038h_data = {
 	.touch_coord_cmd = IST3038C_REG_TOUCH_COORD,
 	.whoami_cmd = IST3038C_REG_CHIPID,
 	.whoami_val = IST3038H_WHOAMI,
+	.protocol = IMAGIS_PROTOCOL_SHARED_REGISTER,
 };
 
 static const struct of_device_id imagis_of_match[] = {

-- 
2.55.0

