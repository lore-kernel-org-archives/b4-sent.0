From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Tue, 20 Oct 2026 18:28:47 +0200
Subject: [PATCH] iio: inv_sensors: do not compute period estimation when
 updating odr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-iio-common-inv-sensors-do-not-compute-period-when-updating-odr-v1-1-8fedaea8116d@tdk.com>
X-B4-Tracking: v=1; b=H4sIAL6W12oC/yWO0QqDMAxFf0XyvICWzeF+ZezBtZlmYFKaqgPx3
 1e3x8OBe+4GRonJ4FZtkGhhY5UCzakCP/YyEHIoDK52bVO7GpkVvU6TCrIsaCSmyTAoiubDxDk
 TxrKqAdeRBOcY+swyoIaE3cV319a75tz1UCIx0Ys/vwP3x59tfr7J56MK+/4FUaV3TaIAAAA=
X-Change-ID: 20261020-iio-common-inv-sensors-do-not-compute-period-when-updating-odr-95c976c2149a
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <jonathan.cameron@oss.qualcomm.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792513728; l=1865;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=8Snz6Ctm/7LdgRA5eD0zB/7H++w98rHrAjXN1xYIlKU=;
 b=Le61TwPfhQPBKNrGmU3ULSPxaz0wNdQNY5G29RbKIMIZxkZHOnyTIK7G9gK4WwaXSrorPHazY
 ny5OuEEJiEsAPBIK8eOkMvTG5k5o8SQzFX4KWVDgSxznQ4oMpyGLItv
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When odr is updated, the delta between the interrupts will change and it
will lead to a bad period estimation.

Avoid this by preventing the period estimation in this case.

Fixes: 82bd09ce4fd3 ("iio: inv_sensors: improve period measurement by using a longer delay")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/common/inv_sensors/inv_sensors_timestamp.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
index 8c9e81a77e68..7ccd5d5a6986 100644
--- a/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
+++ b/drivers/iio/common/inv_sensors/inv_sensors_timestamp.c
@@ -142,6 +142,12 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 	/* update delta timestamps and estimated period */
 	it = &ts->delta;
 	ts->delta_counter += sample_nb;
+	/* reset in case of odr change */
+	if (ts->new_mult) {
+		it->lo = 0;
+		it->up = 0;
+		ts->delta_counter = 0;
+	}
 	delta = timestamp - it->up;
 	delta_threshold = INV_SENSORS_TIMESTAMP_MIN(INV_SENSORS_MIN_IT_DELTA, ts->chip.jitter);
 	if (delta >= delta_threshold) {
@@ -161,7 +167,7 @@ void inv_sensors_timestamp_interrupt(struct inv_sensors_timestamp *ts,
 	it->lo = it->up;
 	it->up = timestamp;
 	delta = it->up - it->lo;
-	if (it->lo != 0) {
+	if (it->lo != 0 && !ts->new_mult) {
 		/* compute period and check validity */
 		period = div_s64(delta, sample_nb);
 		valid = inv_validate_period(ts, period);

---
base-commit: 43ffda3c7f8456bbe641ae8249a077a361b97880
change-id: 20261020-iio-common-inv-sensors-do-not-compute-period-when-updating-odr-95c976c2149a

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

