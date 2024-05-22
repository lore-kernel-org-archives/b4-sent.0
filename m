From: Nuno Sa <nuno.sa@analog.com>
Date: Wed, 22 May 2024 15:14:56 +0200
Subject: [PATCH v2] iio: adc: adi-axi-adc: make sure DRP is locked on
 enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240522-dev-axi-adc-drp-v2-1-b63c9790a48a@analog.com>
X-B4-Tracking: v=1; b=H4sIAM/vTWYC/3WNQQ6CMBBFr0Jm7Zi2SgVX3sOwGOkAkyglrWkwp
 He3snf5XvLf3yByEI5wrTYInCSKnwuYQwX9RPPIKK4wGGXOqlYWHSekVZBcjy4sSGwfrnUnY/U
 FymoJPMi6F+9d4Uni24fPfpD0z/5vJY0aG2epqe3QqpZvNNPTj8fev6DLOX8BDamKaa8AAAA=
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716383697; l=2681;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Pe6bUQm9SfdBpBcwS0s69lmSgXMkhkpPj+U4DdXlRyo=;
 b=x08YBcrQtzf5svic0QHBtYDSVIIhildhtQd1/7v6ETofv4QJ7tJoMn8cka5yC0siSm6WRNlZ2
 ZzOZaqYRnN9Ck7eXaT3PzHoBL6JZd18UmxzMoz6CvXEWZZeUsNtHcYf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When enabling the core, make sure DRP (Dynamic Reconfiguration Port)
is locked. Most of the designs don't really use it but we still get the
lock bit set. So let's do it all the time so the code is generic.

While at it add proper mutex guards as we should not be able to disable
the core in the middle of enabling it. Also reduce the timeout time to 1
microsecond as it seems to be enough and goes in line with what we have
on the similar DAC core (adi-axi-dac).

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
Changes in v2:
- Fixed typo in commit message;
- Renamed the AXI_ADC_DRP_STATUS -> ADI_AXI_ADC_REG_DRP_STATUS and
  AXI_ADC_DRP_LOCKED -> ADI_AXI_ADC_DRP_LOCKED fro consistency.
- Link to v1: https://lore.kernel.org/r/20240506-dev-axi-adc-drp-v1-1-8d6a856f909e@analog.com
---
 drivers/iio/adc/adi-axi-adc.c | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 0cf0d81358fd5..d54567cf40c64 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -42,6 +42,9 @@
 #define ADI_AXI_ADC_REG_CTRL			0x0044
 #define    ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK	BIT(1)
 
+#define ADI_AXI_ADC_REG_DRP_STATUS			0x0074
+#define   ADI_AXI_ADC_DRP_LOCKED			BIT(17)
+
 /* ADC Channel controls */
 
 #define ADI_AXI_REG_CHAN_CTRL(c)		(0x0400 + (c) * 0x40)
@@ -83,14 +86,26 @@ struct adi_axi_adc_state {
 static int axi_adc_enable(struct iio_backend *back)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	unsigned int __val;
 	int ret;
 
+	guard(mutex)(&st->lock);
 	ret = regmap_set_bits(st->regmap, ADI_AXI_REG_RSTN,
 			      ADI_AXI_REG_RSTN_MMCM_RSTN);
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
@@ -99,6 +114,7 @@ static void axi_adc_disable(struct iio_backend *back)
 {
 	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
 
+	guard(mutex)(&st->lock);
 	regmap_write(st->regmap, ADI_AXI_REG_RSTN, 0);
 }
 

---
base-commit: 5e3c5871138da700796587aa5f096d39135f9d36
change-id: 20240506-dev-axi-adc-drp-ae6bd9d32617
--

Thanks!
- Nuno Sá

