From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 27 Nov 2023 16:55:35 +0100
Subject: [PATCH 2/2] iio: dac: ad5791: Add support for controlling RBUF via
 devicetree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231127-ad5791-michael-stuff-v1-2-04167b3edc56@analog.com>
References: <20231127-ad5791-michael-stuff-v1-0-04167b3edc56@analog.com>
In-Reply-To: <20231127-ad5791-michael-stuff-v1-0-04167b3edc56@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Hennerich <michael.hennerich@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701100539; l=1575;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=V60ayX58Xp4oAs8NlC1uKeQ7LGPvuaHa+/Zm9B0Kn5A=;
 b=+lvFhDi3dz4Zjoy+gfF6jAx15RVdJzTmTyoGM4/y+g47gGI4uQXyrrSVhfUD63LCuoXgeevMI
 Peh1v1bDO7WCOtxCMMJgMDLviDkccef5D+7VQcpinEe2h62xBE1hTSf
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

This patch adds support for an external amplifier to be connected in a
gain of two configuration.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/dac/ad5791.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/dac/ad5791.c b/drivers/iio/dac/ad5791.c
index a4167454da81..75b549827e15 100644
--- a/drivers/iio/dac/ad5791.c
+++ b/drivers/iio/dac/ad5791.c
@@ -345,6 +345,7 @@ static int ad5791_probe(struct spi_device *spi)
 	struct iio_dev *indio_dev;
 	struct ad5791_state *st;
 	int ret, pos_voltage_uv = 0, neg_voltage_uv = 0;
+	bool use_rbuf_gain2;
 
 	indio_dev = devm_iio_device_alloc(&spi->dev, sizeof(*st));
 	if (!indio_dev)
@@ -379,6 +380,12 @@ static int ad5791_probe(struct spi_device *spi)
 	st->pwr_down = true;
 	st->spi = spi;
 
+	if (pdata)
+		use_rbuf_gain2 = pdata->use_rbuf_gain2;
+	else
+		use_rbuf_gain2 = device_property_read_bool(&spi->dev,
+							   "adi,rbuf-gain2-en");
+
 	if (!IS_ERR(st->reg_vss) && !IS_ERR(st->reg_vdd)) {
 		st->vref_mv = (pos_voltage_uv + neg_voltage_uv) / 1000;
 		st->vref_neg_mv = neg_voltage_uv / 1000;
@@ -398,7 +405,7 @@ static int ad5791_probe(struct spi_device *spi)
 
 
 	st->ctrl = AD5761_CTRL_LINCOMP(st->chip_info->get_lin_comp(st->vref_mv))
-		  | ((pdata && pdata->use_rbuf_gain2) ? 0 : AD5791_CTRL_RBUF) |
+		  | (use_rbuf_gain2 ? 0 : AD5791_CTRL_RBUF) |
 		  AD5791_CTRL_BIN2SC;
 
 	ret = ad5791_spi_write(st, AD5791_ADDR_CTRL, st->ctrl |

-- 
2.43.0

