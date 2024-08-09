From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 09 Aug 2024 11:17:07 +0200
Subject: [PATCH 2/4] iio: imu: adis16480: drop ifdef around CONFIG_DEBUG_FS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-dev-adis-debugfs-improv-v1-2-d3adb6996518@analog.com>
References: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
In-Reply-To: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723195072; l=2149;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=INFkT1lRAs5IyvgBIQdTgiDQKkEI3o5fQR1S25bTHBw=;
 b=6828GMXZGnzXAeFZtJBinSMrhhGokbIYSPO3VCzNOvrTsjgZWX/o1N3YM4xhXNtryjdeBSeYM
 nN/j0EloDTlAy718KiYB4IyUjuC1t1SdXHE9AwMK7g6RxOEvZGIHVpV
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IS_ENABLED(CONFIG_DEBUG_FS) to return in case debugfs is not present.
Since this is known at compile time, it allows the compiler to drop any
unused code. Therefore no need to wrap the code with #ifdef.

While at it make adis16480_debugfs_init() void as the return code is
ignored.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16480.c | 18 ++++--------------
 1 file changed, 4 insertions(+), 14 deletions(-)

diff --git a/drivers/iio/imu/adis16480.c b/drivers/iio/imu/adis16480.c
index 4e31503d512e..294181f2fcb3 100644
--- a/drivers/iio/imu/adis16480.c
+++ b/drivers/iio/imu/adis16480.c
@@ -193,8 +193,6 @@ module_param(low_rate_allow, bool, 0444);
 MODULE_PARM_DESC(low_rate_allow,
 		 "Allow IMU rates below the minimum advisable when external clk is used in PPS mode (default: N)");
 
-#ifdef CONFIG_DEBUG_FS
-
 static ssize_t adis16480_show_firmware_revision(struct file *file,
 		char __user *userbuf, size_t count, loff_t *ppos)
 {
@@ -304,11 +302,14 @@ static int adis16480_show_flash_count(void *arg, u64 *val)
 DEFINE_DEBUGFS_ATTRIBUTE(adis16480_flash_count_fops,
 	adis16480_show_flash_count, NULL, "%lld\n");
 
-static int adis16480_debugfs_init(struct iio_dev *indio_dev)
+static void adis16480_debugfs_init(struct iio_dev *indio_dev)
 {
 	struct adis16480 *adis16480 = iio_priv(indio_dev);
 	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
 
+	if (!IS_ENABLED(CONFIG_DEBUG_FS))
+		return;
+
 	debugfs_create_file_unsafe("firmware_revision", 0400,
 		d, adis16480, &adis16480_firmware_revision_fops);
 	debugfs_create_file_unsafe("firmware_date", 0400,
@@ -319,19 +320,8 @@ static int adis16480_debugfs_init(struct iio_dev *indio_dev)
 		d, adis16480, &adis16480_product_id_fops);
 	debugfs_create_file_unsafe("flash_count", 0400,
 		d, adis16480, &adis16480_flash_count_fops);
-
-	return 0;
 }
 
-#else
-
-static int adis16480_debugfs_init(struct iio_dev *indio_dev)
-{
-	return 0;
-}
-
-#endif
-
 static int adis16480_set_freq(struct iio_dev *indio_dev, int val, int val2)
 {
 	struct adis16480 *st = iio_priv(indio_dev);

-- 
2.45.2

