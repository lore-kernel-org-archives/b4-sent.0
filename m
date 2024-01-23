From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 23 Jan 2024 16:14:27 +0100
Subject: [PATCH v7 6/9] iio: buffer-dmaengine: export buffer alloc and free
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240123-iio-backend-v7-6-1bff236b8693@analog.com>
References: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
In-Reply-To: <20240123-iio-backend-v7-0-1bff236b8693@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Frank Rowand <frowand.list@gmail.com>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Saravana Kannan <saravanak@google.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706022871; l=3896;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6pMFXM0wCdg3Id7C+f0CPli3rW2y13iOegJBdE0KPUQ=;
 b=x+kT0NW+CBWtL0y8nI3w8oL8rxeNLSDTUVtwRM5O55pRN2iksreSU7DMbgg780WLGomaRVs/X
 GHEj+oghwM3CTiCydiU3VkmLcVx05lsaukdRloF51PSkBOJnesjJEvR
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Export iio_dmaengine_buffer_free() and iio_dmaengine_buffer_alloc().
This is in preparation of introducing IIO backends support. This will
allow us to allocate a buffer and control it's lifetime from a device
different from the one holding the DMA firmware properties. Effectively,
in this case the struct device holding the firmware information about
the DMA channels is not the same as iio_dev->dev.parent (typical case).

While at it, namespace the buffer-dmaengine exports and update the
current user of these buffers.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/adi-axi-adc.c                      | 1 +
 drivers/iio/buffer/industrialio-buffer-dmaengine.c | 8 +++++---
 include/linux/iio/buffer-dmaengine.h               | 3 +++
 3 files changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/adc/adi-axi-adc.c b/drivers/iio/adc/adi-axi-adc.c
index c247ff1541d2..0f21d1d98b9f 100644
--- a/drivers/iio/adc/adi-axi-adc.c
+++ b/drivers/iio/adc/adi-axi-adc.c
@@ -447,3 +447,4 @@ module_platform_driver(adi_axi_adc_driver);
 MODULE_AUTHOR("Michael Hennerich <michael.hennerich@analog.com>");
 MODULE_DESCRIPTION("Analog Devices Generic AXI ADC IP core driver");
 MODULE_LICENSE("GPL v2");
+MODULE_IMPORT_NS(IIO_DMAENGINE_BUFFER);
diff --git a/drivers/iio/buffer/industrialio-buffer-dmaengine.c b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
index 45fe7d0d42ee..a18c1da292af 100644
--- a/drivers/iio/buffer/industrialio-buffer-dmaengine.c
+++ b/drivers/iio/buffer/industrialio-buffer-dmaengine.c
@@ -159,7 +159,7 @@ static const struct iio_dev_attr *iio_dmaengine_buffer_attrs[] = {
  * Once done using the buffer iio_dmaengine_buffer_free() should be used to
  * release it.
  */
-static struct iio_buffer *iio_dmaengine_buffer_alloc(struct device *dev,
+struct iio_buffer *iio_dmaengine_buffer_alloc(struct device *dev,
 	const char *channel)
 {
 	struct dmaengine_buffer *dmaengine_buffer;
@@ -210,6 +210,7 @@ static struct iio_buffer *iio_dmaengine_buffer_alloc(struct device *dev,
 	kfree(dmaengine_buffer);
 	return ERR_PTR(ret);
 }
+EXPORT_SYMBOL_NS_GPL(iio_dmaengine_buffer_alloc, IIO_DMAENGINE_BUFFER);
 
 /**
  * iio_dmaengine_buffer_free() - Free dmaengine buffer
@@ -217,7 +218,7 @@ static struct iio_buffer *iio_dmaengine_buffer_alloc(struct device *dev,
  *
  * Frees a buffer previously allocated with iio_dmaengine_buffer_alloc().
  */
-static void iio_dmaengine_buffer_free(struct iio_buffer *buffer)
+void iio_dmaengine_buffer_free(struct iio_buffer *buffer)
 {
 	struct dmaengine_buffer *dmaengine_buffer =
 		iio_buffer_to_dmaengine_buffer(buffer);
@@ -227,6 +228,7 @@ static void iio_dmaengine_buffer_free(struct iio_buffer *buffer)
 
 	iio_buffer_put(buffer);
 }
+EXPORT_SYMBOL_NS_GPL(iio_dmaengine_buffer_free, IIO_DMAENGINE_BUFFER);
 
 static void __devm_iio_dmaengine_buffer_free(void *buffer)
 {
@@ -287,7 +289,7 @@ int devm_iio_dmaengine_buffer_setup(struct device *dev,
 
 	return iio_device_attach_buffer(indio_dev, buffer);
 }
-EXPORT_SYMBOL_GPL(devm_iio_dmaengine_buffer_setup);
+EXPORT_SYMBOL_NS_GPL(devm_iio_dmaengine_buffer_setup, IIO_DMAENGINE_BUFFER);
 
 MODULE_AUTHOR("Lars-Peter Clausen <lars@metafoo.de>");
 MODULE_DESCRIPTION("DMA buffer for the IIO framework");
diff --git a/include/linux/iio/buffer-dmaengine.h b/include/linux/iio/buffer-dmaengine.h
index 5c355be89814..cbb8ba957fad 100644
--- a/include/linux/iio/buffer-dmaengine.h
+++ b/include/linux/iio/buffer-dmaengine.h
@@ -10,6 +10,9 @@
 struct iio_dev;
 struct device;
 
+struct iio_buffer *iio_dmaengine_buffer_alloc(struct device *dev,
+					      const char *channel);
+void iio_dmaengine_buffer_free(struct iio_buffer *buffer);
 int devm_iio_dmaengine_buffer_setup(struct device *dev,
 				    struct iio_dev *indio_dev,
 				    const char *channel);

-- 
2.43.0

