From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Fri, 08 Aug 2025 09:40:10 +0200
Subject: [PATCH] iio: imu: inv_icm42600: change invalid data error to EBUSY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250808-inv-icm42600-change-temperature-error-code-v1-1-986fbf63b77d@tdk.com>
X-B4-Tracking: v=1; b=H4sIANmplWgC/y2NwQqDMBAFf0X23IUkaGr7K6WHkLy2ezCRjUpB/
 HdD6XFgmNmpQgWV7t1Oik2qlNzAXjqKn5DfYEmNyRk3mNFcWfLGEqfeeWP4ryyYZmhYVgVDtSj
 HksB+SNaH2xg9LLXgrHjJ9zd7PI/jBD+8oqZ8AAAA
X-Change-ID: 20250807-inv-icm42600-change-temperature-error-code-65d16a98c6e1
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 Jonathan Cameron <Jonathan.Cameron@huawei.com>, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754638810; l=1568;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=NpeRL441DPZ1rC1rEkgDPmcWmaZUMbzkqnfYNLrMji8=;
 b=EPMyM5pzy8BkOiqIAuGm4MBI6sE8S7x+CcXBqShuVr25CsSsqrrzPnoiR5Nq0tEH5xd4Ivn8B
 M1Bjef2/BL/C2SkgfYqYreeV0aECEBlblVdSc4X409EmjW8Sx3FSa/g
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Temperature sensor returns the temperature of the mechanical parts
of the chip. If both accel and gyro are off, temperature sensor is
also automatically turned off and return invalid data.

In this case, returning EBUSY error code is better then EINVAL and
indicates userspace that it needs to retry reading temperature in
another context.

Fixes: bc3eb0207fb5 ("iio: imu: inv_icm42600: add temperature sensor support")
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Cc: stable@vger.kernel.org
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
index 8b15afca498cb5dfa7e056a60d3c78e419f11b29..1756f3d07049a26038776a35d9242f3dd1320354 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_temp.c
@@ -32,8 +32,12 @@ static int inv_icm42600_temp_read(struct inv_icm42600_state *st, s16 *temp)
 		goto exit;
 
 	*temp = (s16)be16_to_cpup(raw);
+	/*
+	 * Temperature data is invalid if both accel and gyro are off.
+	 * Return EBUSY in this case.
+	 */
 	if (*temp == INV_ICM42600_DATA_INVALID)
-		ret = -EINVAL;
+		ret = -EBUSY;
 
 exit:
 	mutex_unlock(&st->lock);

---
base-commit: 6408dba154079656d069a6a25fb3a8954959474c
change-id: 20250807-inv-icm42600-change-temperature-error-code-65d16a98c6e1

Best regards,
-- 
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

