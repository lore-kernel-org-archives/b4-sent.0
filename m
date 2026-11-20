From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Nov 2026 18:04:01 +0000
Subject: [PATCH RFC 5/5] iio: sysfs: drop core-only fields from struct
 iio_dev_attr
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-iio-core-attr-review-v1-5-05b41f8133c2@analog.com>
References: <20261120-iio-core-attr-review-v1-0-05b41f8133c2@analog.com>
In-Reply-To: <20261120-iio-core-attr-review-v1-0-05b41f8133c2@analog.com>
To: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795197883; l=1385;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=65/z2WflfdlMHb7yQxMB5agemZHd6GgMQWFUiigsa0U=;
 b=r6Nvq+rxeQxCWzAcw8aDRZDugDzbMk8jQDXr5u8T7ss65LXsa1FemLTXqJI3/cUwpjb4aGbuM
 LROuVPUNLjfC3wMD5Fu0cTJ/E19QWTfNox/kh+kMSCdsY1DMGbP2F+S
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The list node, channel spec and buffer pointer of struct iio_dev_attr
are now only used through struct iio_chan_attr and the types extending
it. Remove them, so that attributes declared by drivers through
IIO_DEVICE_ATTR*() and friends no longer carry them.

On 64-bit, without lockdep, this shrinks struct iio_dev_attr from 72 to
40 bytes.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 include/linux/iio/sysfs.h | 9 ---------
 1 file changed, 9 deletions(-)

diff --git a/include/linux/iio/sysfs.h b/include/linux/iio/sysfs.h
index de5bb125815c..1e4122b8c13a 100644
--- a/include/linux/iio/sysfs.h
+++ b/include/linux/iio/sysfs.h
@@ -9,23 +9,14 @@
 #ifndef _INDUSTRIAL_IO_SYSFS_H_
 #define _INDUSTRIAL_IO_SYSFS_H_
 
-struct iio_buffer;
-struct iio_chan_spec;
-
 /**
  * struct iio_dev_attr - iio specific device attribute
  * @dev_attr:	underlying device attribute
  * @address:	associated register address
- * @l:		list head for maintaining list of dynamically created attrs
- * @c:		specification for the underlying channel
- * @buffer:	the IIO buffer to which this attribute belongs to (if any)
  */
 struct iio_dev_attr {
 	struct device_attribute dev_attr;
 	u64 address;
-	struct list_head l;
-	struct iio_chan_spec const *c;
-	struct iio_buffer *buffer;
 };
 
 #define to_iio_dev_attr(_dev_attr)				\

-- 
2.43.0

