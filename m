From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 09 Aug 2024 11:17:08 +0200
Subject: [PATCH 3/4] iio: imu: adis16400: drop ifdef around CONFIG_DEBUG_FS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-dev-adis-debugfs-improv-v1-3-d3adb6996518@analog.com>
References: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
In-Reply-To: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723195072; l=1916;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6Q00KFDp8vSfMOy9SOdSB2hurveB/47INrxlbxbqT6k=;
 b=MOe2m3mRxxYVT4dKXrTL7w9TeT5oxgHTj8VgX43Gt9YlBbwhopa21a5uQF45NtrIp2p6KBmTo
 xIZDDiTEo38CYmW1+rCWg6QmF2GTb/WqFoYp+BfYarWftjWPX1Z5PdA
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IS_ENABLED(CONFIG_DEBUG_FS) to return in case debugfs is not present.
Since this is known at compile time, it allows the compiler to drop any
unused code. Therefore no need to wrap the code with #ifdef.

While at it make adis16400_debugfs_init() void as the return code is
ignored.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16400.c | 18 ++++--------------
 1 file changed, 4 insertions(+), 14 deletions(-)

diff --git a/drivers/iio/imu/adis16400.c b/drivers/iio/imu/adis16400.c
index 0bfd6205f5f6..6484ab8aff55 100644
--- a/drivers/iio/imu/adis16400.c
+++ b/drivers/iio/imu/adis16400.c
@@ -202,8 +202,6 @@ enum {
 	ADIS16400_SCAN_TIMESTAMP,
 };
 
-#ifdef CONFIG_DEBUG_FS
-
 static ssize_t adis16400_show_serial_number(struct file *file,
 		char __user *userbuf, size_t count, loff_t *ppos)
 {
@@ -273,11 +271,14 @@ static int adis16400_show_flash_count(void *arg, u64 *val)
 DEFINE_DEBUGFS_ATTRIBUTE(adis16400_flash_count_fops,
 	adis16400_show_flash_count, NULL, "%lld\n");
 
-static int adis16400_debugfs_init(struct iio_dev *indio_dev)
+static void adis16400_debugfs_init(struct iio_dev *indio_dev)
 {
 	struct adis16400_state *st = iio_priv(indio_dev);
 	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
 
+	if (!IS_ENABLED(CONFIG_DEBUG_FS))
+		return;
+
 	if (st->variant->flags & ADIS16400_HAS_SERIAL_NUMBER)
 		debugfs_create_file_unsafe("serial_number", 0400,
 				d, st, &adis16400_serial_number_fops);
@@ -286,19 +287,8 @@ static int adis16400_debugfs_init(struct iio_dev *indio_dev)
 				d, st, &adis16400_product_id_fops);
 	debugfs_create_file_unsafe("flash_count", 0400,
 			d, st, &adis16400_flash_count_fops);
-
-	return 0;
 }
 
-#else
-
-static int adis16400_debugfs_init(struct iio_dev *indio_dev)
-{
-	return 0;
-}
-
-#endif
-
 enum adis16400_chip_variant {
 	ADIS16300,
 	ADIS16334,

-- 
2.45.2

