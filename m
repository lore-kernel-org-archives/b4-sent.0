From: Carlos Casadiego <cdcp206@gmail.com>
Date: Thu, 24 Sep 2026 09:48:45 -0500
Subject: [PATCH v2] iio: accel: bmc150: check reset write error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-iio-bmc150-check-reset-error-v2-1-b6dc74d7aaf4@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBAAv0J6dk1bEKkn/2E40GWFVaFmi0RD+
 LuAH/A4yWRmUpGEKapTMimhkSOHfgG7SxS2Vd8QcL2wstrm2tkUmAP4Ds1BA7aEdxCKNACJBIG
 0cF673OuqztSSeApd+b3lL+WP48vfCIe1uRotxyHIZ/uPZvX+XI0GDPgCDXnM0GXHc9NV/Nhj6
 FQ5z/MX4NnWPtoAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790261326; l=1746;
 i=cdcp206@gmail.com; s=20260921; h=from:subject:message-id;
 bh=atwOd5gI9arDmyV4IEUHyQAiqnNRy5dIUk3BoqWk3+c=;
 b=mEHoTVdxu3VMl/0b9gO1YV64W44bmxiEmvbvwx/2Lu1pIOsoI48RyKRsPrWzpmJw73rtgmWY+
 kDwFPxka/UyBfg9qmxEtgbADY99HVaA4Dx5HmybtcB3OGeQvMSDH72C
X-Developer-Key: i=cdcp206@gmail.com; a=ed25519;
 pk=Vr3c2AUi1oYbgVkQtRSsWin33frZn0vGGq5g04VWmH8=
X-Endpoint-Received: by B4 Relay for cdcp206@gmail.com/20260921 with auth_id=1041
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The software reset is required to bring the device into a known
state before reading the chip ID.

Check the return value of regmap_write() and abort initialization if
the reset command cannot be written.

Fixes: 1c500840934a ("iio: accel: bmc150: reset chip at init time")
Acked-by: Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>
Signed-off-by: Carlos Casadiego <cdcp206@gmail.com>
---
Changes in v2:
- Remove the blank line in the tag block.
- Add Srinivas Pandruvada's Acked-by.
- Link to v1: https://patch.msgid.link/20260923-iio-bmc150-check-reset-error-v1-1-b8c1ebc4c947@gmail.com
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

