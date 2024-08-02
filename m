From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 02 Aug 2024 16:27:05 +0200
Subject: [PATCH v2 7/8] iio: adc: ad9467: add backend test mode helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-7-4cb62852f0d0@analog.com>
References: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
In-Reply-To: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=3095;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=ORQVhXl18L7QpqOhlMxALCTW9W1adG0MCwa3NMU5bf8=;
 b=YbIh3Vv04Cv/TGptnpgRaT6I0SbpPmi8JNas51Sr2Ge2o56ND/+ux20I9lJ6+EgCYzA4u+f0u
 MAF7GhXrK3FA7gJG8aW2wMAeHDCy7k7+wgEUmKn3S6rEznZQmKFe+r5
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Group the backend configurations to be done in preparing and stopping
calibration in two new helpers analogous to ad9467_testmode_set(). This
is in preparation for adding support for debugFS test_mode where
we need similar configurations as in the calibration process.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 67 ++++++++++++++++++++++++++++++------------------
 1 file changed, 42 insertions(+), 25 deletions(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 557d98ca2f25..2f4bbbd5611c 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -494,11 +494,49 @@ static int ad9467_testmode_set(struct ad9467_state *st, unsigned int chan,
 				AN877_ADC_TRANSFER_SYNC);
 }
 
-static int ad9647_calibrate_prepare(struct ad9467_state *st)
+static int ad9467_backend_testmode_on(struct ad9467_state *st,
+				      unsigned int chan,
+				      enum iio_backend_test_pattern pattern)
 {
 	struct iio_backend_data_fmt data = {
 		.enable = false,
 	};
+	int ret;
+
+	ret = iio_backend_data_format_set(st->back, chan, &data);
+	if (ret)
+		return ret;
+
+	ret = iio_backend_test_pattern_set(st->back, chan, pattern);
+	if (ret)
+		return ret;
+
+	return iio_backend_chan_enable(st->back, chan);
+}
+
+static int ad9467_backend_testmode_off(struct ad9467_state *st,
+				       unsigned int chan)
+{
+	struct iio_backend_data_fmt data = {
+		.enable = true,
+		.sign_extend = true,
+	};
+	int ret;
+
+	ret = iio_backend_chan_disable(st->back, chan);
+	if (ret)
+		return ret;
+
+	ret = iio_backend_test_pattern_set(st->back, chan,
+					   IIO_BACKEND_NO_TEST_PATTERN);
+	if (ret)
+		return ret;
+
+	return iio_backend_data_format_set(st->back, chan, &data);
+}
+
+static int ad9647_calibrate_prepare(struct ad9467_state *st)
+{
 	unsigned int c;
 	int ret;
 
@@ -511,16 +549,8 @@ static int ad9647_calibrate_prepare(struct ad9467_state *st)
 		if (ret)
 			return ret;
 
-		ret = iio_backend_data_format_set(st->back, c, &data);
-		if (ret)
-			return ret;
-
-		ret = iio_backend_test_pattern_set(st->back, c,
-						   IIO_BACKEND_ADI_PRBS_9A);
-		if (ret)
-			return ret;
-
-		ret = iio_backend_chan_enable(st->back, c);
+		ret = ad9467_backend_testmode_on(st, c,
+						 IIO_BACKEND_ADI_PRBS_9A);
 		if (ret)
 			return ret;
 	}
@@ -601,24 +631,11 @@ static int ad9467_calibrate_apply(struct ad9467_state *st, unsigned int val)
 
 static int ad9647_calibrate_stop(struct ad9467_state *st)
 {
-	struct iio_backend_data_fmt data = {
-		.sign_extend = true,
-		.enable = true,
-	};
 	unsigned int c, mode;
 	int ret;
 
 	for (c = 0; c < st->info->num_channels; c++) {
-		ret = iio_backend_chan_disable(st->back, c);
-		if (ret)
-			return ret;
-
-		ret = iio_backend_test_pattern_set(st->back, c,
-						   IIO_BACKEND_NO_TEST_PATTERN);
-		if (ret)
-			return ret;
-
-		ret = iio_backend_data_format_set(st->back, c, &data);
+		ret = ad9467_backend_testmode_off(st, c);
 		if (ret)
 			return ret;
 

-- 
2.45.2

