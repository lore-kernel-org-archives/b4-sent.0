From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 01 Apr 2024 18:32:21 +0300
Subject: [PATCH 3/6] iio: adc: ad7173: refactor channel configuration
 parsing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240401-ad4111-v1-3-34618a9cc502@analog.com>
References: <20240401-ad4111-v1-0-34618a9cc502@analog.com>
In-Reply-To: <20240401-ad4111-v1-0-34618a9cc502@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711985550; l=2160;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=LP925hA7l/Zq+jxivGEGAOgI2hBOHLlP0ftz5riKxwA=;
 b=/RbMwmYnyhC5pKQaInX3g8tTV5ka0OyCWhWopLnpDFY3wgL+e2loPLkV1ldaDbSKtknDIKhsB
 /+X38d8OzhKC/vKCrDsGYSh0zjHicqefIm2+JfwdgrZGF5a+ELQ9yVs
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move configurations regarding number of channels from
*_fw_parse_device_config to *_fw_parse_channel_config.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 drivers/iio/adc/ad7173.c | 29 +++++++++++++++++------------
 1 file changed, 17 insertions(+), 12 deletions(-)

diff --git a/drivers/iio/adc/ad7173.c b/drivers/iio/adc/ad7173.c
index 8a95b1391826..699bc6970790 100644
--- a/drivers/iio/adc/ad7173.c
+++ b/drivers/iio/adc/ad7173.c
@@ -917,7 +917,23 @@ static int ad7173_fw_parse_channel_config(struct iio_dev *indio_dev)
 	struct device *dev = indio_dev->dev.parent;
 	struct iio_chan_spec *chan_arr, *chan;
 	unsigned int ain[2], chan_index = 0;
-	int ref_sel, ret;
+	int ref_sel, ret, num_channels;
+
+	num_channels = device_get_child_node_count(dev);
+
+	if (st->info->has_temp)
+		num_channels++;
+
+	if (num_channels == 0)
+		return dev_err_probe(dev, -ENODATA, "No channels specified\n");
+
+	if (num_channels > st->info->num_channels)
+		return dev_err_probe(dev, -EINVAL,
+			"Too many channels specified. Maximum is %d, not including temperature channel if supported.\n",
+			st->info->num_channels);
+
+	indio_dev->num_channels = num_channels;
+	st->num_channels = num_channels;
 
 	chan_arr = devm_kcalloc(dev, sizeof(*indio_dev->channels),
 				st->num_channels, GFP_KERNEL);
@@ -1012,7 +1028,6 @@ static int ad7173_fw_parse_device_config(struct iio_dev *indio_dev)
 {
 	struct ad7173_state *st = iio_priv(indio_dev);
 	struct device *dev = indio_dev->dev.parent;
-	unsigned int num_channels;
 	int ret;
 
 	st->regulators[0].supply = ad7173_ref_sel_str[AD7173_SETUP_REF_SEL_EXT_REF];
@@ -1071,16 +1086,6 @@ static int ad7173_fw_parse_device_config(struct iio_dev *indio_dev)
 
 	ad7173_sigma_delta_info.irq_line = ret;
 
-	num_channels = device_get_child_node_count(dev);
-
-	if (st->info->has_temp)
-		num_channels++;
-
-	if (num_channels == 0)
-		return dev_err_probe(dev, -ENODATA, "No channels specified\n");
-	indio_dev->num_channels = num_channels;
-	st->num_channels = num_channels;
-
 	return ad7173_fw_parse_channel_config(indio_dev);
 }
 

-- 
2.43.0

