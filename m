From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 09 Aug 2024 11:17:09 +0200
Subject: [PATCH 4/4] iio: imu: adis16460: drop ifdef around CONFIG_DEBUG_FS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240809-dev-adis-debugfs-improv-v1-4-d3adb6996518@analog.com>
References: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
In-Reply-To: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723195072; l=1899;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=n1Jglfa5iy92BkrwrPeTAXoPaCMzOj6zVbu4oTIXimA=;
 b=YfrAyimaJSeHI23eRNfs1lZQ0nIiSOL9ap+I5hl9chdkqZ/VbhqCiSUyTIf/q+ZA1gNUvTKyK
 /NjwlK4wDF9DL3kuBfA3BzQrjMedsxEXNFhQXG0qzhn8CRRoP5ZMWLw
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use IS_ENABLED(CONFIG_DEBUG_FS) to return in case debugfs is not present.
Since this is known at compile time, it allows the compiler to drop any
unused code. Therefore no need to wrap the code with #ifdef.

While at it make adis16460_debugfs_init() void as the return code is
ignored.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/imu/adis16460.c | 18 ++++--------------
 1 file changed, 4 insertions(+), 14 deletions(-)

diff --git a/drivers/iio/imu/adis16460.c b/drivers/iio/imu/adis16460.c
index 69facd72bd7d..eaa38dd6201f 100644
--- a/drivers/iio/imu/adis16460.c
+++ b/drivers/iio/imu/adis16460.c
@@ -69,8 +69,6 @@ struct adis16460 {
 	struct adis adis;
 };
 
-#ifdef CONFIG_DEBUG_FS
-
 static int adis16460_show_serial_number(void *arg, u64 *val)
 {
 	struct adis16460 *adis16460 = arg;
@@ -125,30 +123,22 @@ static int adis16460_show_flash_count(void *arg, u64 *val)
 DEFINE_DEBUGFS_ATTRIBUTE(adis16460_flash_count_fops,
 		adis16460_show_flash_count, NULL, "%lld\n");
 
-static int adis16460_debugfs_init(struct iio_dev *indio_dev)
+static void adis16460_debugfs_init(struct iio_dev *indio_dev)
 {
 	struct adis16460 *adis16460 = iio_priv(indio_dev);
 	struct dentry *d = iio_get_debugfs_dentry(indio_dev);
 
+	if (!IS_ENABLED(CONFIG_DEBUG_FS))
+		return;
+
 	debugfs_create_file_unsafe("serial_number", 0400,
 			d, adis16460, &adis16460_serial_number_fops);
 	debugfs_create_file_unsafe("product_id", 0400,
 			d, adis16460, &adis16460_product_id_fops);
 	debugfs_create_file_unsafe("flash_count", 0400,
 			d, adis16460, &adis16460_flash_count_fops);
-
-	return 0;
 }
 
-#else
-
-static int adis16460_debugfs_init(struct iio_dev *indio_dev)
-{
-	return 0;
-}
-
-#endif
-
 static int adis16460_set_freq(struct iio_dev *indio_dev, int val, int val2)
 {
 	struct adis16460 *st = iio_priv(indio_dev);

-- 
2.45.2

