From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Fri, 20 Feb 2026 16:46:12 +0000
Subject: [PATCH RFC 8/8] iio: frequency: ad9910: add channel labels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260220-ad9910-iio-driver-v1-8-3b264aa48a10@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771605986; l=1464;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=XVRMytzjE0Xjg264u9puMX+fiQxZ2hkudN/VqdIWRLk=;
 b=5SaIsbhoNyh6zvARQPcFhGGl1gTCcLezdZHcHhu0tnqnvxY6Rl6ozdCQ2urKHFjRFx6uWdemu
 mCfxMLVBs8tAgqn63Km3Kna/REqHbpQRL+6EuIKW9WGWJAg+1J8Irlq
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add human-readable labels for all AD9910 IIO channels via the read_label
callback: single_tone, parallel_port, digital_ramp_generator, ram_control,
and output_shift_keying.

Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 drivers/iio/frequency/ad9910.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/iio/frequency/ad9910.c b/drivers/iio/frequency/ad9910.c
index b1540b157a0e..e983614805b4 100644
--- a/drivers/iio/frequency/ad9910.c
+++ b/drivers/iio/frequency/ad9910.c
@@ -1814,10 +1814,26 @@ static const struct attribute_group ad9910_attrs_group = {
 	.bin_attrs = ad9910_bin_attrs,
 };
 
+static const char * const ad9910_channel_str[] = {
+	[AD9910_CHANNEL_SINGLE_TONE] = "single_tone",
+	[AD9910_CHANNEL_PARALLEL_PORT] = "parallel_port",
+	[AD9910_CHANNEL_DRG] = "digital_ramp_generator",
+	[AD9910_CHANNEL_RAM] = "ram_control",
+	[AD9910_CHANNEL_OSK] = "output_shift_keying",
+};
+
+static int ad9910_read_label(struct iio_dev *indio_dev,
+			     struct iio_chan_spec const *chan,
+			     char *label)
+{
+	return sprintf(label, "%s\n", ad9910_channel_str[chan->channel]);
+}
+
 static const struct iio_info ad9910_info = {
 	.read_raw = ad9910_read_raw,
 	.write_raw = ad9910_write_raw,
 	.write_raw_get_fmt = ad9910_write_raw_get_fmt,
+	.read_label = ad9910_read_label,
 	.attrs = &ad9910_attrs_group,
 	.debugfs_reg_access = &ad9910_reg_access,
 };

-- 
2.43.0

