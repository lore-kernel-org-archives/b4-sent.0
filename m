From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 30 Jun 2025 21:47:29 +0200
Subject: [PATCH v6 1/3] iio: imu: inv_icm42600: reorganize DMA aligned
 buffers in structure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250630-losd-3-inv-icm42600-add-wom-support-v6-1-5bb0c84800d9@tdk.com>
References: <20250630-losd-3-inv-icm42600-add-wom-support-v6-0-5bb0c84800d9@tdk.com>
In-Reply-To: <20250630-losd-3-inv-icm42600-add-wom-support-v6-0-5bb0c84800d9@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751312852; l=1893;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=YQ1EdN6AgLVf9Q86CW1l/yLV7rzxsO/ydve8d4dakbQ=;
 b=56aCg+7+DMkAB3t6pw1xCUu+WtUK0aDWIDNsbbmmTy2OrQLK/PU54E4jnNtEz2v1CnMigTrR7
 fikFw1YiY8YAZrNj18CiL94fOGhqdCr1UqjOvxDtN4qOaPfMnQgGKvY
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move all DMA aligned buffers together at the end of the structure.

1. Timestamp anynomous structure is not used with DMA so it doesn't
belong after __aligned(IIO_DMA_MINALIGN).
2. struct inv_icm42600_fifo contains it's own __aligned(IIO_DMA_MINALIGN)
within it at the end so it should not be after __aligned(IIO_DMA_MINALIGN)
in the outer struct either.
3. Normally 1 would have been considered a bug, but because of the extra
alignment from 2, it actually was OK, but we shouldn't be relying on such
quirks.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
 drivers/iio/imu/inv_icm42600/inv_icm42600.h | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/iio/imu/inv_icm42600/inv_icm42600.h b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
index 55ed1ddaa8cb5dd410d17db3866fa0f22f18e9d2..9b2cce172670c5513f18d5979a5ff563e9af4cb3 100644
--- a/drivers/iio/imu/inv_icm42600/inv_icm42600.h
+++ b/drivers/iio/imu/inv_icm42600/inv_icm42600.h
@@ -148,9 +148,9 @@ struct inv_icm42600_suspended {
  *  @suspended:		suspended sensors configuration.
  *  @indio_gyro:	gyroscope IIO device.
  *  @indio_accel:	accelerometer IIO device.
- *  @buffer:		data transfer buffer aligned for DMA.
- *  @fifo:		FIFO management structure.
  *  @timestamp:		interrupt timestamps.
+ *  @fifo:		FIFO management structure.
+ *  @buffer:		data transfer buffer aligned for DMA.
  */
 struct inv_icm42600_state {
 	struct mutex lock;
@@ -164,12 +164,12 @@ struct inv_icm42600_state {
 	struct inv_icm42600_suspended suspended;
 	struct iio_dev *indio_gyro;
 	struct iio_dev *indio_accel;
-	u8 buffer[2] __aligned(IIO_DMA_MINALIGN);
-	struct inv_icm42600_fifo fifo;
 	struct {
 		s64 gyro;
 		s64 accel;
 	} timestamp;
+	struct inv_icm42600_fifo fifo;
+	u8 buffer[2] __aligned(IIO_DMA_MINALIGN);
 };
 
 

-- 
2.49.0

