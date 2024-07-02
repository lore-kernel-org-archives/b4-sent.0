From: Nuno Sa <nuno.sa@analog.com>
Date: Tue, 02 Jul 2024 18:02:33 +0200
Subject: [PATCH 01/20] iio: core: add accessors 'masklength'
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240702-dev-iio-masklength-private-v1-1-98193bf536a6@analog.com>
References: <20240702-dev-iio-masklength-private-v1-0-98193bf536a6@analog.com>
In-Reply-To: <20240702-dev-iio-masklength-private-v1-0-98193bf536a6@analog.com>
To: linux-iio@vger.kernel.org, chrome-platform@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, 
 Cosmin Tanislav <cosmin.tanislav@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 Dmitry Rokosov <ddrokosov@sberdevices.ru>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719936156; l=1677;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=EA7SSU5JCACZ9RbuyelW015qMw9c7NJ9Gp/LUGrm0oI=;
 b=WOeC8On1W5DCuG3LfamYH01OA5F0KKWMc0DWI3AWAeSbOQx46FElbbhV4CKkRfZy3+gYMQqWC
 lf31gWkzbbECs1Z5B21bh3N363YaVGrn7aRYnhS2HeqXObSmuYw+cFY
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

'masklength' is supposed to be an IIO private member. However, drivers
(often in trigger handlers) need to access it to iterate over the
enabled channels for example (there are other reasons). Hence, a couple
of new accessors are being added:

 * iio_for_each_active_channel() - Iterates over the active channels;
 * iio_get_masklength() - Get length of the channels mask.

The goal of these new accessors is to annotate 'masklength' as private
as soon as all drivers accessing it are converted to use the new
helpers.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 include/linux/iio/iio.h | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/include/linux/iio/iio.h b/include/linux/iio/iio.h
index 894309294182d..dd6bbc468283e 100644
--- a/include/linux/iio/iio.h
+++ b/include/linux/iio/iio.h
@@ -855,6 +855,24 @@ static inline const struct iio_scan_type
 	return &chan->scan_type;
 }
 
+/**
+ * iio_get_masklength - Get length of the channels mask
+ * @indio_dev: the IIO device to get the masklength for
+ */
+static inline unsigned int iio_get_masklength(const struct iio_dev *indio_dev)
+{
+	return indio_dev->masklength;
+}
+
+/**
+ * iio_for_each_active_channel - Iterated over active channels
+ * @indio_dev: the IIO device
+ * @chan: Holds the index of the enabled channel
+ */
+#define iio_for_each_active_channel(indio_dev, chan) \
+	for_each_set_bit((chan), (indio_dev)->active_scan_mask, \
+			 iio_get_masklength(indio_dev))
+
 ssize_t iio_format_value(char *buf, unsigned int type, int size, int *vals);
 
 int iio_str_to_fixpoint(const char *str, int fract_mult, int *integer,

-- 
2.45.2

