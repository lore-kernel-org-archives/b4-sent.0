From: Radu Sabau <radu.sabau@analog.com>
Date: Mon, 23 Nov 2026 15:25:26 +0200
Subject: [PATCH 2/7] iio: imu: adis: Add a kfifo buffer setup helper for
 FIFO devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-adis-fifo-v1-2-f6ad9e493e19@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795440327; l=8434;
 i=radu.sabau@analog.com; s=20261001; h=from:subject:message-id;
 bh=gsQHAC9QTe/dAmiHhtXzAdEosCoLWNzpLjvdYa7amHw=;
 b=5/Jr3WeuIC0narguV8H1Jyqs6VYr7pVcYOmkRto8Xj+9VK2/hKBPbinqfhyWSmLmRxCfpJDSh
 BIuiBx6MEp/D7xyREY9sA/N9mOu/V1Pjr9fNO2/Y2/ncnFV93mPCKPc
X-Developer-Key: i=radu.sabau@analog.com; a=ed25519;
 pk=XOZSO/Ut8qfYw7khL8lUF65Pgl+VLihISyS+Iy9jY8c=
X-Endpoint-Received: by B4 Relay for radu.sabau@analog.com/20261001 with auth_id=1094
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Devices with a hardware FIFO (has_fifo) currently go through the
triggered buffer: the FIFO interrupt is requested with
iio_trigger_generic_data_rdy_poll() as its thread function, which calls
iio_trigger_poll() from the IRQ thread, and the samples are read from a
trigger handler. iio_trigger_poll() is meant to be called from hard
interrupt context, and the FIFO then depends on whatever trigger is
selected.

Add devm_adis_setup_kfifo_buffer() for such devices. It sets up a kfifo
buffer and requests the FIFO interrupt as a oneshot threaded IRQ running a
handler supplied by the driver, which reads the FIFO and pushes the
samples. The interrupt is requested disabled, and the driver enables and
disables it with enable_irq() and disable_irq() from its buffer setup
functions. This is done without the adis lock, which the handler takes.

The trigger/current_trigger attribute is user visible on the existing FIFO
devices, so add devm_adis_register_fifo_trigger() for them to keep it. It
registers a trigger with the usual name and sets INDIO_HARDWARE_TRIGGERED
so the attribute exists. The buffer runs in software mode, so the trigger
has no effect on it: writing it is accepted and ignored, as
hid-sensor-trigger does for the same reason. New drivers do not need it.

No driver uses the helpers yet.

Signed-off-by: Radu Sabau <radu.sabau@analog.com>
---
 drivers/iio/imu/Kconfig        |  1 +
 drivers/iio/imu/adis_buffer.c  | 45 ++++++++++++++++++++++++++++++++++
 drivers/iio/imu/adis_trigger.c | 55 ++++++++++++++++++++++++++++++++++++++++++
 include/linux/iio/imu/adis.h   | 32 ++++++++++++++++++++++++
 4 files changed, 133 insertions(+)

diff --git a/drivers/iio/imu/Kconfig b/drivers/iio/imu/Kconfig
index 8b91426f60d0..b00acccab061 100644
--- a/drivers/iio/imu/Kconfig
+++ b/drivers/iio/imu/Kconfig
@@ -151,6 +151,7 @@ config IIO_ADIS_LIB
 
 config IIO_ADIS_LIB_BUFFER
 	bool
+	select IIO_KFIFO_BUF
 	select IIO_TRIGGERED_BUFFER
 	help
 	  A set of buffer helper functions for the Analog Devices ADIS* device
diff --git a/drivers/iio/imu/adis_buffer.c b/drivers/iio/imu/adis_buffer.c
index 501da4eaef69..e49e02adeda6 100644
--- a/drivers/iio/imu/adis_buffer.c
+++ b/drivers/iio/imu/adis_buffer.c
@@ -15,6 +15,7 @@
 
 #include <linux/iio/iio.h>
 #include <linux/iio/buffer.h>
