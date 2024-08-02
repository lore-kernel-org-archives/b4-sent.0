From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 02 Aug 2024 16:27:03 +0200
Subject: [PATCH v2 5/8] iio: adc: adi-axi-adc: split axi_adc_chan_status()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-5-4cb62852f0d0@analog.com>
References: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
In-Reply-To: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=1692;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=V0ifC8BkhpqXxH/+MuvvxC8gC/RczC5y3WDjHB0pmiY=;
 b=APYikaO/jqUxR4xJ5wdlIuD5H7uWkbeMGiiXyFbxn4srU4q6/3cg7rHtyiiwTqeILeerAwpdP
 iZkTYxVOCEIA8RYIVWNhWBi3mEDaa10/qcuM7Ii21arDiZJRMLVSQE3
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new axi_adc_read_chan_status() helper so we get the raw register
value out of it.

This is in preparation of a future change where we really want to look
into dedicated bits of the register.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c | 19 ++++++++++++++-----
 1 file changed, 14 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index f4cdfcca865d..442a87024e1a 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -208,12 +208,10 @@ static int axi_adc_test_pattern_set(struct iio_backend *back,
 	}
 }
 
-static int axi_adc_chan_status(struct iio_backend *back, unsigned int chan,
-			       bool *error)
+static int axi_adc_read_chan_status(struct adi_axi_adc_state *st, unsigned int chan,
+				    unsigned int *status)
 {
-	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
 	int ret;
-	u32 val;
 
 	guard(mutex)(&st->lock);
 	/* reset test bits by setting them */
@@ -225,7 +223,18 @@ static int axi_adc_chan_status(struct iio_backend *back, unsigned int chan,
 	/* let's give enough time to validate or erroring the incoming pattern */
 	fsleep(1000);
 
-	ret = regmap_read(st->regmap, ADI_AXI_ADC_REG_CHAN_STATUS(chan), &val);
+	return regmap_read(st->regmap, ADI_AXI_ADC_REG_CHAN_STATUS(chan),
+			   status);
+}
+
+static int axi_adc_chan_status(struct iio_backend *back, unsigned int chan,
+			       bool *error)
+{
+	struct adi_axi_adc_state *st = iio_backend_get_priv(back);
+	u32 val;
+	int ret;
+
+	ret = axi_adc_read_chan_status(st, chan, &val);
 	if (ret)
 		return ret;
 

-- 
2.45.2

