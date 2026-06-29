From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 29 Jun 2026 21:51:55 +0200
Subject: [PATCH v2] iio: imu: inv_icm42600: fix timestamping by limiting
 FIFO reading
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260629-inv-icm42600-fix-watermark-fifo-reading-v2-1-967e375db7b3@tdk.com>
X-B4-Tracking: v=1; b=H4sIANrMQmoC/5WOQQ7CIBQFr9Kw9hugFKsr72G6QArt1xQMIGqa3
 l1aT+ByksmbN5NoAppITtVMgskY0bsCfFcRPSo3GMC+MOGUSyp5DegyoJ5EQQoW3/BSyYRJhXs
 h6yEY1aMbQHKhlaUtPTSClLVHMMXeSpfux/F5vRmd1vnVGDEmHz7blcxW7/9qZsDA1raRR6Fa1
 qpz6u977SfSLcvyBbqWBZHuAAAA
X-Change-ID: 20260623-inv-icm42600-fix-watermark-fifo-reading-624caf080754
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>, 
 linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, stable@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782762742; l=3459;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=nQhkZPtLs3PxMsL5AOyaO81u0Ro6Jo38fVYTn+BsJME=;
 b=yNVbPmWmarrbpNgNuwBQ178hkXzXHqoQp/X8hWQ65VmW5iY76m8EurFHMdJuhiYWYIGd3L5jT
 SWPomtYGum/BbS0QinLJhieEwMKSikWg4wbFY+i32wgeOde28Se91zn
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Timestamps are made by measuring the chip clock using the watermark
interrupts. If we read more than watermark samples as done today, we
are reducing the period between interrupts and distort the time
measurement. Fix that by reading only watermark samples in the
interrupt case.

Fixes: 7f85e42a6c54 ("iio: imu: inv_icm42600: add buffer support in iio devices")
Cc: stable@vger.kernel.org
Signed-off-by: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
---
Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v2:
- Delete watermark computation rework, keep only FIFO read fix.
- Link to v1: https://patch.msgid.link/20260623-inv-icm42600-fix-watermark-fifo-reading-v1-1-f3f5694a818a@tdk.com

To: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: Jonathan Cameron <Jonathan.Cameron@huawei.com>
Cc: Jean-Baptiste Maneyrol <jmaneyrol@invensense.com>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c | 9 +++++----
 drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h | 1 +
 2 files changed, 6 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
index 68a395758031..5c3840acf085 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.c
@@ -248,6 +248,7 @@ int inv_icm42600_buffer_update_watermark(struct inv_icm42600_state *st)
 
 	/* compute watermark value in bytes */
 	wm_size = watermark * packet_size;
+	st->fifo.watermark.value = watermark;
 
 	/* changing FIFO watermark requires to turn off watermark interrupt */
 	ret = regmap_update_bits_check(st->map, INV_ICM42600_REG_INT_SOURCE0,
@@ -454,11 +455,10 @@ int inv_icm42600_buffer_fifo_read(struct inv_icm42600_state *st,
 	st->fifo.nb.accel = 0;
 	st->fifo.nb.total = 0;
 
-	/* compute maximum FIFO read size */
+	/* compute maximum FIFO read size (watermark for max = 0 interrupt case) */
 	if (max == 0)
-		max_count = sizeof(st->fifo.data);
-	else
-		max_count = max * inv_icm42600_get_packet_size(st->fifo.en);
+		max = st->fifo.watermark.value;
+	max_count = max * inv_icm42600_get_packet_size(st->fifo.en);
 
 	/* read FIFO count value */
 	raw_fifo_count = (__be16 *)st->buffer;
@@ -574,6 +574,7 @@ int inv_icm42600_buffer_init(struct inv_icm42600_state *st)
 
 	st->fifo.watermark.eff_gyro = 1;
 	st->fifo.watermark.eff_accel = 1;
+	st->fifo.watermark.value = 1;
 
 	/*
 	 * Default FIFO configuration (bits 7 to 5)
diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
index ffca4da1e249..88b8b9f780af 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600_buffer.h
@@ -34,6 +34,7 @@ struct inv_icm42600_fifo {
 		unsigned int accel;
 		unsigned int eff_gyro;
 		unsigned int eff_accel;
+		unsigned int value;
 	} watermark;
 	size_t count;
 	struct {

---
base-commit: cc746297b23e89bd5df9f91f3a0ca209e8991763
change-id: 20260623-inv-icm42600-fix-watermark-fifo-reading-624caf080754

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

