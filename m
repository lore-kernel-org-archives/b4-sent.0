From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 21:14:14 +0200
Subject: [PATCH v3 2/5] iio: light: al3000a: Fix an error handling path in
 al3000a_probe()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-al3010-iio-regmap-v3-2-cc3da273b5b2@ixit.cz>
References: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
In-Reply-To: <20250402-al3010-iio-regmap-v3-0-cc3da273b5b2@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1374; i=david@ixit.cz;
 h=from:subject:message-id; bh=qQvDrqw+rZNARjQEY1+9cVvczIiceT4fSIl/q8P2uWQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7Yy31DPx1wXYhRoVsBn5uORAwDaRgaCShuFJV
 JL6J1pc50OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2MtwAKCRBgAj/E00kg
 cvYcD/0dByWa9SsXZP2okc2RI8wXLHViKiH3fw94LHQj4u+vaxOxffQunlUO+WFhK4adgWHuKgO
 rKM80wX+TJPzqwatOGycNRU8OkToFIOIjKAwN+YXIGkYE+dz9X071MRKrp+k2HHN7KFyVUm7zfq
 PLsnv7gX5g4VtbEQ0CIZrP0KD48P0xxV5eyUBuijiasz3G+LS/G+L1QIpkdCzlarnd6r2+GZ+oj
 IQnRy5Kk0zOmX9euaNty73QuLGKXoHWX9E8NctDu77wHVzZCQzhWlNPsOWrvgvM8Zx2k4lpXvbP
 Udxbg3q10uByIiX/co+SwtaFEnnQbkNAJOB7waW2Wsy5cpkadMHGRrYFMmp54Kcu6DjmXZWL93N
 XPw2CeCytmMZjWF51q0QZRRb+1emZQm3OreZo+EeTaCk3u36f+Qao1+qWvJ52WH2QO/0o4j97F/
 aYsEM1TWb1doyhj/NjC9QP7ClyoAfYELDlFYtGk60tVnVVqUqi5HeDoRVhIIMdweaAqWk4r7JKE
 usgj0VfEzLoENT8ajWBWdYTBrO0F3bMkjzz/XbgIaFHfDBqhyJAyNOOgMVFfu1t3V1IsIT1wZep
 R4W84Qak9Fx7alNLvb+Hq9pg3O7Ltu+083faecfCU9dLFJabamMNMHwOn1BlllZUfKTaSiICZ7+
 Aop13hKPWeMvfqQ==
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
 drivers/iio/light/al3000a.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/light/al3000a.c b/drivers/iio/light/al3000a.c
index e2fbb1270040f43d9f0a97838861818a8eaef813..e6208bfeb3be9040364463ef6d59a15d31e8700c 100644
--- a/drivers/iio/light/al3000a.c
+++ b/drivers/iio/light/al3000a.c
@@ -91,6 +91,10 @@ static int al3000a_init(struct al3000a_data *data)
 	if (ret)
 		return ret;
 
+	ret = devm_add_action_or_reset(&data->client->dev, al3000a_set_pwr_off, data);
+	if (ret)
+		return dev_err_probe(&data->client->dev, ret, "failed to add action\n");
+
 	ret = regmap_write(data->regmap, AL3000A_REG_SYSTEM, AL3000A_CONFIG_RESET);
 	if (ret)
 		return ret;
@@ -157,10 +161,6 @@ static int al3000a_probe(struct i2c_client *client)
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

