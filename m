From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 10 Jul 2026 12:20:45 +0100
Subject: [PATCH v7 1/7] iio: dac: ad5696: properly check i2c_transfer()
 return value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-ad5686-new-features-v7-1-1bcc8c280e4d@analog.com>
References: <20260710-ad5686-new-features-v7-0-1bcc8c280e4d@analog.com>
In-Reply-To: <20260710-ad5686-new-features-v7-0-1bcc8c280e4d@analog.com>
To: Michael Auchter <michael.auchter@ni.com>, linux@analog.com, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-hardening@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Kees Cook <kees@kernel.org>, "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>, sashiko-bot@kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783682457; l=1018;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=0adqBlbl4dTMRxAIOk7QAvkBMzJDBt+Tq03dU+E4TBY=;
 b=c8W3eMCQ7RttpJqMVNWBVpt6H4evr+Hzn9ii0d40rXKHBOFgc69V5O+4idXLDb9nQZCms6vSD
 XK1ZMyF+YbQD+5nze3fgGxjs19mzL/IVF/w6vgmMQW9d6PVs/EQ/AiD
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verify that the expected number of i2c messages were transferred when
ad5686_i2c_read() is called. This issue exists since the support for I2C
devices where first introduced.

Fixes: 4177381b4401 ("iio:dac:ad5686: Add AD5671R/75R/94/94R/95R/96/96R support")
Reported-by: sashiko-bot@kernel.org
Closes: https://lore.kernel.org/all/20260705114746.1485F1F000E9@smtp.kernel.org/
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/dac/ad5696-i2c.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/dac/ad5696-i2c.c b/drivers/iio/dac/ad5696-i2c.c
index 279309329b64..6f726e6301a6 100644
--- a/drivers/iio/dac/ad5696-i2c.c
+++ b/drivers/iio/dac/ad5696-i2c.c
@@ -40,8 +40,8 @@ static int ad5686_i2c_read(struct ad5686_state *st, u8 addr)
 				      0x00);
 
 	ret = i2c_transfer(i2c->adapter, msg, 2);
-	if (ret < 0)
-		return ret;
+	if (ret != 2)
+		return ret < 0 ? ret : -EIO;
 
 	return be16_to_cpu(st->data[0].d16);
 }

-- 
2.43.0

