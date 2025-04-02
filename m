From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:14:15 +0200
Subject: [PATCH v3 3/5] iio: light: al3320a: Fix an error handling path in
 al3320a_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v3-3-cc3da273b5b2@ixit.cz>
References: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1336; i=david@ixit.cz;
 h=from:subject:message-id; bh=xUR9gZOnjOoo0snJLgIn15f7Ro6lut1DvCDtNBnZliU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7Yy3HOIVp0gNPuYuFIC9TWknQMBqKiZtTfBDQ
 NHggVCvdbOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2MtwAKCRBgAj/E00kg
 ci+oEACT4SQ9qhj6AogU5XSeGSWVeoJmSF1/gDjIJFsYEk4x+IMWOilEld9etR8R9AVLgIIUz2N
 M9XEf73ktQ/UQNqq1Y6qRuRvWCOWW7QLYMFR6g0ufFcxfMRwQTpHfEQrTJfWfAvR5iDxuwqW7aD
 AhqQOR0tskfNAd4UTdWkKWqILRrcJW1Md9422fRpwNlFasiCAKMhaoGltqJULcFclEAw4y0eVtK
 6w+LB1dR4R8YOU1kQmMJ6a6BzjpYezVSK6dOIBUw6L0UhO2ZDRWvXXPIntRIHq62Gg5XfCt0cXd
 Y4LIdBmPwonGzkVzGkBXeybA1dd7rDtXvdqv+eB3NRt0Um6+swHgVKDA2/BXkwwt/88/5e8afj7
 ph4GQH84p1GCEeudA5uGU64zN29pbQ8T+UpesfiT3XT2FV5siAuNedItlWrxu6bVJZBiVx/eGAH
 JlfIVjOvS3Qc77l+RODFHHDMySEZuQc8gnqN5isvQpjivajDa49PcikSQqZnHbAq5hhTsdRfGpb
 zJuJAeAIlyPpDH9c7R06S9WVyu9EpEcC7ceiWSQXrBXiaOmatqCvuAIb5NBXjIU+Bsvs24nJw5j
 YHDpQE6BMy8L2TIMAfn+VlR993h+krjuEwYaXVeN2FTjJN9uLTZ9vLqKPPRz3OMeGA8XOJlQqX+
 53gPEkok5JDFmDw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If regmap_write() fails in al3320a_init(), al3320a_set_pwr_off is
not called.

In order to avoid such a situation, move the devm_add_action_or_reset()
which calls al3320a_set_pwr_off right after a successful
al3320a_set_pwr_on.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3320a.c | 10 ++++++----
 1 file changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3320a.c b/drivers/iio/light/al3320a.c
index 1b2b0359ed5dad5e00d2fe584f8f3495c13c997e..005a7664568667b5cf9419baba6764f7b4e8fc39 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -101,6 +101,12 @@ static int al3320a_init(struct al3320a_data *data)
 	if (ret < 0)
 		return ret;
 
+	ret = devm_add_action_or_reset(&data->client->dev,
+				       al3320a_set_pwr_off,
+				       data);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add action\n");
+
 	ret = i2c_smbus_write_byte_data(data->client, AL3320A_REG_CONFIG_RANGE,
 					FIELD_PREP(AL3320A_GAIN_MASK,
 						   AL3320A_RANGE_3));
@@ -211,10 +217,6 @@ static int al3320a_probe(struct i2c_client *client)
 		return ret;
 	}
 
-	ret = devm_add_action_or_reset(dev, al3320a_set_pwr_off, data);
-	if (ret < 0)
-		return ret;
-
 	return devm_iio_device_register(dev, indio_dev);
 }
 

-- 
2.49.0