+#include <linux/iio/kfifo_buf.h>
 #include <linux/iio/trigger_consumer.h>
 #include <linux/iio/triggered_buffer.h>
 #include <linux/iio/imu/adis.h>
@@ -220,3 +221,47 @@ devm_adis_setup_buffer_and_trigger_with_attrs(struct adis *adis, struct iio_dev
 					adis);
 }
 EXPORT_SYMBOL_NS_GPL(devm_adis_setup_buffer_and_trigger_with_attrs, "IIO_ADISLIB");
+
+/**
+ * devm_adis_setup_kfifo_buffer() - Sets up a kfifo buffer for a FIFO adis device
+ * @adis: The adis device
+ * @indio_dev: The IIO device
+ * @thread_fn: Threaded interrupt handler which reads the device FIFO and
+ *	       pushes the samples to the buffer. It is called with @indio_dev
+ *	       as dev_id.
+ * @ops: Optional buffer setup functions, may be NULL.
+ * @buffer_attrs: Extra buffer attributes.
+ *
+ * Returns 0 on success, a negative error code otherwise.
+ *
+ * Unlike devm_adis_setup_buffer_and_trigger_with_attrs(), the samples are not
+ * captured from a trigger handler. The device FIFO interrupt is requested as a
+ * threaded oneshot IRQ running @thread_fn, and the data goes straight to a
+ * kfifo buffer. The IRQ is requested disabled and the driver enables and
+ * disables it with enable_irq() and disable_irq() from its buffer setup
+ * functions, without holding the adis lock. Devices which already had a
+ * trigger/current_trigger attribute can keep it with
+ * devm_adis_register_fifo_trigger().
+ */
+int devm_adis_setup_kfifo_buffer(struct adis *adis, struct iio_dev *indio_dev,
+				 irq_handler_t thread_fn,
+				 const struct iio_buffer_setup_ops *ops,
+				 const struct iio_dev_attr **buffer_attrs)
+{
+	int ret;
+
+	ret = devm_iio_kfifo_buffer_setup_ext(&adis->spi->dev, indio_dev, ops,
+					      buffer_attrs);
+	if (ret)
+		return ret;
+
+	if (adis->spi->irq) {
+		ret = devm_adis_request_fifo_irq(adis, indio_dev, thread_fn);
+		if (ret)
+			return ret;
+	}
+
+	return devm_add_action_or_reset(&adis->spi->dev, adis_buffer_cleanup,
+					adis);
+}
+EXPORT_SYMBOL_NS_GPL(devm_adis_setup_kfifo_buffer, "IIO_ADISLIB");
diff --git a/drivers/iio/imu/adis_trigger.c b/drivers/iio/imu/adis_trigger.c
index 3e6a7af6ab01..ea8661bff901 100644
--- a/drivers/iio/imu/adis_trigger.c
+++ b/drivers/iio/imu/adis_trigger.c
@@ -104,3 +104,58 @@ int devm_adis_probe_trigger(struct adis *adis, struct iio_dev *indio_dev)
 }
 EXPORT_SYMBOL_NS_GPL(devm_adis_probe_trigger, "IIO_ADISLIB");
 
