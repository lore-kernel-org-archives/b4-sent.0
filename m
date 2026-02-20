From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Feb 2026 16:46:08 +0000
Subject: [PATCH RFC 4/8] iio: frequency: ad9910: expose sysclk_frequency
 device attribute
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ad9910-iio-driver-v1-4-3b264aa48a10@analog.com>
References: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
In-Reply-To: <20260220-ad9910-iio-driver-v1-0-3b264aa48a10@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Philipp Zabel <p.zabel@pengutronix.de>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771605986; l=1404;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=3u3vH6CTF1USbub44V9JoeQJxCYLlIqHrcKGASf1v1Q=;
 b=iDOfa8mp9mZIXa7ZbDGNGhBxsqzthOCKwINnqC2zBsNzPIZC3z6beNB+jIXWPztWvytHIs1Xv
 XfETCKlfGOpCj0+8LIseeJprlX6OthL1X29aWuUOrdtBTwq1to8FSoC
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add read-only sysclk_frequency sysfs attribute. This value is important
for userspace to calculate values to populate the Parallel Port or the
RAM data buffer.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index bb280972e84c..a72e3685f676 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -789,10 +789,31 @@ static int ad9910_reg_access(struct iio_dev *indio_dev,
 	return ret;
 }
 
+static ssize_t sysclk_frequency_show(struct device *dev,
+				     struct device_attribute *attr,
+				     char *buf)
+{
+	struct ad9910_state *st = iio_priv(dev_to_iio_dev(dev));
+
+	return sysfs_emit(buf, "%u\n", st->data.sysclk_freq_hz);
+}
+
+static IIO_DEVICE_ATTR_RO(sysclk_frequency, 0);
+
+static struct attribute *ad9910_attrs[] = {
+	&iio_dev_attr_sysclk_frequency.dev_attr.attr,
+	NULL
+};
+
+static const struct attribute_group ad9910_attrs_group = {
+	.attrs = ad9910_attrs,
+};
+
 static const struct iio_info ad9910_info = {
 	.read_raw = ad9910_read_raw,
 	.write_raw = ad9910_write_raw,
 	.write_raw_get_fmt = ad9910_write_raw_get_fmt,
+	.attrs = &ad9910_attrs_group,
 	.debugfs_reg_access = &ad9910_reg_access,
 };
 

-- 
2.43.0

