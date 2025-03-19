From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:48 +0100
Subject: [PATCH v2 09/13] iio: light: al3010: Move devm_add_action_or_reset
 back to _probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-9-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1174; i=david@ixit.cz;
 h=from:subject:message-id; bh=lxmXVhzbE/KiGpK6qJA+6k8UM9RsJY9i0gVwY5uqpFA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA+2mIlnZ7Ts//k4qsOCt/jeIP0gzh0IYaBJ
 SKZzJPlZdaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPgAKCRBgAj/E00kg
 cm9jD/9j8a2y5krkAfkMDghPKwG65bzMOGiMfuuCIj5JD2TbLRz8zuMrmp7TXNnbecdfO8VVP34
 RkndudsNxfztde/l1Z4vXf0BOTsuBDUYNOsjgvSXS2TxXpodcyP/dzjtgeYAnPSaA6rsdn1QqAD
 NvSEyZ6Z49Ql/tuet6ogK3kJkDg6NsafIh4FrzRsVEAyWowO4kix60tiX/LyNqo6dzcpaDTGuFO
 rGINVyJ06M3+/2FxxOK6ceQbak99dX3k5pOxYhTn30gz5aCk3ZTrG25QisQJ+S8gR8RHJ1QibV5
 ytcFVvdNQCsCwxvng3bWYvH1WolzkTNzBB6QYMxREjMGDDP75oFANs6HhpTYt26WWkkkeyzow2h
 0XZg74JHa4mZObQ+/5TP9XOB5Ep54ZYZHSAJvcfEBNNutKg6ZX5+6FsDDCuQMV49UIu/H0juEuL
 KfgW0qpAFaPGRudUGIhtG3OPjCBchGny1w1AOqizDbTbWof86QxAmsQ58rGMGCgnuuHAS+ZLNR0
 ycIwkUmdkB9LPN25slW8f1e/o1ngR32FcMn8giN7+4mRvMkKcO1VhUsNgxJPahPslfXSaAhV7+O
 dO3V8cqRhY89drdgrTUrDOeeqLxJHkpcQVrj6R/CD9QV0sYO7wPUy7Q5TEH6ZGeAtKnXm4ktDwY
 ijmMGMJqyF8drWQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In a preparation to the regmap transition.

Improve error handling using dev_err_probe().

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 10 ++++------
 1 file changed, 4 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index 8c004a9239aef246a8c6f6c3f4acd6b760ee8249..8098c92c9572befe92d00ef0785ded5e1a08d587 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -89,12 +89,6 @@ static int al3010_init(struct al3010_data *data)
 	if (ret < 0)
 		return ret;
 
-	ret = devm_add_action_or_reset(&data->client->dev,
-				       al3010_set_pwr_off,
-				       data);
-	if (ret < 0)
-		return ret;
-
 	ret = i2c_smbus_write_byte_data(data->client, AL3010_REG_CONFIG,
 					FIELD_PREP(AL3010_GAIN_MASK,
 						   AL3XXX_RANGE_3));
@@ -195,6 +189,10 @@ static int al3010_probe(struct i2c_client *client)
 		return ret;
 	}
 
+	ret = devm_add_action_or_reset(dev, al3010_set_pwr_off, data);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add action\n");
+
 	return devm_iio_device_register(dev, indio_dev);
 }
 

-- 
2.49.0

