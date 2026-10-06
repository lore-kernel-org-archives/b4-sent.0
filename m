From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Tue, 06 Oct 2026 16:31:31 +0800
Subject: [PATCH] media: i2c: it6625: wait at least 700 ms after reset
 release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-upstream-it6625-reset-delay-v1-1-e4cb3c74e6d3@ite.com.tw>
X-B4-Tracking: v=1; b=H4sIAOKxxGoC/x3MwQqCQBAG4FeROTcwruyGvUp0WPS3BspkZotCf
 HcXj9/lW8lhCqdLs5Lhq67vuaI9NTQ88nwH61hNQUJqRRJ/Fi+G/GItKYXIBkfhEc/85y50fZT
 zECfpqQ6LYdLfsV9v27YDs2vltW0AAAA=
X-Change-ID: 20261006-upstream-it6625-reset-delay-3239507c5f09
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791275507; l=1335;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=ajDymvLtZd4mqViSriJEAC5U7NEZYEy4dRLuuNrLaX0=;
 b=GSQIayG0IULUFI9TdFynbzFRV7IK3fWOrjkVZnnqflNa5KpkfXWBp7iczOKhgxAvBx74AekFd
 uCeHfClM2lmD4bxFG26EW/XmcrVcN8NDXvboJ9ihL69KXQp9m2A2tM0
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IT6625/IT6626 are controlled through an on-chip MCU, which needs at
least 700 ms after the reset line is released before it boots and
answers on the I2C interface. The probe path only waits 10 ms before
reading the chip ID, so the read can happen before the MCU is up and
probe then fails.

Wait at least 700 ms after releasing reset.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b74df9dbf8c2cab7461c69bc0f926141ed7a506c..585c8835e218c568709a057d4afc3c5cbd1dccff 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -2260,7 +2260,8 @@ static int it6625_probe(struct i2c_client *client)
 	if (it6625->reset_gpio) {
 		usleep_range(1000, 2000);
 		gpiod_set_value_cansleep(it6625->reset_gpio, 0);
-		usleep_range(10000, 11000);
+		/* the MCU needs at least 700 ms to boot after reset release */
+		msleep(700);
 	}
 
 	err = it6625_regmap_i2c_init(client, it6625);

---
base-commit: 89a3d2a2237e017cdbefcb036db71ce74e67faf5
change-id: 20261006-upstream-it6625-reset-delay-3239507c5f09

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

