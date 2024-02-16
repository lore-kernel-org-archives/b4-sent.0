From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 16 Feb 2024 15:10:50 +0100
Subject: [PATCH RFC 1/8] iio: buffer: add function to set the buffer
 direction
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-iio-backend-axi-dds-v1-1-22aed9fb07a1@analog.com>
References: <20240216-iio-backend-axi-dds-v1-0-22aed9fb07a1@analog.com>
In-Reply-To: <20240216-iio-backend-axi-dds-v1-0-22aed9fb07a1@analog.com>
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708092664; l=1611;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=d5nwu7cwhkLNuXvBJXa201xpcbfgCUn83k0KuJDTwTA=;
 b=dH8M5t6AQdheCgW+ZjeT64oYXmXSOk26zy2dis9MriSL43KUs8exshkx4Hv8SqTJj5GKS9q1R
 TD6ZvxI9EdEAj53s/1coK2NEEg7opqVp+VcbghvzeUauHMSOk7OxsO9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an helper function to set the direction. This is preliminary change
and will be useful for IIO backends that provide output buffers.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-buffer.c | 12 ++++++++++++
 include/linux/iio/buffer.h        |  3 +++
 2 files changed, 15 insertions(+)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index b581a7e80566..504e5a96bd90 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -1982,6 +1982,18 @@ void iio_buffer_put(struct iio_buffer *buffer)
 }
 EXPORT_SYMBOL_GPL(iio_buffer_put);
 
+/**
+ * iio_buffer_set_dir() - Set the buffer direction
+ * @buffer: The buffer to set the direction
+ * @direction: The direction
+ */
+void iio_buffer_set_dir(struct iio_buffer *buffer,
+			enum iio_buffer_direction direction)
+{
+	buffer->direction = direction;
+}
+EXPORT_SYMBOL(iio_buffer_set_dir);
+
 /**
  * iio_device_attach_buffer - Attach a buffer to a IIO device
  * @indio_dev: The device the buffer should be attached to
diff --git a/include/linux/iio/buffer.h b/include/linux/iio/buffer.h
index 418b1307d3f2..aee52b834443 100644
--- a/include/linux/iio/buffer.h
+++ b/include/linux/iio/buffer.h
@@ -55,4 +55,7 @@ bool iio_validate_scan_mask_onehot(struct iio_dev *indio_dev,
 int iio_device_attach_buffer(struct iio_dev *indio_dev,
 			     struct iio_buffer *buffer);
 
+void iio_buffer_set_dir(struct iio_buffer *buffer,
+			enum iio_buffer_direction direction);
+
 #endif /* _IIO_BUFFER_GENERIC_H_ */

-- 
2.43.0