+/**
+ * devm_adis_request_fifo_irq() - Requests the FIFO interrupt of an adis device
+ * @adis: The adis device
+ * @indio_dev: The IIO device
+ * @thread_fn: Threaded interrupt handler, called with @indio_dev as dev_id
+ *
+ * Requests the (level triggered) FIFO interrupt as a oneshot threaded IRQ. The
+ * IRQ is requested disabled: the driver enables it with enable_irq() once the
+ * device FIFO is running and disables it with disable_irq() before stopping
+ * it, without holding the adis lock as @thread_fn takes it.
+ *
+ * Returns 0 on success or a negative error code
+ */
+int devm_adis_request_fifo_irq(struct adis *adis, struct iio_dev *indio_dev,
+			       irq_handler_t thread_fn)
+{
+	int ret;
+
+	ret = adis_validate_irq_flag(adis);
+	if (ret)
+		return ret;
+
+	adis->irq_flag |= IRQF_NO_AUTOEN;
+
+	return devm_request_threaded_irq(&adis->spi->dev, adis->spi->irq, NULL,
+					 thread_fn, adis->irq_flag | IRQF_ONESHOT,
+					 indio_dev->name, indio_dev);
+}
+EXPORT_SYMBOL_NS_GPL(devm_adis_request_fifo_irq, "IIO_ADISLIB");
+
+/**
+ * devm_adis_register_fifo_trigger() - Registers the legacy trigger of a FIFO device
+ * @adis: The adis device
+ * @indio_dev: The IIO device
+ *
+ * Registers an IIO trigger named after the device. It is never used to push
+ * samples, as the data goes to a kfifo buffer. It only keeps the
+ * trigger/current_trigger interface of devices that always had it, so writing
+ * it is accepted but has no effect. New drivers do not need it.
+ *
+ * Returns 0 on success or a negative error code
+ */
+int devm_adis_register_fifo_trigger(struct adis *adis, struct iio_dev *indio_dev)
+{
+	adis->trig = devm_iio_trigger_alloc(&adis->spi->dev, "%s-dev%d",
+					    indio_dev->name,
+					    iio_device_id(indio_dev));
+	if (!adis->trig)
+		return -ENOMEM;
+
+	indio_dev->modes |= INDIO_HARDWARE_TRIGGERED;
+
+	return devm_iio_trigger_register(&adis->spi->dev, adis->trig);
+}
+EXPORT_SYMBOL_NS_GPL(devm_adis_register_fifo_trigger, "IIO_ADISLIB");
diff --git a/include/linux/iio/imu/adis.h b/include/linux/iio/imu/adis.h
index c9016f636530..4f87321a2d5e 100644
--- a/include/linux/iio/imu/adis.h
+++ b/include/linux/iio/imu/adis.h
@@ -569,6 +569,16 @@ devm_adis_setup_buffer_and_trigger_with_attrs(struct adis *adis,
 
 int devm_adis_probe_trigger(struct adis *adis, struct iio_dev *indio_dev);
 
+int devm_adis_setup_kfifo_buffer(struct adis *adis, struct iio_dev *indio_dev,
+				 irq_handler_t thread_fn,
+				 const struct iio_buffer_setup_ops *ops,
+				 const struct iio_dev_attr **buffer_attrs);
+
+int devm_adis_request_fifo_irq(struct adis *adis, struct iio_dev *indio_dev,
+			       irq_handler_t thread_fn);
+
+int devm_adis_register_fifo_trigger(struct adis *adis, struct iio_dev *indio_dev);
+
 int adis_update_scan_mode(struct iio_dev *indio_dev,
 			  const unsigned long *scan_mask);
 
@@ -590,6 +600,28 @@ static inline int devm_adis_probe_trigger(struct adis *adis,
 	return 0;
 }
 
+static inline int
+devm_adis_setup_kfifo_buffer(struct adis *adis, struct iio_dev *indio_dev,
+			     irq_handler_t thread_fn,
+			     const struct iio_buffer_setup_ops *ops,
+			     const struct iio_dev_attr **buffer_attrs)
+{
+	return 0;
+}
+
+static inline int
+devm_adis_request_fifo_irq(struct adis *adis, struct iio_dev *indio_dev,
+			   irq_handler_t thread_fn)
+{
+	return 0;
+}
+
+static inline int
+devm_adis_register_fifo_trigger(struct adis *adis, struct iio_dev *indio_dev)
+{
+	return 0;
+}
+
 #define adis_update_scan_mode NULL
 
 #endif /* CONFIG_IIO_BUFFER */

-- 
2.43.0

