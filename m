From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Wed, 13 May 2026 16:35:52 +0200
Subject: [PATCH] iio: magnetometer: ak8975: ensure device is awake for
 buffered capture
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260513-ak8975-fix-v1-1-104ea605dd54@gmail.com>
X-B4-Tracking: v=1; b=H4sIAEeMBGoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDU0Nj3cRsC0tzU920zApdU+MkwyQDIwtT85QUJaCGgqJUoDDYsOjY2lo
 AUQqcPFwAAAA=
X-Change-ID: 20260513-ak8975-fix-53b1b02857dd
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Gregor Boirie <gregor.boirie@parrot.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sashiko <sashiko-bot@kernel.org>, Joshua Crofts <joshua.crofts1@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778682953; l=2687;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=t9KRDGrt1AwFqcezKrfyVWVsvRmTCT6cOir8KV8zCzQ=;
 b=pgfmeaJf5C7P8Kn+b50rdXeQMnMKI9HhvqalTRYgdX7Eq+EWidWuVRKwcWCLx5AcFXZbiwSLr
 4X08gT1EMmsB50JpPvnF/vYqgneka5z8V/FvPwo3WN3l+IchwNVM0yv
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, the ak8975_start_read_axis() can be called while the device
is autosuspended, causing two issues:

1. I2C transfers in the aforementioned function will fail or timeout
because ak8975_runtime_suspend() disables the device regulators.
2. Since ak8975_fill_buffer() does not hold runtime references,
ak8975_runtime_suspend() can run concurrently, and since PM callbacks
do not use a locking mechanism, it may cause a race accessing the
control register via the I2C bus.

Fix this issue by adding struct iio_buffer_setup_ops that contains
preenable and postdisable functions to ensure correct that device is
powered on when running a buffered capture.

Fixes: bc11ca4a0b84 ("iio:magnetometer:ak8975: triggered buffer support")
Reported-by: Sashiko <sashiko-bot@kernel.org>
Closes: https://sashiko.dev/#/patchset/20260511-magnetometer-fixes-post-pickup-v7-0-9d910faa28b6%40gmail.com
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/magnetometer/ak8975.c | 24 +++++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/magnetometer/ak8975.c b/drivers/iio/magnetometer/ak8975.c
index dbab4d0bba348be70e5c8b71678de935879bff42..0fb2fd03d11ce195a67949056c000c473a8d3e99 100644
--- a/drivers/iio/magnetometer/ak8975.c
+++ b/drivers/iio/magnetometer/ak8975.c
@@ -899,6 +899,28 @@ static irqreturn_t ak8975_handle_trigger(int irq, void *p)
 	return IRQ_HANDLED;
 }
 
+static int ak8975_buffer_preenable(struct iio_dev *indio_dev)
+{
+	struct ak8975_data *data = iio_priv(indio_dev);
+	struct device *dev = &data->client->dev;
+
+	return pm_runtime_resume_and_get(dev);
+}
+
+static int ak8975_buffer_postdisable(struct iio_dev *indio_dev)
+{
+	struct ak8975_data *data = iio_priv(indio_dev);
+	struct device *dev = &data->client->dev;
+
+	pm_runtime_put_autosuspend(dev);
+
+	return 0;
+}
+
+static const struct iio_buffer_setup_ops ak8975_buffer_setup_ops = {
+	.preenable = ak8975_buffer_preenable,
+	.postdisable = ak8975_buffer_postdisable,
+};
 static int ak8975_probe(struct i2c_client *client)
 {
 	const struct i2c_device_id *id = i2c_client_get_device_id(client);
@@ -992,7 +1014,7 @@ static int ak8975_probe(struct i2c_client *client)
 	indio_dev->name = name;
 
 	ret = iio_triggered_buffer_setup(indio_dev, NULL, ak8975_handle_trigger,
-					 NULL);
+					 &ak8975_buffer_setup_ops);
 	if (ret) {
 		dev_err(&client->dev, "triggered buffer setup failed\n");
 		goto power_off;

---
base-commit: 1548c54e9adc32a719499216f63fba14b2fc07c3
change-id: 20260513-ak8975-fix-53b1b02857dd

Best regards,
-- 
Joshua Crofts <joshua.crofts1@gmail.com>

