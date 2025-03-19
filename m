From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Mar 2025 21:59:46 +0100
Subject: [PATCH v2 07/13] iio: light: al3010: Split set_pwr function into
 set_pwr_on and _off
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250319-al3010-iio-regmap-v2-7-1310729d0543@ixit.cz>
References: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
In-Reply-To: <20250319-al3010-iio-regmap-v2-0-1310729d0543@ixit.cz>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Robert Eckelmann <longnoserob@gmail.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1909; i=david@ixit.cz;
 h=from:subject:message-id; bh=vOib51/xpneU1DtWyRjsNY1gpYkAaqRHzYSkX1BUJo4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2zA+WhBZQES0+91AU6m/fyiF7GLrpJGg7rPU1
 6XKQBu1L5WJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9swPgAKCRBgAj/E00kg
 cmZXEAC7DBAsyzOMQiY4z3k4WVrDST/JuGR/9IbmZR5bsN+EolCvK/H5ebgdwn+vv9f9wRtriwZ
 OSFAwwe3dA1ukqDpX/LHSnMKJkglDtJA74Fz+nY+Ekj50U0YNw2D0BFY/dvpvgMlmyjSTNufdVJ
 +riBrfQW5odlIrMSR9WpzItSc5Zc771yUSOwYwa1l11JXTCyLS+SMo9o2SskhqLwnfbYi0v20kl
 aQaw+weS54MsuX4JKI6zEaiqKWwlE39JIQWVlxYakPiG9y4LvR0v7A88ssfBb+zoYiGYT4CD6Nh
 sRYJeVnylBfWWJ42ttQMPlju9FDQtpt4CBIUyWTlPaedtSEahIIRHH+OWCHmrVJi/nbhqiRvN4M
 kmkeMLboSRbE6bDovJF6fQAcNh4ZFHDTEupZSl/bmV5RmfyjwHzRT3m84R8J/Q0HBtXfXuydYbN
 v/WQhzYWmchBJurPLyWvTDVi02OzBj3q36wvhtvujqDMXGY3ua85KuOjX85rqG6Cz+9k76tgs6D
 5Mm7Dkf2QRDBqUbS0WYKJMeODbYtMv9Kr0NVBHeRLH/RBYgPVDrg84RWAVvyYESTvCJj7Dd3FNd
 VyLm4No5LRQBv6ukxvpLzK5O/c8Uf2CNnG5yIUSjnwOZu5Ye4KsonP64qrKWnVvaQuWMlWtlIT8
 jW4K0/0RXq0cP3g==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simplifies later conversion to the regmap framework.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/iio/light/al3010.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/drivers/iio/light/al3010.c b/drivers/iio/light/al3010.c
index c8f528f3636a2eb0f0c9586da64a6560d4b42e29..8c004a9239aef246a8c6f6c3f4acd6b760ee8249 100644
--- a/drivers/iio/light/al3010.c
+++ b/drivers/iio/light/al3010.c
@@ -67,24 +67,25 @@ static const struct attribute_group al3010_attribute_group = {
 	.attrs = al3010_attributes,
 };
 
-static int al3010_set_pwr(struct i2c_client *client, bool pwr)
+static int al3010_set_pwr_on(struct i2c_client *client)
 {
-	u8 val = pwr ? AL3010_CONFIG_ENABLE : AL3010_CONFIG_DISABLE;
-	return i2c_smbus_write_byte_data(client, AL3010_REG_SYSTEM, val);
+	return i2c_smbus_write_byte_data(client, AL3010_REG_SYSTEM,
+					 AL3010_CONFIG_ENABLE);
 }
 
 static void al3010_set_pwr_off(void *_data)
 {
 	struct al3010_data *data = _data;
 
-	al3010_set_pwr(data->client, false);
+	i2c_smbus_write_byte_data(data->client, AL3010_REG_SYSTEM,
+				  AL3010_CONFIG_DISABLE);
 }
 
 static int al3010_init(struct al3010_data *data)
 {
 	int ret;
 
-	ret = al3010_set_pwr(data->client, true);
+	ret = al3010_set_pwr_on(data->client);
 	if (ret < 0)
 		return ret;
 
@@ -199,12 +200,15 @@ static int al3010_probe(struct i2c_client *client)
 
 static int al3010_suspend(struct device *dev)
 {
-	return al3010_set_pwr(to_i2c_client(dev), false);
+	struct al3010_data *data = iio_priv(dev_get_drvdata(dev));
+
+	al3010_set_pwr_off(data);
+	return 0;
 }
 
 static int al3010_resume(struct device *dev)
 {
-	return al3010_set_pwr(to_i2c_client(dev), true);
+	return al3010_set_pwr_on(to_i2c_client(dev));
 }
 
 static DEFINE_SIMPLE_DEV_PM_OPS(al3010_pm_ops, al3010_suspend, al3010_resume);

-- 
2.49.0

