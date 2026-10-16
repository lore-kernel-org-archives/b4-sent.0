From: Amir Atef <amiratefabdallah1122@gmail.com>
Subject: [PATCH v2] staging: iio: frequency: ad9834: use guard(mutex)
Date: Sat, 17 Oct 2026 02:45:52 +0300
Message-Id: <179219435216.322.13409717511306957730.20261017-ad9834-guard-mutex-v2@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 David Lechner <dlechner@baylibre.com>, Nuno Sa <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, linux-iio@vger.kernel.org, 
 linux-staging@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792194352; l=4410;
 i=amiratefabdallah1122@gmail.com; s=20261016; h=from:subject:message-id;
 bh=QC3WjUcRokALSjuAgdPJHx7Z+g92N3srbIAjHSHgWH0=;
 b=XqlHDjIA8XspS27KHuZUtY1Q9oxs7Yin5t4IjtP4AZgGZvqWRSEuhAIOQZebtLSetiYdydJ5z
 Bb6H5vmf0WyA2YwWr4yKFsbGkzOgT7Lrx/mkq6UAnVIfyVOpQqWpgmE
X-Developer-Key: i=amiratefabdallah1122@gmail.com; a=ed25519;
 pk=FRhtQptjt3GSkQBUg7qfVL8eusorsJqHzciu3+ss11o=
X-Endpoint-Received: by B4 Relay for amiratefabdallah1122@gmail.com/20261016 with auth_id=1209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use guard(mutex) to manage the state lock in ad9834_write() and
ad9834_store_wavetype(). This simplifies error handling by allowing
early returns instead of setting the return code and breaking out of the
switch statement to manually unlock the mutex.

Signed-off-by: Amir Atef <amiratefabdallah1122@gmail.com>
---
Changes in v2:
- Add blank line after guard(mutex) in ad9834_write().
- Move 'int ret;' to the end of the variable declaration block in
  ad9834_store_wavetype().
- Drop redundant 'else' in ad9834_store_wavetype() case 1 by inverting
  the condition (kept 'else' in ad9834_write() and case 0 where they are
  part of if-else-if-else chains).
- Replace ternary return with explicit 'if (ret) return ret;' in
  ad9834_store_wavetype().
- Link to v1: https://lore.kernel.org/r/179214943270.333.5921549521929682753.20261016-ad9834-guard-mutex@gmail.com

 drivers/staging/iio/frequency/ad9834.c | 50 ++++++++++++--------------
 1 file changed, 22 insertions(+), 28 deletions(-)

diff --git a/drivers/staging/iio/frequency/ad9834.c b/drivers/staging/iio/frequency/ad9834.c
index 0d20f796e0f0..c45bb388c998 100644
--- a/drivers/staging/iio/frequency/ad9834.c
+++ b/drivers/staging/iio/frequency/ad9834.c
@@ -6,6 +6,7 @@
  */
 
 #include <linux/bits.h>
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/dev_printk.h>
 #include <linux/err.h>
@@ -154,7 +155,8 @@ static ssize_t ad9834_write(struct device *dev,
 	if (ret)
 		return ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
+
 	switch ((u32)this_attr->address) {
 	case AD9834_REG_FREQ0:
 	case AD9834_REG_FREQ1:
@@ -165,10 +167,8 @@ static ssize_t ad9834_write(struct device *dev,
 		ret = ad9834_write_phase(st, this_attr->address, val);
 		break;
 	case AD9834_OPBITEN:
-		if (st->control & AD9834_MODE) {
-			ret = -EINVAL;  /* AD9834 reserved mode */
-			break;
-		}
+		if (st->control & AD9834_MODE)
+			return -EINVAL;  /* AD9834 reserved mode */
 
 		if (val)
 			st->control |= AD9834_OPBITEN;
@@ -194,8 +194,7 @@ static ssize_t ad9834_write(struct device *dev,
 			st->control |= this_attr->address;
 			st->control &= ~AD9834_PIN_SW;
 		} else {
-			ret = -EINVAL;
-			break;
+			return -EINVAL;
 		}
 		st->data = cpu_to_be16(AD9834_REG_CMD | st->control);
 		ret = spi_sync(st->spi, &st->msg);
@@ -210,9 +209,8 @@ static ssize_t ad9834_write(struct device *dev,
 		ret = spi_sync(st->spi, &st->msg);
 		break;
 	default:
-		ret = -ENODEV;
+		return -ENODEV;
 	}
-	mutex_unlock(&st->lock);
 
 	return ret ? ret : len;
 }
@@ -225,10 +223,10 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct ad9834_state *st = iio_priv(indio_dev);
 	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
-	int ret = 0;
 	bool is_ad9833_7 = (st->devid == ID_AD9833) || (st->devid == ID_AD9837);
+	int ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 
 	switch ((u32)this_attr->address) {
 	case 0:
@@ -241,7 +239,7 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 				st->control &= ~AD9834_OPBITEN;
 				st->control |= AD9834_MODE;
 			} else if (st->control & AD9834_OPBITEN) {
-				ret = -EINVAL;	/* AD9834 reserved mode */
+				return -EINVAL;	/* AD9834 reserved mode */
 			} else {
 				st->control |= AD9834_MODE;
 			}
@@ -249,31 +247,27 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 			st->control &= ~AD9834_MODE;
 			st->control |= AD9834_OPBITEN;
 		} else {
-			ret = -EINVAL;
+			return -EINVAL;
 		}
 
 		break;
 	case 1:
-		if (sysfs_streq(buf, "square") &&
-		    !(st->control & AD9834_MODE)) {
-			st->control &= ~AD9834_MODE;
-			st->control |= AD9834_OPBITEN;
-		} else {
-			ret = -EINVAL;
-		}
+		if (!sysfs_streq(buf, "square") || (st->control & AD9834_MODE))
+			return -EINVAL;
+
+		st->control &= ~AD9834_MODE;
+		st->control |= AD9834_OPBITEN;
 		break;
 	default:
-		ret = -EINVAL;
-		break;
+		return -EINVAL;
 	}
 
-	if (!ret) {
-		st->data = cpu_to_be16(AD9834_REG_CMD | st->control);
-		ret = spi_sync(st->spi, &st->msg);
-	}
-	mutex_unlock(&st->lock);
+	st->data = cpu_to_be16(AD9834_REG_CMD | st->control);
+	ret = spi_sync(st->spi, &st->msg);
+	if (ret)
+		return ret;
 
-	return ret ? ret : len;
+	return len;
 }
 
 static
-- 
2.51.0


