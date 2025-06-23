From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Date: Mon, 23 Jun 2025 14:55:52 +0200
Subject: [PATCH v5 1/3] iio: imu: inv_icm42600: move structure DMA buffers
 at the end
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250623-losd-3-inv-icm42600-add-wom-support-v5-1-4b3b33e028fe@tdk.com>
References: <20250623-losd-3-inv-icm42600-add-wom-support-v5-0-4b3b33e028fe@tdk.com>
In-Reply-To: <20250623-losd-3-inv-icm42600-add-wom-support-v5-0-4b3b33e028fe@tdk.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750683359; l=1524;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=Sqk5EBW69Vb3qsTzZ8JKNX6MNPvlZeiK+pOwCYdRCz0=;
 b=yZ91Enn+j5euiJhL/kFfEZ/3Qeqk2J4+Olnz93SNdPg9C41wawcKrf802EsCcRbpCzlGeywD/
 2JNEJBVnaQbApO7CgYux8OdHV4MA7OM6sfUOYNITdEg1EUPujIfvaLq
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move DMA buffers at the end of the structure to avoid overflow
bugs with unexpected effect.

struct inv_icm42600_fifo has a DMA buffer at the end.

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

