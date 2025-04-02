From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:14:13 +0200
Subject: [PATCH v3 1/5] iio: light: al3010: Improve al3010_init error
 handling with dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v3-1-cc3da273b5b2@ixit.cz>
References: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1211; i=david@ixit.cz;
 h=from:subject:message-id; bh=gTAVbM5fFc5QokjDQ95bD2qhmu90RRaffipzE9qAgeM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7Yy2z6bI5zDrIbRTccUfbKEF9zMRSlNwd1PrR
 ubGSiB3LI2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2MtgAKCRBgAj/E00kg
 ciPbD/0ehgt16z5hkaK1f7naswyW1uVnfcDGxIBm/LlIWktjEKGcdo1yeG9/NEgiE+LBTIi5iC7
 yb8cox7jEr9UQB1bR+NH+hzVLRKpQqaP9+0mZx3CIDybmTIXHe9Zg9mE8YSe//02dZ31zEubA19
 fDLroie4+fXRCvVMDlNUzECerX2za1s4TO8mpWDDm9CEHEKTRFTwZUIQmdanD7NnW7i2xJ4kuHs
 1PHschta+u8tjvmXkZf/YVXUea817/ekz5ztXaQC/uXTxPbRn4KJrBFqhiwBPd0cjmXi4sQ//ZV
 utVGiW9DVUEOZEu6ObXP+dCK/WGexoN78ae44W0ecyjKQ0SzkxswZlFIhfwMPE9gf88vPV0XfO5
 qDVtwdlP5u24a8y5axZccSIaYJy6MF7le0CHMcGKqTwBM5+gxvlkoY7H0qD09R2Fe9J7QbEt3sR
 Mj6rTqCLzxOAAm7DEBoiHqEJtqVxxIjvUIbwjYBoM4SBgGd2s5JfkkrsFO83mkJABw+6ZQtbPHO
 SqSlcO9D9z/haXAPhs+a+8v+ECCnj+DHRJXwonjpzbuSNO3wcuvl1DyBr7q8r/XygpMD7ZPHLoD
 bJYv8F+qZ0QrkTEe2XcfkpRjd0IOJWaf0+4sKo3LmseziDMzIC9rJkOEi+Ty7aVTVSp8rHrCDtM
 cMhGS4fORo77qUw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Minor code simplifications and improved error reporting.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 8c004a9239aef246a8c6f6c3f4acd6b760ee8249..0fcf4253864843142f1a7c61c9a92dcfbdf72a60 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -92,8 +92,8 @@ static int al3010_init(struct al3010_data *data)
 	ret = devm_add_action_or_reset(&data->client->dev,
 				       al3010_set_pwr_off,
 				       data);
-	if (ret < 0)
-		return ret;
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add action\n");
 
 	ret = i2c_smbus_write_byte_data(data->client, AL3010_REG_CONFIG,
 					FIELD_PREP(AL3010_GAIN_MASK,
@@ -190,10 +190,8 @@ static int al3010_probe(struct i2c_client *client)
 	indio_dev->modes = INDIO_DIRECT_MODE;
 
 	ret = al3010_init(data);
-	if (ret < 0) {
-		dev_err(dev, "al3010 chip init failed\n");
-		return ret;
-	}
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to init ALS\n");
 
 	return devm_iio_device_register(dev, indio_dev);
 }

-- 
2.49.0

