From: Joshua Crofts <joshua.crofts1@gmail.com>
Date: Tue, 12 May 2026 12:57:25 +0200
Subject: [PATCH v2 05/10] iio: light: opt3001: ensure correct parenthesis
 alignment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260512-opt3001-cleanup-v2-5-8018cf3a8a0a@gmail.com>
References: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
In-Reply-To: <20260512-opt3001-cleanup-v2-0-8018cf3a8a0a@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Alexander Koch <mail@alexanderkoch.net>, 
 Michael Hornung <mhornung.linux@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joshua Crofts <joshua.crofts1@gmail.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778583471; l=6434;
 i=joshua.crofts1@gmail.com; s=20260422; h=from:subject:message-id;
 bh=Ud0bg+skwhtsrM6KPCOfS93zapO4Sp0BOPy7CuSdYis=;
 b=VzTjL4E2DxFkJX+n9TBTieNCXNHRLW8Y8cplgDSkYUIv3qbVrQsC1imNoi/TOo/JbuTEavNSi
 9cM2B0SZBFMDuIHyVmBb728320uMHNE0Qe4YqKj+FmRuxG1h6FLd5bw
X-Developer-Key: i=joshua.crofts1@gmail.com; a=ed25519;
 pk=Xd+UVoRPiiI0K3LHQ2XIcXmO0jvVuFTv9eTx3lgBphI=
X-Endpoint-Received: by B4 Relay for joshua.crofts1@gmail.com/20260422 with auth_id=746
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ensure correct parenthesis alignment per checkpatch.pl report.

No functional change.

Suggested-by: Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Signed-off-by: Joshua Crofts <joshua.crofts1@gmail.com>
---
 drivers/iio/light/opt3001.c | 73 +++++++++++++++++++++++++--------------------
 1 file changed, 41 insertions(+), 32 deletions(-)

diff --git a/drivers/iio/light/opt3001.c b/drivers/iio/light/opt3001.c
index 0de8ef4f3e68e6380b47d27e35882c604563377c..ad729152bb9266a35919e3abe576e792dbc08730 100644
--- a/drivers/iio/light/opt3001.c
+++ b/drivers/iio/light/opt3001.c
@@ -224,8 +224,8 @@ static const struct opt3001_scale opt3002_scales[] = {
 	},
 };
 
