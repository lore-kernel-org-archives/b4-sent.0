From: Nuno Sa <nuno.sa@analog.com>
Date: Thu, 28 Mar 2024 14:22:25 +0100
Subject: [PATCH 01/10] iio: buffer: add helper for setting direction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-iio-backend-axi-dac-v1-1-afc808b3fde3@analog.com>
References: <20240328-iio-backend-axi-dac-v1-0-afc808b3fde3@analog.com>
In-Reply-To: <20240328-iio-backend-axi-dac-v1-0-afc808b3fde3@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Dragos Bogdan <dragos.bogdan@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711632149; l=1414;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=lt7Z8RtIdxVgrFaJw2wbb9LfqTru+QeAjVGlcUx2ZmQ=;
 b=YLdcKzTC+ACwMMpn0xzv2NB3s4QralrrXazg9t1SIQP7uy/w+RRq3Rgl7jmXevXFSEwPUZ2C1
 FVOvjF3XC2FCSohkp+rZmxd4a49eEsMvkPBYCx6aiO52KTdDgokTXhG
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Simple helper for setting the buffer direction when it's allocated using
iio_dmaengine_buffer_alloc().

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-buffer.c | 7 +++++++
 include/linux/iio/buffer.h        | 3 +++
 2 files changed, 10 insertions(+)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index 1d950a3e153b..4b1ca6ad86ee 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -1956,6 +1956,13 @@ void iio_buffer_put(struct iio_buffer *buffer)
 }
 EXPORT_SYMBOL_GPL(iio_buffer_put);
 
+void iio_buffer_set_dir(struct iio_buffer *buffer,
+			enum iio_buffer_direction dir)
+{
+	buffer->direction = dir;
+}
+EXPORT_SYMBOL_GPL(iio_buffer_set_dir);
+
 /**
  * iio_device_attach_buffer - Attach a buffer to a IIO device
  * @indio_dev: The device the buffer should be attached to
diff --git a/include/linux/iio/buffer.h b/include/linux/iio/buffer.h
index 418b1307d3f2..7e70bb5adc01 100644
--- a/include/linux/iio/buffer.h
+++ b/include/linux/iio/buffer.h
@@ -55,4 +55,7 @@ bool iio_validate_scan_mask_onehot(struct iio_dev *indio_dev,
 int iio_device_attach_buffer(struct iio_dev *indio_dev,
 			     struct iio_buffer *buffer);
 
+void iio_buffer_set_dir(struct iio_buffer *buffer,
+			enum iio_buffer_direction dir);
+
 #endif /* _IIO_BUFFER_GENERIC_H_ */

-- 
2.44.0

