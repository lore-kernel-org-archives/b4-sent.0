From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 31 May 2024 11:41:55 +0200
Subject: [PATCH v3 2/2] iio: adc: adi-axi-adc: make sure DRP is locked on
 enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240531-dev-axi-adc-drp-v3-2-e3fa79447c67@analog.com>
References: <20240531-dev-axi-adc-drp-v3-0-e3fa79447c67@analog.com>
In-Reply-To: <20240531-dev-axi-adc-drp-v3-0-e3fa79447c67@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717148521; l=1911;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=l64Ix/Gmc9pXNSX5ow7dG1cblWhfc28+HdYcrglxFJY=;
 b=hMCFMda3YhtZYcw2dODuRVxdHZCcUSevZtz8HNchEqf8hO1ZbxczSAuR5oKDADY3ys7mi7IUp
 ESvMtrMRFt8CxeCW7zE7yfx4yaKEBcBQAZaToXKY3qzyH+1EOXZ0ote
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When enabling the core, make sure DRP (Dynamic Reconfiguration Port)
is locked. Most of the designs don't really use it but we still get the
lock bit set. So let's do it all the time so the code is generic.

While at it reduce the timeout time to 1 microsecond as it seems to be
enough and goes in line with what we have on the similar DAC core
(adi-axi-dac).

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index bf51d619ebbc..0f8bd1d75131 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -42,6 +42,9 @@
 #define ADI_AXI_ADC_REG_CTRL			0x0044
 #define    ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK	BIT(1)
 
+#define ADI_AXI_ADC_REG_DRP_STATUS		0x0074
+#define   ADI_AXI_ADC_DRP_LOCKED		BIT(17)
+
 /* ADC Channel controls */
 
 #define ADI_AXI_REG_CHAN_CTRL(c)		(0x0400 + (c) * 0x40)
@@ -83,6 +86,7 @@ struct adi_axi_adc_state {
 static int axi_adc_enable(struct iio_backend *back)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	unsigned int __val;
 	int ret;
 
 	guard(mutex)(&st->lock);
@@ -91,7 +95,17 @@ static int axi_adc_enable(struct iio_backend *back)
 	if (ret)
 		return ret;
 
-	fsleep(10000);
+	/*
+	 * Make sure the DRP (Dynamic Reconfiguration Port) is locked. Not all
+	 * designs really use it but if they don't we still get the lock bit
+	 * set. So let's do it all the time so the code is generic.
+	 */
+	ret = regmap_read_poll_timeout(st->regmap, ADI_AXI_ADC_REG_DRP_STATUS,
+				       __val, __val & ADI_AXI_ADC_DRP_LOCKED,
+				       100, 1000);
+	if (ret)
+		return ret;
+
 	return regmap_set_bits(st->regmap, ADI_AXI_REG_RSTN,
 			       ADI_AXI_REG_RSTN_RSTN | ADI_AXI_REG_RSTN_MMCM_RSTN);
 }

-- 
2.45.1

