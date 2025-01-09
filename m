From: "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
Date: Fri, 10 Jan 2025 00:37:48 +0300
Subject: [PATCH v3 2/4] input: cyttsp5: improve read size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250110-nekocwd-upstreaming-cyttsp5-v3-2-b33659c8effc@gmail.com>
References: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
In-Reply-To: <20250110-nekocwd-upstreaming-cyttsp5-v3-0-b33659c8effc@gmail.com>
To: Linus Walleij <linus.walleij@linaro.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 James Hilliard <james.hilliard1@gmail.com>, 
 "Vasiliy Doylov (NekoCWD)" <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1879;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=3F8l24mMNC3+oYN1LDuYXU58jg8ObsK3gJ6DuKE3OoQ=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNIbHM9oRe3KnDaD709YrWrb9MsHthw5eHTV1ukX9tUwX
 iht5mq+1VHKwiDGxSArpshis9Fjtlh+uOSkaU8VYOawMoEMYeDiFICJ3LjFyHAlf/mygpkXpJ+m
 Pvm8b5Jst/5FuyCp9NRpkk6f0hqjP/9gZHi6uX3nya5dJy4+iMiLW9NwbavthRcCavuvXz10faf
 Z5hfcAA==
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before PIP 1.7 empty buffer is 0x0002
From PIP 1.7, empty buffer is 0xFFXX

Co-developed-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: James Hilliard <james.hilliard1@gmail.com>
Signed-off-by: Vasiliy Doylov (NekoCWD) <nekodevelopper@gmail.com>
---
 drivers/input/touchscreen/cyttsp5.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/input/touchscreen/cyttsp5.c b/drivers/input/touchscreen/cyttsp5.c
index ef74b4f190351b99c0722b38ae5fa491a4087ffe..4b73b1abc7e449b2dd0c453b816ce7887d9ddb0e 100644
--- a/drivers/input/touchscreen/cyttsp5.c
+++ b/drivers/input/touchscreen/cyttsp5.c
@@ -27,6 +27,7 @@
 #define CY_I2C_DATA_SIZE			(2 * 256)
 #define HID_VERSION				0x0100
 #define CY_MAX_INPUT				512
+#define CY_PIP_1P7_EMPTY_BUF			0xFF00
 #define CYTTSP5_PREALLOCATED_CMD_BUFFER		32
 #define CY_BITS_PER_BTN				1
 #define CY_NUM_BTN_EVENT_ID			GENMASK(CY_BITS_PER_BTN - 1, 0)
@@ -228,7 +229,11 @@ static int cyttsp5_read(struct cyttsp5 *ts, u8 *buf, u32 max)
 		return error;
 
 	size = get_unaligned_le16(temp);
-	if (!size || size == 2)
+	/*
+	 * Before PIP 1.7, empty buffer is 0x0002
+	 * From PIP 1.7, empty buffer is 0xFFXX
+	 */
+	if (!size || size == 2 || size >= CY_PIP_1P7_EMPTY_BUF)
 		return 0;
 
 	if (size > max)
@@ -708,7 +713,8 @@ static irqreturn_t cyttsp5_handle_irq(int irq, void *handle)
 	if (size == 0) {
 		/* reset */
 		report_id = 0;
-		size = 2;
+	} else if (size == 2 || size >= CY_PIP_1P7_EMPTY_BUF) {
+		return IRQ_HANDLED;
 	} else {
 		report_id = ts->input_buf[2];
 	}
@@ -744,7 +750,7 @@ static int cyttsp5_deassert_int(struct cyttsp5 *ts)
 		return error;
 
 	size = get_unaligned_le16(&buf[0]);
-	if (size == 2 || size == 0)
+	if (size == 2 || size == 0 || size >= CY_PIP_1P7_EMPTY_BUF)
 		return 0;
 
 	return -EINVAL;

-- 
2.47.1

