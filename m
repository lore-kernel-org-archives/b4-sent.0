From: Markus Koeniger <markus.koeniger@liebherr.com>
Date: Mon, 22 Dec 2025 15:50:04 +0100
Subject: [PATCH] iio: accel: iis328dq: fix gain values
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-iio-accel-iis328dq-fix-gains-v1-1-c2f337703e91@liebherr.com>
X-B4-Tracking: v=1; b=H4sIAJtaSWkC/x2MwQqDQAwFf0VybsB9paL9FelhXaMGZK0bEEH89
 4beZhiYi0yKitG7uqjIoaZbdgmPitIS8yysozuhxisAYNWNY0qyOtkT7bjzpCfPUbNxQhumrmv
 CAJAvvkU8/vf9575/L+y9UG4AAAA=
X-Change-ID: 20251222-iio-accel-iis328dq-fix-gains-c281f9961b22
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Fedrau <dima.fedrau@gmail.com>, 
 Dimitri Fedrau <dimitri.fedrau@liebherr.com>, 
 Markus Koeniger <markus.koeniger@liebherr.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766415022; l=3546;
 i=markus.koeniger@liebherr.com; s=20251222; h=from:subject:message-id;
 bh=wdugeHElWqIVhDug3MqNblDVssp1zP7JHfNEZkrVJVg=;
 b=phZfpOMPnViHuDnukeNdRgQap90KPTDiZjxV6lJ8s5X3BDGHGxHIs/YgqKEyZGPFeUPNSrjog
 gwsVe4uCsltA1IuicUguRcoxJPAWk+Rj/E3CvEB2PBqFXS+5VGTdPfu
X-Developer-Key: i=markus.koeniger@liebherr.com; a=ed25519;
 pk=3fL7nhId6Sb17FYMBAevOva1I1fwHyykC4jdDKiRGpI=
X-Endpoint-Received: by B4 Relay for markus.koeniger@liebherr.com/20251222 with auth_id=583
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The sensors IIS328DQ and H3LIS331DL share one configuration but
H3LIS331DL has different gain parameters, configs therefore
need to be split up.
The gain parameters for the IIS328DQ are 0.98, 1.95 and 3.91,
depending on the selected measurement range.

See sensor manuals, chapter 2.1 "mechanical characteristics",
parameter "Sensitivity":
IIS328DQ https://www.st.com/resource/en/datasheet/iis328dq.pdf
H3LIS331DL https://www.st.com/resource/en/datasheet/h3lis331dl.pdf

Fixes: 46e33707fe95 ("iio: accel: add support for IIS328DQ variant")
Reviewed-by: Dimitri Fedrau <dimitri.fedrau@liebherr.com>
Signed-off-by: Markus Koeniger <markus.koeniger@liebherr.com>
---
Fix gain value of IIS328DQ accelerometer. The typical gain parameters for 
the IIS328DQ are 0.98, 1.95 and 3.91, depending on the selected 
measurement range. The configuration for IIS328DQ and H3LIS331DL needs 
to be split up as H3LIS331DL has different gains of 49, 98 and 195. 
---
 drivers/iio/accel/st_accel_core.c | 72 ++++++++++++++++++++++++++++++++++++++-
 1 file changed, 71 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/accel/st_accel_core.c b/drivers/iio/accel/st_accel_core.c
index 99cb661fabb2..afd97216d8ae 100644
--- a/drivers/iio/accel/st_accel_core.c
+++ b/drivers/iio/accel/st_accel_core.c
@@ -517,7 +517,6 @@ static const struct st_sensor_settings st_accel_sensors_settings[] = {
 		.wai_addr = ST_SENSORS_DEFAULT_WAI_ADDRESS,
 		.sensors_supported = {
 			[0] = H3LIS331DL_ACCEL_DEV_NAME,
-			[1] = IIS328DQ_ACCEL_DEV_NAME,
 		},
 		.ch = (struct iio_chan_spec *)st_accel_12bit_channels,
 		.odr = {
@@ -584,6 +583,77 @@ static const struct st_sensor_settings st_accel_sensors_settings[] = {
 		.multi_read_bit = true,
 		.bootime = 2,
 	},
+	{
+		.wai = 0x32,
+		.wai_addr = ST_SENSORS_DEFAULT_WAI_ADDRESS,
+		.sensors_supported = {
+			[0] = IIS328DQ_ACCEL_DEV_NAME,
+		},
+		.ch = (struct iio_chan_spec *)st_accel_12bit_channels,
+		.odr = {
+			.addr = 0x20,
+			.mask = 0x18,
+			.odr_avl = {
+				{ .hz = 50, .value = 0x00, },
+				{ .hz = 100, .value = 0x01, },
+				{ .hz = 400, .value = 0x02, },
+				{ .hz = 1000, .value = 0x03, },
+			},
+		},
+		.pw = {
+			.addr = 0x20,
+			.mask = 0x20,
+			.value_on = ST_SENSORS_DEFAULT_POWER_ON_VALUE,
+			.value_off = ST_SENSORS_DEFAULT_POWER_OFF_VALUE,
+		},
+		.enable_axis = {
+			.addr = ST_SENSORS_DEFAULT_AXIS_ADDR,
+			.mask = ST_SENSORS_DEFAULT_AXIS_MASK,
+		},
+		.fs = {
+			.addr = 0x23,
+			.mask = 0x30,
+			.fs_avl = {
+				[0] = {
+					.num = ST_ACCEL_FS_AVL_100G,
+					.value = 0x00,
+					.gain = IIO_G_TO_M_S_2(980),
+				},
+				[1] = {
+					.num = ST_ACCEL_FS_AVL_200G,
+					.value = 0x01,
+					.gain = IIO_G_TO_M_S_2(1950),
+				},
+				[2] = {
+					.num = ST_ACCEL_FS_AVL_400G,
+					.value = 0x03,
+					.gain = IIO_G_TO_M_S_2(3910),
+				},
+			},
+		},
+		.bdu = {
+			.addr = 0x23,
+			.mask = 0x80,
+		},
+		.drdy_irq = {
+			.int1 = {
+				.addr = 0x22,
+				.mask = 0x02,
+			},
+			.int2 = {
+				.addr = 0x22,
+				.mask = 0x10,
+			},
+			.addr_ihl = 0x22,
+			.mask_ihl = 0x80,
+		},
+		.sim = {
+			.addr = 0x23,
+			.value = BIT(0),
+		},
+		.multi_read_bit = true,
+		.bootime = 2,
+	},
 	{
 		/* No WAI register present */
 		.sensors_supported = {

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20251222-iio-accel-iis328dq-fix-gains-c281f9961b22

Best regards,
-- 
Markus Koeniger <markus.koeniger@liebherr.com>

