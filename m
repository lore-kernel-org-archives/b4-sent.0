From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 20 Jul 2026 12:38:34 +0200
Subject: [PATCH v2 3/3] iio: inv_sensors: improve period measurement by
 using a longer delay
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-iio-common-inv-sensors-timestamp-rework-v2-3-aec31446809c@tdk.com>
References: <20260720-iio-common-inv-sensors-timestamp-rework-v2-0-aec31446809c@tdk.com>
In-Reply-To: <20260720-iio-common-inv-sensors-timestamp-rework-v2-0-aec31446809c@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784543936; l=4309;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=XgtZLh2KI5FSAM9NrJBryiRhF0RxEixZYqvMUesVYz4=;
 b=yqal+NPcGcWDQLPsp6oAzWkTPN6HOImaAvl+0jLlAWKsGG9+Vk4itLV34VeazKABngTi1znw3
 eBzbLcB94UiCK22mTb2pt1pac7S01QaI8gF+uG0h9mYGak2eEQETXr9
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
 .../iio/common/inv_sensors/inv_sensors_timestamp.c | 26 +++++++++++++++++++---
 include/linux/iio/common/inv_sensors_timestamp.h   |  6 +++++
 2 files changed, 29 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
index 2aaaa8df6d03..88a82d1370c5 100644
--- a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
+++ b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
@@ -16,6 +16,9 @@
 #define INV_SENSORS_TIMESTAMP_MAX(_val, _jitter)		\
 	(((_val) * (1000 + (_jitter))) / 1000)
 
+/* minimum timestamp delta between 2 interrupts for measuring period (20ms) */
+#define INV_SENSORS_MIN_IT_DELTA	(20 * NSEC_PER_MSEC)
+
 /* Add a new value inside an accumulator and update the estimate value */
 static void inv_update_acc(struct inv_sensors_timestamp_acc *acc, u32 val)
 {
@@ -122,7 +125,7 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 				     size_t sample_nb, s64 timestamp)
 {
 	struct inv_sensors_timestamp_interval *it;
-	s64 delta, interval;
+	s64 delta, delta_threshold, interval;
 	u32 period;
 	bool valid = false;
 
@@ -136,15 +139,32 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 		ts->timestamp = timestamp - interval;
 	}
 
+	/* update delta timestamps and estimated period */
+	it = &ts->delta;
+	ts->delta_counter += sample_nb;
+	delta = timestamp - it->up;
+	delta_threshold = INV_SENSORS_TIMESTAMP_MIN(INV_SENSORS_MIN_IT_DELTA, ts->chip.jitter);
+	if (delta >= delta_threshold) {
+		it->lo = it->up;
+		it->up = timestamp;
+		if (it->lo != 0) {
+			/* compute period: delta time divided by number of samples */
+			delta = it->up - it->lo;
+			period = div_s64(delta, ts->delta_counter);
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
 	if (it->lo != 0) {
-		/* compute period: delta time divided by number of samples */
+		/* compute period and check validity */
 		period = div_s64(delta, sample_nb);
-		valid = inv_update_chip_period(ts, period);
+		valid = inv_validate_period(ts, period);
 	}
 
 	/* if interrupt interval is valid, sync with interrupt timestamp */
diff --git a/include/linux/iio/common/inv_sensors_timestamp.h b/include/linux/iio/common/inv_sensors_timestamp.h
index e4e720e6f4b7..4f08204ede3b 100644
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
 	u32 min_period;
 	u32 max_period;
 	struct inv_sensors_timestamp_interval it;
+	struct inv_sensors_timestamp_interval delta;
+	u32 delta_counter;
 	s64 timestamp;
 	u32 mult;
 	u32 new_mult;
@@ -88,6 +92,8 @@ static inline void inv_sensors_timestamp_reset(struct inv_sensors_timestamp *ts)
 	const struct inv_sensors_timestamp_interval interval_init = {0LL, 0LL};
 
 	ts->it = interval_init;
+	ts->delta = interval_init;
+	ts->delta_counter = 0;
 	ts->timestamp = 0;
 }
 

-- 
2.54.0

