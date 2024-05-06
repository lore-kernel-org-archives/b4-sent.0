From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 06 May 2024 16:50:14 +0200
Subject: [PATCH] iio: adc: adi-axi-adc: make sure DRP is locked on enable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240506-dev-axi-adc-drp-v1-1-8d6a856f909e@analog.com>
X-B4-Tracking: v=1; b=H4sIACXuOGYC/x3MQQqAIBBA0avErBswK6OuEi3MmWo2FgohiHdPW
 r7F/xkiB+EIS5Mh8CtRbl/RtQ24y/qTUagatNKDGpVB4hdtErTkkMKDls1OM/XadBPU6gl8SPq
 P61bKB6XYMeVhAAAA
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1715007016; l=2359;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Ou6OWiJZRzymhEsoJAN5Nc0NJCfxBqb9AS935zux47s=;
 b=EjuCIqKrBYcMCu1/Bgb2mPJh6HDKh/ZRkIffuQ9g0cHK6mV5izrEzdegamHNtYKGpVS+CeVcJ
 uVFhR5mP8cND4kC505agItOlG/FOmLQhWMrnxLlTggCmy5symnYoBza
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We enabling the core, make sure DRP (Dynamic Reconfiguration Port)
is locked. Most of the designs don't really use it but we still get the
lock bit set. So let's do it all the time so the code is generic.

While at it add proper mutex guards as we should not be able to disable
the core in the middle of enabling it. Also reduce the timeout time to 1
microsecond as it seems to be enough and goes in line with what we have
on the similar DAC core (adi-axi-dac).

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index 0cf0d81358fd5..782d8813bb43b 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -42,6 +42,9 @@
 #define ADI_AXI_ADC_REG_CTRL			0x0044
 #define    ADI_AXI_ADC_CTRL_DDR_EDGESEL_MASK	BIT(1)
 
+#define AXI_ADC_DRP_STATUS			0x0074
+#define   AXI_ADC_DRP_LOCKED			BIT(17)
+
 /* ADC Channel controls */
 
 #define ADI_AXI_REG_CHAN_CTRL(c)		(0x0400 + (c) * 0x40)
@@ -83,14 +86,25 @@ struct adi_axi_adc_state {
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
+	ret = regmap_read_poll_timeout(st->regmap, AXI_ADC_DRP_STATUS, __val,
+				       __val & AXI_ADC_DRP_LOCKED, 100, 1000);
+	if (ret)
+		return ret;
+
 	return regmap_set_bits(st->regmap, ADI_AXI_REG_RSTN,
 			       ADI_AXI_REG_RSTN_RSTN | ADI_AXI_REG_RSTN_MMCM_RSTN);
 }
@@ -99,6 +113,7 @@ static void axi_adc_disable(struct iio_backend *back)
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

