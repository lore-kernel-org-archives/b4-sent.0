From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:28 +0200
Subject: [PATCH 4/7] iio: imu: adis16475: Use a kfifo buffer for the
 devices with a FIFO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-4-f6ad9e493e19@analog.com>
References: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
In-Reply-To: <20261123-adis-fifo-v1-0-f6ad9e493e19@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, 
 Ramona Gradinariu <ramona.bolboaca13@gmail.com>, 
 Radu Sabau <radu.sabau@analog.com>
Cc: linux-iio@vger.kernel.org, linux@analog.com, 
 linux-kernel@vger.kernel.org, Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=5523;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=DKqWxjSownX7PQ6rmCCXSFYEawwf4xKEOAeGkoBi/ig=;
 b=+k0pd6ke7ueV2GuH5FZRikSHH2Wi9y+NlqJuVUoakK6bNCyv+S47IJTvfc+Z7JoAfdgN5UTOh
 vrOuMZc8DG9ClH3HZgS0+NpEGF2FPQ0Q0nZ8rE0a5pCLHvwf57HhgQC
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ADIS1657x variants read their FIFO from a trigger handler, which runs
from iio_trigger_poll() called in the FIFO interrupt thread, and the
capture depends on the selected trigger.

Switch them to devm_adis_setup_kfifo_buffer(): the FIFO interrupt thread
now reads the FIFO and pushes the samples to a kfifo buffer. The interrupt
is requested disabled and is enabled once the device FIFO is running, and
disabled before it is stopped, from the buffer setup functions. This
replaces the trigger's set_trigger_state(), which did the same through
adis_enable_irq().

The trigger is still registered and trigger/current_trigger is unchanged
for users: the buffer simply does not use it any more, so writing it has
no effect and a buffer can now also be enabled without selecting one.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/adis16475.c | 55 ++++++++++++++++++++++++++++++---------------
 1 file changed, 37 insertions(+), 18 deletions(-)

diff --git a/drivers/iio/imu/adis16475.c b/drivers/iio/imu/adis16475.c
index 6922ffb48516..394b13431ae8 100644
--- a/drivers/iio/imu/adis16475.c
+++ b/drivers/iio/imu/adis16475.c
@@ -517,9 +517,26 @@ static int adis16475_buffer_postenable(struct iio_dev *indio_dev)
 {
 	struct adis16475 *st = iio_priv(indio_dev);
 	struct adis *adis = &st->adis;
+	int ret;
+
+	ret = adis_update_bits(adis, ADIS16475_REG_FIFO_CTRL,
+			       ADIS16575_FIFO_EN_MASK, (u16)ADIS16575_FIFO_EN(1));
+	if (ret)
+		return ret;
+
+	enable_irq(adis->spi->irq);
 
-	return adis_update_bits(adis, ADIS16475_REG_FIFO_CTRL,
-				ADIS16575_FIFO_EN_MASK, (u16)ADIS16575_FIFO_EN(1));
+	return 0;
+}
+
+static int adis16475_buffer_predisable(struct iio_dev *indio_dev)
+{
+	struct adis16475 *st = iio_priv(indio_dev);
+
+	/* Not under the adis lock: this waits for the IRQ thread, which takes it */
+	disable_irq(st->adis.spi->irq);
+
+	return 0;
 }
 
 static int adis16475_buffer_postdisable(struct iio_dev *indio_dev)
@@ -541,6 +558,7 @@ static int adis16475_buffer_postdisable(struct iio_dev *indio_dev)
 
 static const struct iio_buffer_setup_ops adis16475_buffer_ops = {
 	.postenable = adis16475_buffer_postenable,
+	.predisable = adis16475_buffer_predisable,
 	.postdisable = adis16475_buffer_postdisable,
 };
 
@@ -1708,7 +1726,7 @@ static int adis16575_custom_burst_read(struct iio_dev *indio_dev, u8 burst_req,
 }
 
 /*
- * This handler is meant to be used for devices which support burst readings
+ * This IRQ thread is meant to be used for devices which support burst readings
  * from FIFO (namely devices from adis1657x family).
  * In order to pop the FIFO the 0x68 0x00 FIFO pop burst request has to be sent.
  * If the previous device command was not a FIFO pop burst request, the FIFO pop
@@ -1721,12 +1739,12 @@ static int adis16575_custom_burst_read(struct iio_dev *indio_dev, u8 burst_req,
  * different from a 0x68 0x00 or a 0x00 0x00 burst request, the FIFO data popped
  * previously will be lost.
  */
-static irqreturn_t adis16475_trigger_handler_with_fifo(int irq, void *p)
+static irqreturn_t adis16475_fifo_irq_thread(int irq, void *p)
 {
-	struct iio_poll_func *pf = p;
-	struct iio_dev *indio_dev = pf->indio_dev;
+	struct iio_dev *indio_dev = p;
 	struct adis16475 *st = iio_priv(indio_dev);
 	struct adis *adis = &st->adis;
+	s64 timestamp = iio_get_time_ns(indio_dev);
 	int ret;
 	u16 fifo_cnt, i;
 
@@ -1736,10 +1754,7 @@ static irqreturn_t adis16475_trigger_handler_with_fifo(int irq, void *p)
 	if (ret)
 		goto unlock;
 
-	/*
-	 * If no sample is available, nothing can be read. This can happen if
-	 * a the used trigger has a higher frequency than the selected sample rate.
-	 */
+	/* If no sample is available, nothing can be read. */
 	if (!fifo_cnt)
 		goto unlock;
 
@@ -1748,18 +1763,18 @@ static irqreturn_t adis16475_trigger_handler_with_fifo(int irq, void *p)
 	 * next burst request.
 	 */
 	ret = adis16575_custom_burst_read(indio_dev, adis->data->burst_reg_cmd,
-					  pf->timestamp);
+					  timestamp);
 	if (ret)
 		goto unlock;
 
 	for (i = 0; i < fifo_cnt - 1; i++) {
-		ret = adis16475_push_single_sample(indio_dev, pf->timestamp);
+		ret = adis16475_push_single_sample(indio_dev, timestamp);
 		if (ret)
 			goto unlock;
 	}
 
 	/* FIFO read without popping */
-	ret = adis16575_custom_burst_read(indio_dev, 0, pf->timestamp);
+	ret = adis16575_custom_burst_read(indio_dev, 0, timestamp);
 
 unlock:
 	/*
@@ -1767,7 +1782,6 @@ static irqreturn_t adis16475_trigger_handler_with_fifo(int irq, void *p)
 	 * reading data from registers will impact the FIFO reading.
 	 */
 	adis16475_burst32_check(st);
-	iio_trigger_notify_done(indio_dev->trig);
 
 	return IRQ_HANDLED;
 }
@@ -1978,10 +1992,15 @@ static int adis16475_probe(struct spi_device *spi)
 		return ret;
 
 	if (st->adis.data->has_fifo) {
-		ret = devm_adis_setup_buffer_and_trigger_with_attrs(&st->adis, indio_dev,
-								    adis16475_trigger_handler_with_fifo,
-								    &adis16475_buffer_ops,
-								    adis16475_fifo_attributes);
+		ret = devm_adis_setup_kfifo_buffer(&st->adis, indio_dev,
+						   adis16475_fifo_irq_thread,
+						   &adis16475_buffer_ops,
+						   adis16475_fifo_attributes);
+		if (ret)
+			return ret;
+
+		/* Keep the trigger/current_trigger interface of these devices */
+		ret = devm_adis_register_fifo_trigger(&st->adis, indio_dev);
 		if (ret)
 			return ret;
 

-- 
2.43.0

