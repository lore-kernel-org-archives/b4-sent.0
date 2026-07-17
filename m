From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Fri, 17 Jul 2026 14:39:41 +0200
Subject: [PATCH 2/2] iio: invensense: improve period measurement by using a
 longer delay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-iio-common-inv-sensors-timestamp-rework-v1-2-d1afee2805cd@tdk.com>
References: <20260717-iio-common-inv-sensors-timestamp-rework-v1-0-d1afee2805cd@tdk.com>
In-Reply-To: <20260717-iio-common-inv-sensors-timestamp-rework-v1-0-d1afee2805cd@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784291993; l=4521;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=QaB1sqyTIlaV5WHBIAd4mGNxiNij+cw0Vv5qDbn6Sr4=;
 b=aiCdjaLn9gJqnWHa6UH0pXxfZt/qHxBg0e73Luv8nALJmZXVHxaZxUYOMVB9Jwj49buy98D9y
 IvO6fFf82+iAo4P5SpQXeLHspXm8Wpv0fPtHbFagN2uzhY3C6PP0mo+
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Period measurement can be difficult when using high sampling
frequency where the jitter criteria is hard to meet because of the
system jitter.

This new version is using the delta time between 2 distant interrupts
to measure an interval of at least 20ms. 20ms is a good compromise
between the mitigation of system jitter and the delay to update
period. This way we decorrelate the period measurement from the
interrupt timestamps syncing using only the 2 last interrupts.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 .../iio/common/inv_sensors/inv_sensors_timestamp.c | 31 +++++++++++++++++-----
 include/linux/iio/common/inv_sensors_timestamp.h   |  6 +++++
 2 files changed, 31 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
index 2c89e0edc87d..63c1d8a2e19a 100644
--- a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
+++ b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
@@ -16,6 +16,9 @@
 #define INV_SENSORS_TIMESTAMP_MAX(_val, _jitter)		\
 	(((_val) * (1000 + (_jitter))) / 1000)
 
+/* minimum timestamp delta between 2 interrupts for measuring period (20ms) */
+#define INV_SENSORS_MIN_IT_DELTA	(20 * NSEC_PER_MSEC)
+
 /* Add a new value inside an accumulator and update the estimate value */
 static void inv_update_acc(struct inv_sensors_timestamp_acc *acc, uint32_t val)
 {
@@ -121,10 +124,13 @@ static uint32_t inv_align_timestamp_it(struct inv_sensors_timestamp *ts,
 void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 				     size_t sample_nb, int64_t timestamp)
 {
+	const int64_t delta_threshold =
+			INV_SENSORS_TIMESTAMP_MIN(INV_SENSORS_MIN_IT_DELTA,
+						  ts->chip.jitter);
 	struct inv_sensors_timestamp_interval *it;
 	int64_t delta, interval;
 	uint32_t period;
-	bool valid = false;
+	bool valid;
 
 	if (sample_nb == 0)
 		return;
@@ -136,16 +142,29 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 		ts->timestamp = timestamp - interval;
 	}
 
+	/* update delta timestamps and estimated period */
+	it = &ts->delta;
+	ts->delta_counter += sample_nb;
+	delta = timestamp - it->up;
+	if (delta >= delta_threshold) {
+		it->lo = it->up;
+		it->up = timestamp;
+		if (it->lo != 0) {
+			/* compute period: delta time divided by number of samples */
+			delta = it->up - it->lo;
+			period = div_s64(delta, sample_nb);
+			inv_update_chip_period(ts, period);
+		}
+		ts->delta_counter = 0;
+	}
+
 	/* update interrupt timestamp and compute chip and sensor periods */
 	it = &ts->it;
 	it->lo = it->up;
 	it->up = timestamp;
 	delta = it->up - it->lo;
-	if (it->lo != 0) {
-		/* compute period: delta time divided by number of samples */
-		period = div_s64(delta, sample_nb);
-		valid = inv_update_chip_period(ts, period);
-	}
+	period = div_s64(delta, sample_nb);
+	valid = inv_validate_period(ts, period);
 
 	/* if interrupt interval is valid, sync with interrupt timestamp */
 	ts->period = valid ? inv_align_timestamp_it(ts, sample_nb) :
diff --git a/include/linux/iio/common/inv_sensors_timestamp.h b/include/linux/iio/common/inv_sensors_timestamp.h
index 8d506f1e9df2..bc04831f54c4 100644
--- a/include/linux/iio/common/inv_sensors_timestamp.h
+++ b/include/linux/iio/common/inv_sensors_timestamp.h
@@ -46,6 +46,8 @@ struct inv_sensors_timestamp_acc {
  * @min_period:		minimal acceptable clock period
  * @max_period:		maximal acceptable clock period
  * @it:			interrupts interval timestamps
+ * @delta:		interval timestamps between several interrupts
+ * @delta_counter:	number of data samples in the delta interval
  * @timestamp:		store last timestamp for computing next data timestamp
  * @mult:		current internal period multiplier
  * @new_mult:		new set internal period multiplier (not yet effective)
@@ -57,6 +59,8 @@ struct inv_sensors_timestamp {
 	uint32_t min_period;
 	uint32_t max_period;
 	struct inv_sensors_timestamp_interval it;
+	struct inv_sensors_timestamp_interval delta;
+	uint32_t delta_counter;
 	int64_t timestamp;
 	uint32_t mult;
 	uint32_t new_mult;
@@ -88,6 +92,8 @@ static inline void inv_sensors_timestamp_reset(struct inv_sensors_timestamp *ts)
 	const struct inv_sensors_timestamp_interval interval_init = {0LL, 0LL};
 
 	ts->it = interval_init;
+	ts->delta = interval_init;
+	ts->delta_counter = 0;
 	ts->timestamp = 0;
 }
 

-- 
2.54.0

