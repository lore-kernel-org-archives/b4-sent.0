From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 29 Apr 2026 17:04:56 +0200
Subject: [PATCH v3 8/8] iio: light: si1133: prevent race condition on
 timeout
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-si1133-checkup-v3-8-469f21d960eb@gmail.com>
References: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
In-Reply-To: <20260429-si1133-checkup-v3-0-469f21d960eb@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777475147; l=2620;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=wWxVBIcT+WefqGjm1JhnOezGW/VoQWaUnsiRF0Pw7XM=;
 b=1cs2SN0Jy9iDy6Ems50kETdSDCMgC3jQHCvmQfMN8cRZM1xUNCm7U60Dlp65Wi8zQ6T2B4BGg
 wds1Zv3R366CxQQJy9U/RP5Ub6jOGHwX43Apk9Eta1eMZc+fu9V4ZEP
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sashiko reported a bug where the si1133_command exits on timeout
without halting the sensor or masking the interrupt. If the sensor
completes the command later, any subsequent command to the sensor
will cause the IRQ handler to complete immediately, returning stale
data to the driver all while the command hasn't finished yet, shifting
all potential reads in the future.

Fix this by masking the IRQ if wait_for_completion_timeout() fails.
When initiating a new command, do a dummy read of the IRQ_STATUS
register and turn the IRQ back on.

Closes: https://sashiko.dev/#/message/20260428-si1133-checkup-v2-5-70ad14bfefe2%40gmail.com
Assisted-by: gemini:gemini-3.1-pro-preview
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 19 +++++++++++++++----
 1 file changed, 15 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index 842a59bc68c20b3206e0c826f86c913f6c66bd7c..91c90f2873ae053eb7cbc8c9c79ce6d91a1ec9dc 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -401,8 +401,14 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 
 	expected_seq = (data->rsp_seq + 1) & SI1133_MAX_CMD_CTR;
 
-	if (cmd == SI1133_CMD_FORCE)
+	if (cmd == SI1133_CMD_FORCE) {
+		/* Flush pending IRQs from a previous timeout. */
+		regmap_read(data->regmap, SI1133_REG_IRQ_STATUS, &resp);
+		regmap_write(data->regmap, SI1133_REG_IRQ_ENABLE,
+			     SI1133_IRQ_CHANNEL_ENABLE);
+
 		reinit_completion(&data->completion);
+	}
 
 	err = regmap_write(data->regmap, SI1133_REG_COMMAND, cmd);
 	if (err) {
@@ -413,8 +419,13 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 
 	if (cmd == SI1133_CMD_FORCE) {
 		/* wait for irq */
-		if (!wait_for_completion_timeout(&data->completion, timeout))
+		if (!wait_for_completion_timeout(&data->completion, timeout)) {
+			/* Mask the IRQ to prevent delayed interrupt waking up
+			 * any subsequent command.
+			 */
+			regmap_write(data->regmap, SI1133_REG_IRQ_ENABLE, 0);
 			return -ETIMEDOUT;
+		}
 		err = regmap_read(data->regmap, SI1133_REG_RESPONSE0, &resp);
 		if (err)
 			return err;
@@ -431,8 +442,8 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 				 "Failed to read command 0x%02x, ret=%d\n",
 				 cmd, err);
 			/*
-			 * reset counter on err to prevent sofware and hardware
-			 * counters being out of sync
+			 * Reset counter on err to prevent sofware and hardware
+			 * counters being out of sync.
 			 */
 			si1133_cmd_reset_counter(data);
 

-- 
2.47.3

