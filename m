From: Phil Williams <phil.williams@advisoft.co.nz>
Date: Wed, 25 Nov 2026 12:15:44 +1300
Subject: [PATCH v2] iio: imu: st_lsm6dsx: set ts_sensitivity on parts
 without freq_fine
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-st-lsm6dsx-ts-fallback-v2-1-ea0ea2512070@advisoft.co.nz>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WOTQ6CMBCFr0K6dghTIzGuvIdh0Z+pVJGaTm1Qw
 t0teACXX/Le+94smKInFqdqFpGyZx/GAnJXCdOr8UrgbWEhG9kiYgucYOBHa3mCxODUMGhl7mC
 sRIcWad+QKOVnJOenbfjS/Zhf+kYmrWtrovecQnxv5oxr7q8kIyAclSkS5bTTh7Oy5XJwqTahH
 j+iW5blC89ElLnTAAAA
X-Change-ID: 20261116-st-lsm6dsx-ts-fallback-cd21f1d1e30e
To: Lorenzo Bianconi <lorenzo@kernel.org>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Mario Tesi <martepisa@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, stable@vger.kernel.org, 
 Phil Williams <phil.williams@advisoft.co.nz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795562143; l=2777;
 i=phil.williams@advisoft.co.nz; s=kernel; h=from:subject:message-id;
 bh=fGzBxiYeqCVBJr9qUvLqytWRj2H3OFvl+kp4md9filo=;
 b=QpdXAjVXaPivFOUs6AdlJsF1sw2wxLPu6S1QzQ4gahR365MCZy6WI57iOzhxSM82kWsGkHoc8
 lQw4Ov9aivoAmSu6UnA89XcMVmwtTIXb5o7kagE2LCOa1H9boLk45UD
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

Set ts_sensitivity to the previous fixed scale of 25000 ns/tick on
those entries. They have no freq_fine register, so ts_trim_coeff is
left unset and no trim is applied.

Fixes: 8abbf45fcda0 ("iio: st_lsm6dsx: Fixed calibrated timestamp calculation")
Cc: stable@vger.kernel.org
Suggested-by: Lorenzo Bianconi <lorenzo@kernel.org>
Suggested-by: Jonathan Cameron <jic23@kernel.org>
Signed-off-by: Phil Williams <phil.williams@advisoft.co.nz>
---
Resending inline. The first copy went out as an attachment.
No code changes.
---
Changes in v2:
- Drop the ts_gain fallback in st_lsm6dsx_init_hw_timer() and set
  .ts_sensitivity = 25000 in the LSM6DS3, LSM6DS3H and LSM6DSL settings
  entries instead (Lorenzo, Jonathan).
- Leave .ts_trim_coeff unset on those entries since they have no
  freq_fine register (Francesco).
- Link to v1: https://lore.kernel.org/r/20261116-st-lsm6dsx-ts-fallback-v1-1-8ace30afbfb5@advisoft.co.nz
---
 drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c b/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
index 823f8ac66..dffaf76b5 100644
--- a/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
+++ b/drivers/iio/imu/st_lsm6dsx/st_lsm6dsx_core.c
@@ -434,6 +434,7 @@ static const struct st_lsm6dsx_settings st_lsm6dsx_sensor_settings[] = {
 				.addr = 0x09,
 				.mask = GENMASK(5, 3),
 			},
+			.ts_sensitivity = 25000,
 		},
 		.event_settings = {
 			.sources = {
@@ -601,6 +602,7 @@ static const struct st_lsm6dsx_settings st_lsm6dsx_sensor_settings[] = {
 				.addr = 0x09,
 				.mask = GENMASK(5, 3),
 			},
+			.ts_sensitivity = 25000,
 		},
 		.event_settings = {
 			.sources = {
@@ -802,6 +804,7 @@ static const struct st_lsm6dsx_settings st_lsm6dsx_sensor_settings[] = {
 				.addr = 0x09,
 				.mask = GENMASK(5, 3),
 			},
+			.ts_sensitivity = 25000,
 		},
 		.shub_settings = {
 			.page_mux = {

---
base-commit: fa2933aac170dd19c6a7f0d7b81a8f537e40915c
change-id: 20261116-st-lsm6dsx-ts-fallback-cd21f1d1e30e

Best regards,
--  
Phil Williams <phil.williams@advisoft.co.nz>

