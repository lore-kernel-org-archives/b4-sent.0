From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Fri, 31 Oct 2025 12:31:30 +0000
Subject: [PATCH v3 09/10] iio: dac: ad5446: Fix coding style issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-dev-add-ad5542-v3-9-d3541036c0e6@analog.com>
References: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
In-Reply-To: <20251031-dev-add-ad5542-v3-0-d3541036c0e6@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761913895; l=3170;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=7Bk6gr6kX1KvGZP2pdn9aUjTDyH/Zjv7dQ0xWxsPdY8=;
 b=Hl0igyCfRO6obXdMPlhEVaOhTNhnnrZgymWxfmYOWV9iIlqdxfLmnDptFxeepjwcuhN5Jmq4h
 Eh0XQSc6HWDBz0ZN5GXKG1ASF+QfdmsZubehGkZfCV/bzUGQz32h2Wz
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix style issues as reported by checkpatch. Additionally, make sure
include files are given in alphabetical order and that we include the
ones that were missing and remove the one we don't really use.

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5446.c | 41 ++++++++++++++++++-----------------------
 1 file changed, 18 insertions(+), 23 deletions(-)

diff --git a/drivers/iio/dac/ad5446.c b/drivers/iio/dac/ad5446.c
index d288fb56e324..bf9f7edb1a81 100644
--- a/drivers/iio/dac/ad5446.c
+++ b/drivers/iio/dac/ad5446.c
@@ -5,21 +5,17 @@
  * Copyright 2010 Analog Devices Inc.
  */
 
+#include <linux/array_size.h>
 #include <linux/cleanup.h>
-#include <linux/export.h>
-#include <linux/interrupt.h>
-#include <linux/workqueue.h>
 #include <linux/device.h>
-#include <linux/kernel.h>
-#include <linux/slab.h>
-#include <linux/sysfs.h>
-#include <linux/list.h>
-#include <linux/regulator/consumer.h>
 #include <linux/err.h>
-#include <linux/module.h>
-
+#include <linux/export.h>
 #include <linux/iio/iio.h>
-#include <linux/iio/sysfs.h>
+#include <linux/kstrtox.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/regulator/consumer.h>
+#include <linux/sysfs.h>
 
 #include "ad5446.h"
 
@@ -32,7 +28,8 @@ static const char * const ad5446_powerdown_modes[] = {
 };
 
 static int ad5446_set_powerdown_mode(struct iio_dev *indio_dev,
-	const struct iio_chan_spec *chan, unsigned int mode)
+				     const struct iio_chan_spec *chan,
+				     unsigned int mode)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -42,7 +39,7 @@ static int ad5446_set_powerdown_mode(struct iio_dev *indio_dev,
 }
 
 static int ad5446_get_powerdown_mode(struct iio_dev *indio_dev,
-	const struct iio_chan_spec *chan)
+				     const struct iio_chan_spec *chan)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -57,9 +54,9 @@ static const struct iio_enum ad5446_powerdown_mode_enum = {
 };
 
 static ssize_t ad5446_read_dac_powerdown(struct iio_dev *indio_dev,
-					   uintptr_t private,
-					   const struct iio_chan_spec *chan,
-					   char *buf)
+					 uintptr_t private,
+					 const struct iio_chan_spec *chan,
+					 char *buf)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 
@@ -67,9 +64,9 @@ static ssize_t ad5446_read_dac_powerdown(struct iio_dev *indio_dev,
 }
 
 static ssize_t ad5446_write_dac_powerdown(struct iio_dev *indio_dev,
-					    uintptr_t private,
-					    const struct iio_chan_spec *chan,
-					    const char *buf, size_t len)
+					  uintptr_t private,
+					  const struct iio_chan_spec *chan,
+					  const char *buf, size_t len)
 {
 	struct ad5446_state *st = iio_priv(indio_dev);
 	unsigned int shift;
@@ -151,10 +148,8 @@ static int ad5446_write_dac_raw(struct iio_dev *indio_dev,
 }
 
 static int ad5446_write_raw(struct iio_dev *indio_dev,
-			       struct iio_chan_spec const *chan,
-			       int val,
-			       int val2,
-			       long mask)
+			    struct iio_chan_spec const *chan, int val,
+			    int val2, long mask)
 {
 	switch (mask) {
 	case IIO_CHAN_INFO_RAW:

-- 
2.51.0

