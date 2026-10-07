From: Hermes Wu <Hermes.wu@ite.com.tw>
Date: Wed, 07 Oct 2026 18:31:52 +0800
Subject: [PATCH v2 1/2] media: i2c: it6625: wait 1s after reset release
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-upstream-it6625-reset-delay-v2-1-c5d6b2522bbe@ite.com.tw>
References: <20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw>
In-Reply-To: <20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw>
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791369112; l=1144;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=qKkiXypnT97wqDUJbzCy8zgS8RDNiH0mVRFKOrveAOo=;
 b=T6D6cCBMy9lDR4m2CTvQUFEWVNTcqYs7Jm42uGk/iTjGhOJg2AmV5eLw5EigwaB0zY26PEcxT
 L/ifhPjfA0CAYxKDk51BvzuWPEz3Yfmr7tz2tr7vfV0YlqT+txAgniq
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The IT6625/IT6626 are controlled through an on-chip MCU, which needs up
to 1s after the reset line is released before it boots and answers on
the I2C interface. The probe path only waits 10 ms before reading the
chip ID, so the read can happen before the MCU is up and probe then
fails.

Wait 1s after releasing reset.

Fixes: 142e5f00bd57 ("media: i2c: add driver for ITE IT6625/IT6626")
Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
 drivers/media/i2c/it6625.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/it6625.c b/drivers/media/i2c/it6625.c
index b74df9dbf8c2cab7461c69bc0f926141ed7a506c..fc8b22cc1c9ba3612f9c55bea1de61fa9a9c0e84 100644
--- a/drivers/media/i2c/it6625.c
+++ b/drivers/media/i2c/it6625.c
@@ -2260,7 +2260,8 @@ static int it6625_probe(struct i2c_client *client)
 	if (it6625->reset_gpio) {
 		usleep_range(1000, 2000);
 		gpiod_set_value_cansleep(it6625->reset_gpio, 0);
-		usleep_range(10000, 11000);
+		/* the MCU needs up to 1s to boot after reset release */
+		msleep(1000);
 	}
 
 	err = it6625_regmap_i2c_init(client, it6625);

-- 
2.34.1

