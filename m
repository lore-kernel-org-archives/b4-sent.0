From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:33:26 +0200
Subject: [PATCH v4 3/5] iio: light: al3320a: Fix an error handling path in
 al3320a_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v4-3-d189bea87261@ixit.cz>
References: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1351; i=david@ixit.cz;
 h=from:subject:message-id; bh=mTCyccBifllmHJInqLXe+hdaL4JlCXkaIIsicpjyZMI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7ZEKD01cnC8iLLj/aKn9pjzrLDbyH8bXtPAtv
 DYzhSepiJmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2RCgAKCRBgAj/E00kg
 cn40D/4rxElhV51cdYCOw82WrQd5fsVyC4nEuiCh6arve9ful8lyPDhnPhg6MetJKlLfbs0WajM
 3CLobiP4r+k/hpdQDGdWp5tEaWKjS2V9jIwaUcH+YPRTDthrELoonuiuz3jQs9DUEE6IdYlED3m
 K0mZYyZE9McWqU4dflZnSL94SdQ0PUyCqdA6gO0OMg0/9NHcW6UF8dawdpUQg4WEEw618Xux2b/
 FLm2bRHHJd3Ex8gpmxe/bX/vxo3KNRG7YZpEeXX4Y6YNlyRQ7mT6bjAiN1BrmfEs9DQa07+WKa+
 1tnVXBGrgNDWheBD3V0L1u5GOfJxN6nXZEC8c5uRFsMGNEr+BSDRZYv/CPmE4tNjyXRIew1XR2J
 MnLWn0rM6XaqEjF64qz5LNaHCkHXJdUdMJZaNnIfRf64u1Acz4s4U4UQjkJEBLad++BYEsMmXat
 n1Br9SUN7Djazuzk0HIb3ToFHxl/OxxmGA5GT/wRSXJ3/wCAhCS3emABlcJc3XCnxYo0D2KNA7N
 g1f1sJO/NTko0v/N0W4atSQj93rGZmz7HTe6wRHBsxcT/ofVhVaDoFXSI07ApYztjxblVXd9eiU
 5rYS+IaxRWEis0D1cTP0k/XZq6jxe6Au8KpS4+E7IXbF2INLTCgsuXBB04thIDA876bJkmxgybW
 ivarTCdU7lFr+Bg==
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
index 1b2b0359ed5dad5e00d2fe584f8f3495c13c997e..1fa693d54ae2a6e5ead3a9c7ac7018afeba9b760 100644
--- a/drivers/iio/light/al3320a.c
+++ b/drivers/iio/light/al3320a.c
@@ -101,6 +101,12 @@ static int al3320a_init(struct al3320a_data *data)
 	if (ret < 0)
 		return ret;
 
+	ret = devm_add_action_or_reset(&data->client->dev,
+				       al3320a_set_pwr_off,
+				       data);
+	if (ret)
+		return dev_err_probe(&data->client->dev, ret, "failed to add action\n");
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