-static int opt3001_find_scale(const struct opt3001 *opt, int val,
-		int val2, u8 *exponent)
+static int opt3001_find_scale(const struct opt3001 *opt, int val, int val2,
+			      u8 *exponent)
 {
 	int i;
 	for (i = 0; i < ARRAY_SIZE(*opt->chip_info->scales); i++) {
@@ -243,8 +243,8 @@ static int opt3001_find_scale(const struct opt3001 *opt, int val,
 	return -EINVAL;
 }
 
-static void opt3001_to_iio_ret(struct opt3001 *opt, u8 exponent,
-		u16 mantissa, int *val, int *val2)
+static void opt3001_to_iio_ret(struct opt3001 *opt, u8 exponent, u16 mantissa,
+			       int *val, int *val2)
 {
 	int ret;
 	int whole = opt->chip_info->factor_whole;
@@ -365,8 +365,8 @@ static int opt3001_get_processed(struct opt3001 *opt, int *val, int *val2)
 	if (opt->use_irq) {
 		/* Wait for the IRQ to indicate the conversion is complete */
 		ret = wait_event_timeout(opt->result_ready_queue,
-				opt->result_ready,
-				msecs_to_jiffies(OPT3001_RESULT_READY_LONG));
+					 opt->result_ready,
+					 msecs_to_jiffies(OPT3001_RESULT_READY_LONG));
 		if (ret == 0)
 			return -ETIMEDOUT;
 	} else {
@@ -475,8 +475,8 @@ static int opt3001_set_int_time(struct opt3001 *opt, int time)
 }
 
 static int opt3001_read_raw(struct iio_dev *iio,
-		struct iio_chan_spec const *chan, int *val, int *val2,
-		long mask)
+			    struct iio_chan_spec const *chan,
+			    int *val, int *val2, long mask)
 {
 	struct opt3001 *opt = iio_priv(iio);
 	int ret;
@@ -507,8 +507,8 @@ static int opt3001_read_raw(struct iio_dev *iio,
 }
 
 static int opt3001_write_raw(struct iio_dev *iio,
-		struct iio_chan_spec const *chan, int val, int val2,
-		long mask)
+			     struct iio_chan_spec const *chan,
+			     int val, int val2, long mask)
 {
 	struct opt3001 *opt = iio_priv(iio);
 	int ret;
@@ -533,9 +533,11 @@ static int opt3001_write_raw(struct iio_dev *iio,
 }
 
 static int opt3001_read_event_value(struct iio_dev *iio,
-		const struct iio_chan_spec *chan, enum iio_event_type type,
-		enum iio_event_direction dir, enum iio_event_info info,
-		int *val, int *val2)
+				    const struct iio_chan_spec *chan,
+				    enum iio_event_type type,
+				    enum iio_event_direction dir,
+				    enum iio_event_info info,
+				    int *val, int *val2)
 {
 	struct opt3001 *opt = iio_priv(iio);
 	int ret = IIO_VAL_INT_PLUS_MICRO;
@@ -545,11 +547,13 @@ static int opt3001_read_event_value(struct iio_dev *iio,
 	switch (dir) {
 	case IIO_EV_DIR_RISING:
 		opt3001_to_iio_ret(opt, opt->high_thresh_exp,
-				opt->high_thresh_mantissa, val, val2);
+				   opt->high_thresh_mantissa,
+				   val, val2);
 		break;
 	case IIO_EV_DIR_FALLING:
 		opt3001_to_iio_ret(opt, opt->low_thresh_exp,
-				opt->low_thresh_mantissa, val, val2);
+				   opt->low_thresh_mantissa,
+				   val, val2);
 		break;
 	default:
 		ret = -EINVAL;
@@ -561,9 +565,11 @@ static int opt3001_read_event_value(struct iio_dev *iio,
 }
 
 static int opt3001_write_event_value(struct iio_dev *iio,
-		const struct iio_chan_spec *chan, enum iio_event_type type,
-		enum iio_event_direction dir, enum iio_event_info info,
-		int val, int val2)
+				     const struct iio_chan_spec *chan,
+				     enum iio_event_type type,
+				     enum iio_event_direction dir,
+				     enum iio_event_info info,
+				     int val, int val2)
 {
 	struct opt3001 *opt = iio_priv(iio);
 	struct i2c_client *client = opt->client;
@@ -627,8 +633,9 @@ static int opt3001_write_event_value(struct iio_dev *iio,
 }
 
 static int opt3001_read_event_config(struct iio_dev *iio,
-		const struct iio_chan_spec *chan, enum iio_event_type type,
-		enum iio_event_direction dir)
+				     const struct iio_chan_spec *chan,
+				     enum iio_event_type type,
+				     enum iio_event_direction dir)
 {
 	struct opt3001 *opt = iio_priv(iio);
 
@@ -636,8 +643,10 @@ static int opt3001_read_event_config(struct iio_dev *iio,
 }
 
 static int opt3001_write_event_config(struct iio_dev *iio,
-		const struct iio_chan_spec *chan, enum iio_event_type type,
-		enum iio_event_direction dir, bool state)
+				      const struct iio_chan_spec *chan,
+				      enum iio_event_type type,
+				      enum iio_event_direction dir,
+				      bool state)
 {
 	struct opt3001 *opt = iio_priv(iio);
 	struct i2c_client *client = opt->client;
@@ -813,16 +822,16 @@ static irqreturn_t opt3001_irq(int irq, void *_iio)
 			OPT3001_CONFIGURATION_M_CONTINUOUS) {
 		if (ret & OPT3001_CONFIGURATION_FH)
 			iio_push_event(iio,
-					IIO_UNMOD_EVENT_CODE(chan_type, 0,
-							IIO_EV_TYPE_THRESH,
-							IIO_EV_DIR_RISING),
-					iio_get_time_ns(iio));
+				       IIO_UNMOD_EVENT_CODE(chan_type, 0,
+							    IIO_EV_TYPE_THRESH,
+							    IIO_EV_DIR_RISING),
+				       iio_get_time_ns(iio));
 		if (ret & OPT3001_CONFIGURATION_FL)
 			iio_push_event(iio,
-					IIO_UNMOD_EVENT_CODE(chan_type, 0,
-							IIO_EV_TYPE_THRESH,
-							IIO_EV_DIR_FALLING),
-					iio_get_time_ns(iio));
+				       IIO_UNMOD_EVENT_CODE(chan_type, 0,
+							    IIO_EV_TYPE_THRESH,
+							    IIO_EV_DIR_FALLING),
+				       iio_get_time_ns(iio));
 	} else if (ret & OPT3001_CONFIGURATION_CRF) {
 		ret = i2c_smbus_read_word_swapped(client, OPT3001_RESULT);
 		if (ret < 0) {
@@ -886,8 +895,8 @@ static int opt3001_probe(struct i2c_client *client)
 	/* Make use of INT pin only if valid IRQ no. is given */
 	if (irq > 0) {
 		ret = request_threaded_irq(irq, NULL, opt3001_irq,
-				IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
-				"opt3001", iio);
+					   IRQF_TRIGGER_FALLING | IRQF_ONESHOT,
+					   "opt3001", iio);
 		if (ret) {
 			dev_err(dev, "failed to request IRQ #%d\n", irq);
 			return ret;

-- 
2.47.3

