From: Carlos Casadiego <cdcp206@gmail.com>
Date: Wed, 23 Sep 2026 11:41:09 -0500
Subject: [PATCH] iio: accel: bmc150: check reset write error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-iio-bmc150-check-reset-error-v1-1-b8c1ebc4c947@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAwAwK+Qnm1SFiSuXzEe2FKlGlnTojEh/
 J1Vj3OZBVxMxeFYLWDyVtc8FdS7Cnjsp6ugDsUQKHQUQ4OqGdOD6z0hj8J3NHGZUcyyYXOIiWK
 XqB9aKMXT5KKfX386/+2vdBOevyes6wbj/wpQgAAAAA==
X-Change-ID: 20260923-iio-bmc150-check-reset-error-389b096b0ad4
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 Olof Johansson <olof@lixom.net>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Carlos Casadiego <cdcp206@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790181679; l=1470;
 i=cdcp206@gmail.com; s=20260921; h=from:subject:message-id;
 bh=/m+IAGs3XggeHKu/8l8GGOqvK7/NA+SldvDa51UHcTk=;
 b=PV+jE0pGryQUCC8m92s6Apv9hpHrmcfYBH0ZPTF51ofV9egs8H2Kp63iaB7Zh4H6RfXb6VZXJ
 Wz7oJk1a85GCNR9yqUP1X5WpTpE5s6cHPB8pILCuzt8IPRdHAbHxfnq
X-Developer-Key: i=cdcp206@gmail.com; a=ed25519;
 pk=Vr3c2AUi1oYbgVkQtRSsWin33frZn0vGGq5g04VWmH8=
X-Endpoint-Received: by B4 Relay for cdcp206@gmail.com/20260921 with auth_id=1041
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The software reset is required to bring the device into a known
state before reading the chip ID.

Check the return value of regmap_write() and abort initialization if
the reset command cannot be written.

Fixes: 1c500840934a ("iio: accel: bmc150: reset chip at init time")

Signed-off-by: Carlos Casadiego <cdcp206@gmail.com>
---
 drivers/iio/accel/bmc150-accel-core.c | 8 ++++++--
 1 file changed, 6 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/accel/bmc150-accel-core.c b/drivers/iio/accel/bmc150-accel-core.c
index 46bb36d9366e..43a39e1ccce5 100644
--- a/drivers/iio/accel/bmc150-accel-core.c
+++ b/drivers/iio/accel/bmc150-accel-core.c
@@ -1561,8 +1561,12 @@ static int bmc150_accel_chip_init(struct bmc150_accel_data *data)
 	 * Reset chip to get it in a known good state. A delay of 1.8ms after
 	 * reset is required according to the data sheets of supported chips.
 	 */
-	regmap_write(data->regmap, BMC150_ACCEL_REG_RESET,
-		     BMC150_ACCEL_RESET_VAL);
+	ret = regmap_write(data->regmap, BMC150_ACCEL_REG_RESET,
+			   BMC150_ACCEL_RESET_VAL);
+	if (ret < 0) {
+		dev_err(dev, "Error writing reset register\n");
+		return ret;
+	}
 	usleep_range(1800, 2500);
 
 	ret = regmap_read(data->regmap, BMC150_ACCEL_REG_CHIP_ID, &val);

---
base-commit: d8c0f48f0b1583308a98401c0c7b1a65d1d43a6c
change-id: 20260923-iio-bmc150-check-reset-error-389b096b0ad4

Best regards,
--  
Carlos Casadiego <cdcp206@gmail.com>

