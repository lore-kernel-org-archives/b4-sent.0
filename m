From: Amir Atef <amiratefabdallah1122@gmail.com>
Subject: [PATCH] staging: iio: frequency: ad9834: use guard(mutex)
Date: Fri, 16 Oct 2026 14:17:12 +0300
Message-Id: <179214943270.333.5921549521929682753.20261016-ad9834-guard-mutex@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792149432; l=3644;
 i=amiratefabdallah1122@gmail.com; s=20261016; h=from:subject:message-id;
 bh=b1+SRs3iAPcCs6+33+xk+21acapvMkXoR0sdLd32oT4=;
 b=eTM9ePPa1AzM1Tbm5Ij4l2P8xsth9a3dmtSM+YUgQN+ZqFJFvY7lqeLrd3PmMUxYAIFollqXh
 sRMZsk01lYIAlbISZDi1QbuuKeJmaa16TioawPSa+pP47EwLhwRfyDp
X-Developer-Key: i=amiratefabdallah1122@gmail.com; a=ed25519;
 pk=FRhtQptjt3GSkQBUg7qfVL8eusorsJqHzciu3+ss11o=
X-Endpoint-Received: by B4 Relay for amiratefabdallah1122@gmail.com/20261016 with auth_id=1209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use guard(mutex) to manage the state lock in ad9834_write() and
ad9834_store_wavetype(). simplifies error handling by allowing
early returns instead of setting the return code and breaking out of the
switch statement to manually unlock the mutex.

Signed-off-by: Amir Atef <amiratefabdallah1122@gmail.com>
---
 drivers/staging/iio/frequency/ad9834.c | 34 ++++++++++++----------------------
 1 file changed, 12 insertions(+), 22 deletions(-)

diff --git a/drivers/staging/iio/frequency/ad9834.c b/drivers/staging/iio/frequency/ad9834.c
index 0d20f796e0f0..76a520280f68 100644
--- a/drivers/staging/iio/frequency/ad9834.c
+++ b/drivers/staging/iio/frequency/ad9834.c
@@ -8,6 +8,7 @@
  */
 
 #include <linux/bits.h>
+#include <linux/cleanup.h>
 #include <linux/clk.h>
 #include <linux/dev_printk.h>
 #include <linux/err.h>
@@ -155,7 +156,7 @@ static ssize_t ad9834_write(struct device *dev,
 	if (ret)
 		return ret;
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 	switch ((u32)this_attr->address) {
 	case AD9834_REG_FREQ0:
 	case AD9834_REG_FREQ1:
@@ -166,10 +167,8 @@ static ssize_t ad9834_write(struct device *dev,
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
@@ -193,8 +192,7 @@ static ssize_t ad9834_write(struct device *dev,
 			st->control |= this_attr->address;
 			st->control &= ~AD9834_PIN_SW;
 		} else {
-			ret = -EINVAL;
-			break;
+			return -EINVAL;
 		}
 		st->data = cpu_to_be16(AD9834_REG_CMD | st->control);
 		ret = spi_sync(st->spi, &st->msg);
@@ -209,9 +207,8 @@ static ssize_t ad9834_write(struct device *dev,
 		ret = spi_sync(st->spi, &st->msg);
 		break;
 	default:
-		ret = -ENODEV;
+		return -ENODEV;
 	}
-	mutex_unlock(&st->lock);
 
 	return ret ? ret : len;
 }
@@ -223,11 +220,11 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 	struct iio_dev *indio_dev = dev_to_iio_dev(dev);
 	struct ad9834_state *st = iio_priv(indio_dev);
 	struct iio_dev_attr *this_attr = to_iio_dev_attr(attr);
-	int ret = 0;
+	int ret;
 	bool is_ad9833_7 = (st->devid == ID_AD9833) || (st->devid == ID_AD9837);
 
-	mutex_lock(&st->lock);
+	guard(mutex)(&st->lock);
 
 	switch ((u32)this_attr->address) {
 	case 0:
@@ -239,7 +236,7 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 				st->control &= ~AD9834_OPBITEN;
 				st->control |= AD9834_MODE;
 			} else if (st->control & AD9834_OPBITEN) {
-				ret = -EINVAL;	/* AD9834 reserved mode */
+				return -EINVAL;	/* AD9834 reserved mode */
 			} else {
 				st->control |= AD9834_MODE;
 			}
@@ -247,7 +244,7 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 			st->control &= ~AD9834_MODE;
 			st->control |= AD9834_OPBITEN;
 		} else {
-			ret = -EINVAL;
+			return -EINVAL;
 		}
 
 		break;
@@ -257,19 +254,15 @@ static ssize_t ad9834_store_wavetype(struct device *dev,
 			st->control &= ~AD9834_MODE;
 			st->control |= AD9834_OPBITEN;
 		} else {
-			ret = -EINVAL;
+			return -EINVAL;
 		}
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
 
 	return ret ? ret : len;
 }
-- 
2.51.0


