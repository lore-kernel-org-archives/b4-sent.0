From: Vasiliy Doylov <nekodevelopper@gmail.com>
Date: Thu, 16 Jan 2025 16:52:43 +0300
Subject: [PATCH RESEND v4 2/5] iio: accel: mc3230: add mount matrix support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250116-mainlining-mc3510c-v4-2-a41308b85ec2@gmail.com>
References: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
In-Reply-To: <20250116-mainlining-mc3510c-v4-0-a41308b85ec2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Vasiliy Doylov <nekodevelopper@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1923;
 i=nekodevelopper@gmail.com; h=from:subject:message-id;
 bh=d1xov0qHxHQE7DYG5yJ4wuLkWhZ9BJAbb56t/my19Lo=;
 b=owGbwMvMwCW2fZ/SFZeSpU2Mp9WSGNI7+aNeRk6+etuiRaS3h7PIomXOnduf2J4b8shpmkeH3
 4t4lrC/o5SFQYyLQVZMkcVmo8dssfxwyUnTnirAzGFlAhnCwMUpABN5k8Twv3jqYmetEJtHX/oU
 lnw9whdpHl1SpXV9rsKVWXx/fZrnfWX4p/pwycFwYYtZ13yuabqKHDrB/p7h2NEnDEKhm183KVt
 osgMA
X-Developer-Key: i=nekodevelopper@gmail.com; a=openpgp;
 fpr=3CB1489B166F57199296E520B7BE22D44474A582
X-Endpoint-Received: by B4 Relay for nekodevelopper@gmail.com/default with auth_id=314
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch allows to read a mount-matrix device tree property and report
to user-space or in-kernel iio clients.

Signed-off-by: Vasiliy Doylov <nekodevelopper@gmail.com>
---
 drivers/iio/accel/mc3230.c | 28 ++++++++++++++++++++++++----
 1 file changed, 24 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/accel/mc3230.c b/drivers/iio/accel/mc3230.c
index caa40a14a6316acae3a972f0ebe0b325db96eb44..48787c0494ae6f0ef1d4d22bc5a4608035cbe123 100644
--- a/drivers/iio/accel/mc3230.c
+++ b/drivers/iio/accel/mc3230.c
@@ -44,18 +44,34 @@ static const int mc3230_nscale = 115411765;
 	.channel2 = IIO_MOD_##axis,	\
 	.info_mask_separate = BIT(IIO_CHAN_INFO_RAW),	\
 	.info_mask_shared_by_type = BIT(IIO_CHAN_INFO_SCALE),	\
+	.ext_info = mc3230_ext_info, \
 }
 
+struct mc3230_data {
+	struct i2c_client *client;
+	struct iio_mount_matrix orientation;
+};
+
+static const struct iio_mount_matrix *
+mc3230_get_mount_matrix(const struct iio_dev *indio_dev,
+			const struct iio_chan_spec *chan)
+{
+	struct mc3230_data *data = iio_priv(indio_dev);
+
+	return &data->orientation;
+}
+
+static const struct iio_chan_spec_ext_info mc3230_ext_info[] = {
+	IIO_MOUNT_MATRIX(IIO_SHARED_BY_DIR, mc3230_get_mount_matrix),
+	{ }
+};
+
 static const struct iio_chan_spec mc3230_channels[] = {
 	MC3230_CHANNEL(MC3230_REG_XOUT, X),
 	MC3230_CHANNEL(MC3230_REG_YOUT, Y),
 	MC3230_CHANNEL(MC3230_REG_ZOUT, Z),
 };
 
-struct mc3230_data {
-	struct i2c_client *client;
-};
-
 static int mc3230_set_opcon(struct mc3230_data *data, int opcon)
 {
 	int ret;
@@ -141,6 +157,10 @@ static int mc3230_probe(struct i2c_client *client)
 	if (ret < 0)
 		return ret;
 
+	ret = iio_read_mount_matrix(&client->dev, &data->orientation);
+	if (ret)
+		return ret;
+
 	ret = iio_device_register(indio_dev);
 	if (ret < 0) {
 		dev_err(&client->dev, "device_register failed\n");

-- 
2.47.1

