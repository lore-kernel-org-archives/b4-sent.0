From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Mon, 11 May 2026 12:04:08 +0200
Subject: [PATCH 3/7] iio: light: opt3001: prefer dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260511-opt3001-cleanup-v1-3-f7879dc3455c@gmail.com>
References: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
In-Reply-To: <20260511-opt3001-cleanup-v1-0-f7879dc3455c@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778493846; l=3152;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=4ZDg+2cFad43kksEtMJuHN/u9FLl2280zxG04zaNsxE=;
 b=1g/fiGvY8NnoA6DuWmEFYwmGom/Fg0mRoQLsNJQtHDXZSuc6X8TN85KKdGqyty4PKi5PpAWai
 OdlwBXYVnuFCa8qr+j3IjM+J7ch7zSe3OTuhjuWyxjJrcsjVzNVV5lP
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch driver to use dev_err_probe() to unify
error messages generated in *_probe() and probe path functions.

Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 51 ++++++++++++++++++++-------------------------
 1 file changed, 23 insertions(+), 28 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 47f0e01a95e772954de0f1337ac0d881b8b32de6..4d9a17be04555aca368f7bc70a9d9a47fb5b279e 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -723,11 +723,10 @@ static int opt3001_configure(struct opt3001 *opt)
 	u16 reg;
 
 	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_CONFIGURATION);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_CONFIGURATION);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(opt->dev, ret,
+				     "failed to read register %02x\n",
+				     OPT3001_CONFIGURATION);
 
 	reg = ret;
 
@@ -752,28 +751,25 @@ static int opt3001_configure(struct opt3001 *opt)
 
 	ret = i2c_smbus_write_word_swapped(opt->client, OPT3001_CONFIGURATION,
 			reg);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to write register %02x\n",
-				OPT3001_CONFIGURATION);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(opt->dev, ret,
+				     "failed to write register %02x\n",
+				     OPT3001_CONFIGURATION);
 
 	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_LOW_LIMIT);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_LOW_LIMIT);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(opt->dev, ret,
+				     "failed to read register %02x\n",
+				     OPT3001_LOW_LIMIT);
 
 	opt->low_thresh_mantissa = OPT3001_REG_MANTISSA(ret);
 	opt->low_thresh_exp = OPT3001_REG_EXPONENT(ret);
 
 	ret = i2c_smbus_read_word_swapped(opt->client, OPT3001_HIGH_LIMIT);
-	if (ret < 0) {
-		dev_err(opt->dev, "failed to read register %02x\n",
-				OPT3001_HIGH_LIMIT);
-		return ret;
-	}
+	if (ret < 0)
+		return dev_err_probe(opt->dev, ret,
+				     "failed to read register %02x\n",
+				     OPT3001_HIGH_LIMIT);
 
 	opt->high_thresh_mantissa = OPT3001_REG_MANTISSA(ret);
 	opt->high_thresh_exp = OPT3001_REG_EXPONENT(ret);
@@ -875,20 +871,19 @@ static int opt3001_probe(struct i2c_client *client)
 	iio->info = &opt3001_info;
 
 	ret = devm_iio_device_register(dev, iio);
-	if (ret) {
-		dev_err(dev, "failed to register IIO device\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret,
+				     "failed to register IIO device\n");
 
 	/* Make use of INT pin only if valid IRQ no. is given */
 	if (irq > 0) {
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
 		dev_dbg(opt->dev, "enabling interrupt-less operation\n");

-- 
2.47.3

