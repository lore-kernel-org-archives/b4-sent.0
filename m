From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 12 May 2026 12:57:27 +0200
Subject: [PATCH v2 07/10] iio: light: opt3001: prefer dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-opt3001-cleanup-v2-7-8018cf3a8a0a@gmail.com>
References: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
In-Reply-To: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778583471; l=3829;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=37rRREY2il0fiO/98aujElf7Lwb4t3do/3EAx2mE6o8=;
 b=ePJsxbGYRUfMAm9rOg+cBydEIrMvF+Wu1mWxZQQXJm9GaT9iuV2U1cWmH/4URhjNZY929ao9I
 gkSwnGB/JBVBoFM+S8DiXT96zvz4oFX1njzZLPLEwedBmIKcvWAtw+H
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch driver to use dev_err_probe() to unify
error messages generated in *_probe() and probe path functions.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 59 ++++++++++++++++++---------------------------
 1 file changed, 24 insertions(+), 35 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 8eaa2cb6b5b044afdc405f19cd2499abb7e4d7a3..6f7c524d3a7a41c5177c9b02ebe1b7858294a0b4 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -707,21 +707,17 @@ static int opt3001_read_id(struct opt3001 *opt)
 	int ret;
 
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_MANUFACTURER_ID);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_MANUFACTURER_ID);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read register %02x\n",
+				     OPT3001_MANUFACTURER_ID);
 
 	manufacturer[0] = ret >> 8;
 	manufacturer[1] = ret & 0xff;
 
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_DEVICE_ID);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_DEVICE_ID);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read register %02x\n",
+				     OPT3001_DEVICE_ID);
 
 	device_id = ret;
 
@@ -739,11 +735,9 @@ static int opt3001_configure(struct opt3001 *opt)
 	u16 reg;
 
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_CONFIGURATION);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_CONFIGURATION);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read register %02x\n",
+				     OPT3001_CONFIGURATION);
 
 	reg = ret;
 
@@ -767,28 +761,22 @@ static int opt3001_configure(struct opt3001 *opt)
 	reg &= ~OPT3001_CONFIGURATION_FC_MASK;
 
 	ret = i2c_smbus_write_word_swapped(client, OPT3001_CONFIGURATION, reg);
-	if (ret < 0) {
-		dev_err(dev, "failed to write register %02x\n",
-			OPT3001_CONFIGURATION);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to write register %02x\n",
+				     OPT3001_CONFIGURATION);
 
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_LOW_LIMIT);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_LOW_LIMIT);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read register %02x\n",
+				     OPT3001_LOW_LIMIT);
 
 	opt->low_thresh_mantissa = OPT3001_REG_MANTISSA(ret);
 	opt->low_thresh_exp = OPT3001_REG_EXPONENT(ret);
 
 	ret = i2c_smbus_read_word_swapped(client, OPT3001_HIGH_LIMIT);
-	if (ret < 0) {
-		dev_err(dev, "failed to read register %02x\n",
-			OPT3001_HIGH_LIMIT);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(dev, ret, "failed to read register %02x\n",
+				     OPT3001_HIGH_LIMIT);
 
 	opt->high_thresh_mantissa = OPT3001_REG_MANTISSA(ret);
 	opt->high_thresh_exp = OPT3001_REG_EXPONENT(ret);
@@ -896,10 +884,10 @@ static int opt3001_probe(struct i2c_client *client)
 		ret = request_threaded_irq(irq, NULL, opt3001_irq,
 					   IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
 					   "opt3001", iio);
-		if (ret) {
-			dev_err(dev, "failed to request IRQ #%d\n", irq);
-			return ret;
-		}
+		if (ret)
+			return dev_err_probe(dev, ret,
+					     "failed to request IRQ #%d\n",
+					     irq);
 		opt->use_irq = true;
 	} else {
 		dev_dbg(dev, "enabling interrupt-less operation\n");
@@ -907,7 +895,8 @@ static int opt3001_probe(struct i2c_client *client)
 
 	ret = devm_iio_device_register(dev, iio);
 	if (ret)
-		return dev_err(dev, "failed to register IIO device\n");
+		return dev_err_probe(dev, ret,
+				     "failed to register IIO device\n");
 
 	return 0;
 }

-- 
2.47.3

