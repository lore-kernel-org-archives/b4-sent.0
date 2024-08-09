From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 09 Aug 2024 11:17:06 +0200
Subject: [PATCH 1/4] iio: imu: adis16475: drop ifdef around CONFIG_DEBUG_FS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-dev-adis-debugfs-improv-v1-1-d3adb6996518@analog.com>
References: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
In-Reply-To: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723195072; l=1666;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=a5jhUJNFvPeDN03HbwrRCzHfwF3/Z8tIkW6EAXbSqz8=;
 b=Xf2EZl8ZhihDhXkPLoO9pg0SjU/BW6E5MMPYQqoMU4FMYH4udPeTVUwKPv49DtCjA7308aac2
 othDecAsrIqCBPPhcPVH9yEEjBUNfzM/9PyruT06sELDL1zpXwDzT0e
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IS_ENABLED(CONFIG_DEBUG_FS) to return early in case debugfs is not
present. Since this is known at compile time, it allows the compiler to
drop any unused code. Therefore no need to wrap the code with #ifdef.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16475.c | 9 +++------
 1 file changed, 3 insertions(+), 6 deletions(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index c094ae4ffcb2..88efe728b61b 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -164,7 +164,6 @@ module_param(low_rate_allow, bool, 0444);
 MODULE_PARM_DESC(low_rate_allow,
 		 "Allow IMU rates below the minimum advisable when external clk is used in SCALED mode (default: N)");
 
-#ifdef CONFIG_DEBUG_FS
 static ssize_t adis16475_show_firmware_revision(struct file *file,
 						char __user *userbuf,
 						size_t count, loff_t *ppos)
@@ -279,6 +278,9 @@ static void adis16475_debugfs_init(struct iio_dev *indio_dev)
 	struct adis16475 *st = iio_priv(indio_dev);
 	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
 
+	if (!IS_ENABLED(CONFIG_DEBUG_FS))
+		return;
+
 	debugfs_create_file_unsafe("serial_number", 0400,
 				   d, st, &adis16475_serial_number_fops);
 	debugfs_create_file_unsafe("product_id", 0400,
@@ -290,11 +292,6 @@ static void adis16475_debugfs_init(struct iio_dev *indio_dev)
 	debugfs_create_file("firmware_date", 0400, d,
 			    st, &adis16475_firmware_date_fops);
 }
-#else
-static void adis16475_debugfs_init(struct iio_dev *indio_dev)
-{
-}
-#endif
 
 static int adis16475_get_freq(struct adis16475 *st, u32 *freq)
 {

-- 
2.45.2

