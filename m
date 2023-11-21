From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 21 Nov 2023 11:20:19 +0100
Subject: [PATCH 06/12] iio: adc: ad9467: add mutex to struct ad9467_state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-dev-iio-backend-v1-6-6a3d542eba35@analog.com>
References: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
In-Reply-To: <20231121-dev-iio-backend-v1-0-6a3d542eba35@analog.com>
To: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-iio@vger.kernel.org
Cc: Olivier MOYSAN <olivier.moysan@foss.st.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700562016; l=1622;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=g3tcVMAWnAaNpfd4zR0L8lXR29z5KekLRZe6sxMF/hk=;
 b=c73pLlPBK+gRvwbzpMIaQzg2/RJK0F0Puv/XvfzcIUdIwAgeIeOujPcKeq6HBext2kU07mya6
 y+9u9e194XEB1j4VRHh9o3JjEgyQO25ay/PCBtt95QyHrc9TUVacvKt
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
 drivers/iio/adc/ad9467.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/ad9467.c b/drivers/iio/adc/ad9467.c
index 04474dbfa631..91821dee03b7 100644
--- a/drivers/iio/adc/ad9467.c
+++ b/drivers/iio/adc/ad9467.c
@@ -4,7 +4,7 @@
  *
  * Copyright 2012-2020 Analog Devices Inc.
  */
-
+#include <linux/cleanup.h>
 #include <linux/module.h>
 #include <linux/mutex.h>
 #include <linux/device.h>
@@ -122,6 +122,8 @@ struct ad9467_state {
 	unsigned int			output_mode;
 
 	struct gpio_desc		*pwrdown_gpio;
+	/* protect against concurrent accesses to the device */
+	struct mutex			lock;
 };
 
 static int ad9467_spi_read(struct spi_device *spi, unsigned int reg)
@@ -162,6 +164,7 @@ static int ad9467_reg_access(struct adi_axi_adc_conv *conv, unsigned int reg,
 	int ret;
 
 	if (!readval) {
+		guard(mutex)(&st->lock);
 		ret = ad9467_spi_write(spi, reg, writeval);
 		if (ret)
 			return ret;
@@ -310,6 +313,7 @@ static int ad9467_set_scale(struct adi_axi_adc_conv *conv, int val, int val2)
 		if (scale_val[0] != val || scale_val[1] != val2)
 			continue;
 
+		guard(mutex)(&st->lock);
 		ret = ad9467_spi_write(st->spi, AN877_ADC_REG_VREF,
 				       info->scale_table[i][1]);
 		if (ret < 0)

-- 
2.42.1

