From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 07 Dec 2023 13:39:26 +0100
Subject: [PATCH v2 3/8] iio: adc: ad9467: add mutex to struct ad9467_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-iio-backend-prep-v2-3-a4a33bc4d70e@analog.com>
References: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
In-Reply-To: <20231207-iio-backend-prep-v2-0-a4a33bc4d70e@analog.com>
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701952767; l=1696;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=LC5zHdfPHlS7n6KkhXG6jik7f2Wlr704ZcM0hmOoo7c=;
 b=oN+i0GCLFhpnqgEG9hXciaw/SXJ0Qv8vLECl0+LR8z2nNH352K97FOYvDLKBIrjGlyJoD+tHW
 USe3nPWQs3pCKh44rRYvZyvL9eBFE8vjyKJ/WDr3+yL1nHRvI8suLZQ
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When calling ad9467_set_scale(), multiple calls to ad9467_spi_write()
are done which means we need to properly protect the whole operation so
we are sure we will be in a sane state if two concurrent calls occur.

Fixes: ad6797120238 ("iio: adc: ad9467: add support AD9467 ADC")
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ad9467.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index d3c98c4eccd3..104c6d394a3e 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -4,8 +4,9 @@
  *
  * Copyright 2012-2020 Analog Devices Inc.
  */
-
+#include <linux/cleanup.h>
 #include <linux/module.h>
+#include <linux/mutex.h>
 #include <linux/device.h>
 #include <linux/kernel.h>
 #include <linux/slab.h>
@@ -121,6 +122,8 @@ struct ad9467_state {
 	unsigned int			output_mode;
 
 	struct gpio_desc		*pwrdown_gpio;
+	/* ensure consistent state obtained on multiple related accesses */
+	struct mutex			lock;
 };
 
 static int ad9467_spi_read(struct spi_device *spi, unsigned int reg)
@@ -161,6 +164,7 @@ static int ad9467_reg_access(struct adi_axi_adc_conv *conv, unsigned int reg,
 	int ret;
 
 	if (readval == NULL) {
+		guard(mutex)(&st->lock);
 		ret = ad9467_spi_write(spi, reg, writeval);
 		if (ret)
 			return ret;
@@ -310,6 +314,7 @@ static int ad9467_set_scale(struct adi_axi_adc_conv *conv, int val, int val2)
 		if (scale_val[0] != val || scale_val[1] != val2)
 			continue;
 
+		guard(mutex)(&st->lock);
 		ret = ad9467_spi_write(st->spi, AN877_ADC_REG_VREF,
 				       info->scale_table[i][1]);
 		if (ret < 0)

-- 
2.43.0

