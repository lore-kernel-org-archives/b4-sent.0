From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Wed, 29 Apr 2026 14:07:35 +0100
Subject: [PATCH v4 05/13] iio: dac: ad5686: fix overlapping DMA buffers in
 I2C read
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260429-ad5686-fixes-v4-5-bb8f1cbd68e1@analog.com>
References: <20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com>
In-Reply-To: <20260429-ad5686-fixes-v4-0-bb8f1cbd68e1@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Stefan Popa <stefan.popa@analog.com>, Jonathan Cameron <jic23@cam.ac.uk>, 
 Greg Kroah-Hartman <gregkh@suse.de>, 
 Michael Auchter <michael.auchter@ni.com>, 
 Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, 
 Rodrigo Alencar <rdealencar@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777468056; l=1342;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=z//9u6PswtgHUejmo4eNzd3La9IQg4Jj8G/hjxUaHc0=;
 b=Q5kCfVXd2U0uebBfIbMgi/xxxP092I/getGLhO8heWIERHqVUwrL33qNiSNI3sKyyEhZIdFPt
 7AB/vH7vdh9BeyGTOPuhdh1CyWfhjveeo7JcuRCMmnt1coUliChCjMq
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TX and RX buffers in ad5686_i2c_read() both reference data[0], causing
byte d8[1] to be shared between the TX buffer and the RX buffer. I2C
controller drivers that map all message buffers for DMA before initiating
the hardware transaction will map overlapping memory ranges with
conflicting DMA directions (DMA_TO_DEVICE and DMA_FROM_DEVICE). This issue
was reported by sashiko.

Fixes: 4177381b4401 ("iio:dac:ad5686: Add AD5671R/75R/94/94R/95R/96/96R support")
Signed-off-by: Rodrigo Alencar <rdealencar@gmail.com>
---
 drivers/iio/dac/ad5696-i2c.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index d3327bca0e07..d3b46496d67d 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -26,7 +26,7 @@ static int ad5686_i2c_read(struct ad5686_state *st, u8 addr)
 			.addr = i2c->addr,
 			.flags = i2c->flags | I2C_M_RD,
 			.len = 2,
-			.buf = (char *)&st->data[0].d16,
+			.buf = (char *)&st->data[1].d16,
 		},
 	};
 	int ret;
@@ -39,7 +39,7 @@ static int ad5686_i2c_read(struct ad5686_state *st, u8 addr)
 	if (ret < 0)
 		return ret;
 
-	return be16_to_cpu(st->data[0].d16);
+	return be16_to_cpu(st->data[1].d16);
 }
 
 static int ad5686_i2c_write(struct ad5686_state *st,

-- 
2.43.0

