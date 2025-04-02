From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:33:24 +0200
Subject: [PATCH v4 1/5] iio: light: al3010: Improve al3010_init error
 handling with dev_err_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v4-1-d189bea87261@ixit.cz>
References: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1226; i=david@ixit.cz;
 h=from:subject:message-id; bh=N9LbC8OZWRVf5APMfHXIqkJb2k+lvKlkciNMNe3ltSs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7ZEJh1yMmYwBfvrQLmelKSsmcsjaMNsSDa+5P
 0kf0VvqhTSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2RCQAKCRBgAj/E00kg
 chxtD/0WlctxGyXcnUrf4p7CHbPuMELKfAxvnBa37etxVgIiupkvBozuv2OZFLb0k54yoHqicRK
 lXg/ymE0+bYEQLAuPXRY1rcsqp6UTB06K7+UCFGAvaCztqNq+IvX+UPvMipKao4Zi7mpFKEAac+
 RE53tvVjVL0hx6PjNb0iQR3hO+J5VRto5QPiH7TonoDY+XR36lHNKDXG6ni8SFCbliEDAAs7xAY
 eN28gGAhzj62mJi+guuQDGiJyHSQo+cmp99q9MUJhVtnayZHsxBcGbezIb6Kf0uKVeEZFay56PU
 lk916DZyPgvLzr6CdJglPDV1ZLga4G3XLSQpnalKmBafK+mumdiXcUR8RN9guWDx56n8eZrdERY
 pgmVkLUgofnWbzEv+eZ/7TS7DkBw4Gepo49H1UdAHSk4+UzrLAHneJZ6+4RWRHaIrjs7jQ6vQTz
 h8xxitKwxNK4Vt+qeOMsb9N2DS1dlKMx4SDxLcpW8ug1J8KQmsdeIlYrQ2Gb4WILEGSsAeZo6mD
 92QKBRtTMd+oLkW5NW1wRIYWXarIj9HWCivO9tikhs4ouqpxjEY0YBOS31qtZNQl1DkVcYFuYNx
 AEkDOY1e2c2v/Jyi6TTWy2f2iPta82pn8NDVJ+qX+DECsOLJQ5Jwuwvx6MThroE9pNyBUT0k996
 r81JE+n9uMZY6Jw==
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
index 8c004a9239aef246a8c6f6c3f4acd6b760ee8249..34a29a51c5f9e8aa143d3ba195b79a19793e4f88 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -92,8 +92,8 @@ static int al3010_init(struct al3010_data *data)
 	ret = devm_add_action_or_reset(&data->client->dev,
 				       al3010_set_pwr_off,
 				       data);
-	if (ret < 0)
-		return ret;
+	if (ret)
+		return dev_err_probe(&data->client->dev, ret, "failed to add action\n");
 
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

