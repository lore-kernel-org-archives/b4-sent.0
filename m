From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 17 Aug 2025 19:09:26 +0200
Subject: [PATCH 7/7] media: i2c: dw9719: Fix power on/off sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250817-dw9719-v1-7-426f46c69a5a@apitzsch.eu>
References: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
In-Reply-To: <20250817-dw9719-v1-0-426f46c69a5a@apitzsch.eu>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Daniel Scally <djrscally@gmail.com>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Val Packett <val@packett.cool>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755450582; l=2482;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=WHp/XEAFOtAOYg6kNIcSWN2unJmOfneuc2Td8tZ6uiA=;
 b=NJpVHJJszElHrcLxB/I+5PDwFas8+W1oFx/BrnqHoTG0l2JCXVt9E+ZVwigf9wxE3C+BFnwvZ
 Zfmn26gH1EMDwjWpYBJ1sP5M72RPg2CtSw2YF8yWb+DQu8GSP9bEYEl
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Val Packett <val@packett.cool>

The "jiggle" code was not actually expecting failure, which it should
because that's what actually happens when the device wasn't already woken
up by the regulator power-on (i.e. in the case of a shared regulator).

Also, do actually enter the internal suspend mode on shutdown, to save
power in the case of a shared regulator.

Also, wait a bit longer (2x tOPR) on waking up, 1x is not enough at least
on the DW9718S as found on the motorola-nora smartphone.

Signed-off-by: Val Packett <val@packett.cool>
Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/dw9719.c | 23 ++++++++++++++++-------
 1 file changed, 16 insertions(+), 7 deletions(-)

diff --git a/drivers/media/i2c/dw9719.c b/drivers/media/i2c/dw9719.c
index 63c7fd4ab70a0e02518252b23b89c45df4ba273d..dd28a0223d6ac980084b1f661bd029ea6b0be503 100644
--- a/drivers/media/i2c/dw9719.c
+++ b/drivers/media/i2c/dw9719.c
@@ -95,12 +95,19 @@ struct dw9719_device {
 
 static int dw9719_power_down(struct dw9719_device *dw9719)
 {
+	u32 reg_pwr = (dw9719->model == DW9718S) ? DW9718S_PD : DW9719_CONTROL;
+
+	/*
+	 * Worth engaging the internal SHUTDOWN mode especially due to the
+	 * regulator being potentially shared with other devices.
+	 */
+	cci_write(dw9719->regmap, reg_pwr, DW9719_SHUTDOWN, NULL);
 	return regulator_disable(dw9719->regulator);
 }
 
 static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 {
-	u32 reg_pwr;
+	u32 reg_pwr = (dw9719->model == DW9718S) ? DW9718S_PD : DW9719_CONTROL;
 	u64 val;
 	int ret;
 	int err;
@@ -109,13 +116,15 @@ static int dw9719_power_up(struct dw9719_device *dw9719, bool detect)
 	if (ret)
 		return ret;
 
-	/* Jiggle SCL pin to wake up device */
-	reg_pwr = (dw9719->model == DW9718S) ? DW9718S_PD : DW9719_CONTROL;
-	cci_write(dw9719->regmap, reg_pwr, DW9719_SHUTDOWN, &ret);
-	fsleep(100);
+	/*
+	 * Need 100us to transition from SHUTDOWN to STANDBY.
+	 * Jiggle the SCL pin to wake up the device (even when the regulator
+	 * is shared) and wait double the time to be sure, then retry the write.
+	 */
+	cci_write(dw9719->regmap, reg_pwr, DW9719_STANDBY, &ret);
+	ret = 0; /* the jiggle is expected to fail, don't even log that as error */
+	fsleep(200);
 	cci_write(dw9719->regmap, reg_pwr, DW9719_STANDBY, &ret);
-	/* Need 100us to transit from SHUTDOWN to STANDBY */
-	fsleep(100);
 
 	if (detect) {
 		/* This model does not have an INFO register */

-- 
2.50.1

