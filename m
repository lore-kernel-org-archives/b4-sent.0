From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:33:25 +0200
Subject: [PATCH v4 2/5] iio: light: al3000a: Fix an error handling path in
 al3000a_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v4-2-d189bea87261@ixit.cz>
References: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v4-0-d189bea87261@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1507; i=david@ixit.cz;
 h=from:subject:message-id; bh=66tuh0qra+186i8PqZ9MH09vmloKVLdmfLyT9O7NZJA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7ZEKK38jVBmHNU7CFYig14RDpWa0ZY1lj8pTo
 eVvHE5NkY2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2RCgAKCRBgAj/E00kg
 cpyqD/0cFgarWExeX/tExe5FTLgYJPq0Xq/kck8yd71Vru/LfC7yA9BE4BFt3NlSei5tUJQxpmj
 O1WY8H3w5psDaJWwr2sfyEknwDwb66cXaQiX2cG7dQ9TOFeOuSbjEGTuJGlfs5ezPnQBSdyYeKp
 R4wdUo7vJ7fQx9AWhSiuw5IbhCsoSW81QzkFrCsJYw7DA961cT81OYXdGZcVqP1aiZ9c5fL5J+1
 0ETI6JxPm7Vn0AxfiiRxpKaWEtQiR9O4OSIE4o/i95svsqMKMEb9ydJUEUssq0tovzzyTfeyPsU
 aiosITW0pjausm2HFfR51+Mp0yzjY4kOat6jWXBxtE4akF5dce5gtaBlxVbdNnQHxB5/C0CvY/m
 LBniBGgCT9TGk5mwVB41NyRWGv+n4KTuJs57qVNrM1WU1BECDlM3CKOT+6bm/azv5CmW1uKtz6l
 bEO1XPNUo8OEYFnWFALsHmMWEIQl1KW9YIyPx72tQYfq01r3sPnzF+P7j6iud1Z8YgNb3lg1LIe
 7D7lHzKIe/wFWEFnQyC9MRvc1q3DnKZDzpiziZaMW/iRJ/2WIUfyYQkbsNJoCbqPh2Vo5FnbMJ2
 Krxg39SDlLW5EHMLo9wVab5OqosY98PV4D5jfgv+DyQ3do/lMfpLgxdDdOvjVl8VX462e4xLy5g
 lkUx24OLatH7t0w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If regmap_write() fails in al3000a_init(), al3000a_set_pwr_off is
not called.

In order to avoid such a situation, move the devm_add_action_or_reset()
which calls al3000a_set_pwr_off right after a successful
al3000a_set_pwr_on.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3000a.c | 9 +++++----
 1 file changed, 5 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3000a.c b/drivers/iio/light/al3000a.c
index e2fbb1270040f43d9f0a97838861818a8eaef813..6d5115b2a06c5acce18d831b9c41d3d5121fba12 100644
--- a/drivers/iio/light/al3000a.c
+++ b/drivers/iio/light/al3000a.c
@@ -85,12 +85,17 @@ static void al3000a_set_pwr_off(void *_data)
 
 static int al3000a_init(struct al3000a_data *data)
 {
+	struct device *dev = regmap_get_device(data->regmap);
 	int ret;
 
 	ret = al3000a_set_pwr_on(data);
 	if (ret)
 		return ret;
 
+	ret = devm_add_action_or_reset(dev, al3000a_set_pwr_off, data);
+	if (ret)
+		return dev_err_probe(dev, ret, "failed to add action\n");
+
 	ret = regmap_write(data->regmap, AL3000A_REG_SYSTEM, AL3000A_CONFIG_RESET);
 	if (ret)
 		return ret;
@@ -157,10 +162,6 @@ static int al3000a_probe(struct i2c_client *client)
 	if (ret)
 		return dev_err_probe(dev, ret, "failed to init ALS\n");
 
-	ret = devm_add_action_or_reset(dev, al3000a_set_pwr_off, data);
-	if (ret)
-		return dev_err_probe(dev, ret, "failed to add action\n");
-
 	return devm_iio_device_register(dev, indio_dev);
 }
 

-- 
2.49.0

