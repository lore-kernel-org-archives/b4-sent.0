From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Thu, 30 Apr 2026 17:04:28 +0200
Subject: [PATCH v4 8/8] iio: light: si1133: use guard(mutex)() macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260430-si1133-checkup-v4-8-fb3e9dce41bf@gmail.com>
References: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
In-Reply-To: <20260430-si1133-checkup-v4-0-fb3e9dce41bf@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777561514; l=2067;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=hBsegK4uny44/3ElandWq2RObKs2rVS7S5iCG8OtnzI=;
 b=BhO2lyHy83TTyuEIn31CvhLukmjqDyGJ1qQZfhg46gSeO7xuZ5ZweiIpyTNtbJHrFN+uNAJsP
 gj6wHpBDhfdCZSPcIholerVQltO7Tx168IbLTI/MDmnGB3E0ujVjvwU
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove mutex_lock()/mutex_unlock() and goto instances and add
guard(mutex)() macro to modernize driver and improve mutex handling.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/si1133.c | 15 ++++++---------
 1 file changed, 6 insertions(+), 9 deletions(-)

diff --git a/drivers/iio/light/si1133.c b/drivers/iio/light/si1133.c
index a3e4ab25acdc105d3800994f4391a7e4291e1c74..55660dccfc7956e77b1d8105b7261221176c1736 100644
--- a/drivers/iio/light/si1133.c
+++ b/drivers/iio/light/si1133.c
@@ -8,6 +8,7 @@
 
 #include <linux/array_size.h>
 #include <linux/bitops.h>
+#include <linux/cleanup.h>
 #include <linux/completion.h>
 #include <linux/delay.h>
 #include <linux/dev_printk.h>
@@ -396,7 +397,7 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 	int err;
 	int expected_seq;
 
-	mutex_lock(&data->mutex);
+	guard(mutex)(&data->mutex);
 
 	expected_seq = (data->rsp_seq + 1) & SI1133_MAX_CMD_CTR;
 
@@ -413,19 +414,18 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 	if (err) {
 		dev_warn(dev, "Failed to write command 0x%02x, ret=%d\n", cmd,
 			 err);
-		goto out;
+		return err;
 	}
 
 	if (cmd == SI1133_CMD_FORCE) {
 		/* wait for irq */
 		if (!wait_for_completion_timeout(&data->completion, timeout)) {
 			regmap_write(data->regmap, SI1133_REG_IRQ_ENABLE, 0);
-			err = -ETIMEDOUT;
-			goto out;
+			return -ETIMEDOUT;
 		}
 		err = regmap_read(data->regmap, SI1133_REG_RESPONSE0, &resp);
 		if (err)
-			goto out;
+			return err;
 	} else {
 		err = regmap_read_poll_timeout(data->regmap,
 					       SI1133_REG_RESPONSE0, resp,
@@ -443,7 +443,7 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 			 * counters being out of sync.
 			 */
 			si1133_cmd_reset_counter(data);
-			goto out;
+			return err;
 		}
 	}
 
@@ -454,9 +454,6 @@ static int si1133_command(struct si1133_data *data, u8 cmd)
 		data->rsp_seq = expected_seq;
 	}
 
-out:
-	mutex_unlock(&data->mutex);
-
 	return err;
 }
 

-- 
2.47.3

