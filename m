From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:25 +0200
Subject: [PATCH 1/7] iio: imu: adis16475: Use the reset timeouts of the
 ADIS1657x
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-1-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=4005;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=ppM60eYFlYxENuKFnzc7MAMyPxIgDQNsNzoZAOE4acw=;
 b=QvlHsQgtTPrbaQx22b2H5WGaagKWp7yp1Z7ot1lF6yrYtI+kBe9oDVUtARcUp6CxccVkJ4rq6
 1piMeIaBIdEDHnxnFDt08VvhXnIikCf/AtJM6DMIOl31aEgb6/mdu7q
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADIS1657x variants share the timeouts of the ADIS1647x parts, which
wait 200 ms after a reset. The ADIS1657x datasheets give a longer
recovery: about 275 ms after a hardware reset, 241 ms after a software
reset and 282 ms from power on.

Reading the product ID right after the shorter wait returns 0 on an
ADIS16577-2, so the warning about a product ID mismatch is printed, and
the registers written while the part is still starting up are lost. This
includes the FIFO control bits written at probe (watermark pin polarity
and enable, and the overflow behaviour), so the watermark pin is never
driven and the FIFO does not behave as configured.

Give the ADIS1657x variants their own timeouts, a bit above the typical
values from the datasheet.

Fixes: f95920baa066 ("drivers: iio: imu: Add support for adis1657x family")
Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16475.c | 18 ++++++++++++------
 1 file changed, 12 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index 5f21dceda8f7..44520d9216a2 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -887,6 +887,12 @@ static const struct adis_timeout adis16475_timeouts = {
 	.self_test_ms = 20,
 };
 
+static const struct adis_timeout adis1657x_timeouts = {
+	.reset_ms = 300,
+	.sw_reset_ms = 260,
+	.self_test_ms = 20,
+};
+
 static const struct adis_timeout adis1650x_timeouts = {
 	.reset_ms = 260,
 	.sw_reset_ms = 260,
@@ -1331,7 +1337,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16575, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16575, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},
@@ -1354,7 +1360,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16575, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16575, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},
@@ -1377,7 +1383,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16576, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16576, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},
@@ -1400,7 +1406,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16576, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16576, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},
@@ -1423,7 +1429,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16577, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16577, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},
@@ -1446,7 +1452,7 @@ static const struct adis16475_chip_info adis16475_chip_info[] = {
 			 ADIS16475_HAS_BURST_DELTA_DATA |
 			 ADIS16475_NEEDS_BURST_REQUEST |
 			 ADIS16475_HAS_TIMESTAMP32,
-		.adis_data = ADIS16475_DATA(16577, &adis16475_timeouts,
+		.adis_data = ADIS16475_DATA(16577, &adis1657x_timeouts,
 					    ADIS16575_BURST32_DATA_TS32,
 					    ADIS16575_BURST_MAX_SPEED, true),
 	},

-- 
2.43.0

