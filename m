From: Phil Williams <phil.williams@advisoft.co.nz>
Date: Mon, 16 Nov 2026 10:40:01 +1300
Subject: [PATCH] iio: imu: st_lsm6dsx: fall back to 25 us/tick without a
 trim
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-st-lsm6dsx-ts-fallback-v1-1-8ace30afbfb5@advisoft.co.nz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz1jCQcrQq6AOIXFaQ6BVnFZIi
 LuTlvEN/++gnIUVbs0Omb+i8lorqG3AP936YJRQDaYzlogsasGkiw26YVGMLqXR+Rl9MBQpEPc
 dQ43fmaNs//Fwv6yfcWJffjc4jhNT60DqegAAAA==
X-Change-ID: 20261116-st-lsm6dsx-ts-fallback-cd21f1d1e30e
To: Lorenzo Bianconi <lorenzo@kernel.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Mario Tesi <martepisa@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, stable@vger.kernel.org, 
 Phil Williams <phil.williams@advisoft.co.nz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794778800; l=2231;
 i=phil.williams@advisoft.co.nz; s=kernel; h=from:subject:message-id;
 bh=uHlYPZd4leaL6BZM5UhiWipgD8U4U669fNKN8B6lxPA=;
 b=swvwjnWL3dHnjOwF5N49mxp+jQkSzO5f8iKsDykvNkJoG9nL5N9gOV1dfEDQAgYLgtVenSNDn
 mmz43EWAIvwD7R8bnl+BqLxRMaYraCgYT3m1eKkeiSTLJO89BB/7Zg6
X-Developer-Key: i=phil.williams@advisoft.co.nz; a=ed25519;
 pk=t0M8TApJRlA/rHh3lIu1XTiWO2+evmU8VnO43/qqLPk=
X-Endpoint-Received: by B4 Relay for phil.williams@advisoft.co.nz/kernel with auth_id=1538
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 8abbf45fcda0 ("iio: st_lsm6dsx: Fixed calibrated timestamp
calculation") takes the FIFO timestamp scale from ts_sensitivity.
That field is only filled in for parts that have freq_fine. The
untagged-FIFO parts are left at zero:

  LSM6DS3
  LSM6DS3H
  LSM6DSL, LSM6DSM, ISM330DLC and LSM6DS3TR-C

st_lsm6dsx_read_fifo() multiplies the raw counter by hw->ts_gain, so
every sample is published with the timestamp taken when the buffer
was enabled. The accelerometer and gyroscope values still update.
Userspace that integrates attitude from the timestamp delta treats a
stuck timestamp as dt = 0.

These parts have no freq_fine register, so there is no trim to apply.
Use the previous fixed scale of 25000 ns/tick when ts_sensitivity is
unset. Entries that already set it are left alone.

Fixes: 8abbf45fcda0 ("iio: st_lsm6dsx: Fixed calibrated timestamp calculation")
Cc: stable@vger.kernel.org
Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Phil Williams <phil.williams@advisoft.co.nz>
---
Resending inline. The first copy went out as an attachment.
No code changes.
---
 drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c b/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
index 823f8ac66..98db90a30 100644
--- a/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
+++ b/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
@@ -2525,8 +2525,14 @@ static int st_lsm6dsx_init_hw_timer(struct st_lsm6dsx_hw *hw)
 			return err;
 	}
 
-	/* calibrate timestamp sensitivity */
+	/*
+	 * Parts with no freq_fine register have no trim and leave
+	 * ts_sensitivity unset. Those parts used a fixed 25 us/tick.
+	 * A zero gain publishes every FIFO sample with one timestamp.
+	 */
 	hw->ts_gain = ts_settings->ts_sensitivity;
+	if (!hw->ts_gain)
+		hw->ts_gain = 25000;
 	if (ts_settings->freq_fine) {
 		err = regmap_read(hw->regmap, ts_settings->freq_fine, &val);
 		if (err < 0)

---
base-commit: fa2933aac170dd19c6a7f0d7b81a8f537e40915c
change-id: 20261116-st-lsm6dsx-ts-fallback-cd21f1d1e30e

Best regards,
--  
Phil Williams <phil.williams@advisoft.co.nz>

