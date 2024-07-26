From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:00 +0200
Subject: [PATCH 08/23] iio: adc: stm32-adc: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-8-82913fc0fb87@analog.com>
References: <20240726-dev-iio-masklength-private3-v1-0-82913fc0fb87@analog.com>
In-Reply-To: <20240726-dev-iio-masklength-private3-v1-0-82913fc0fb87@analog.com>
To: linux-iio@vger.kernel.org, linux-staging@lists.linux.dev
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Ramona Gradinariu <ramona.gradinariu@analog.com>, 
 Antoniu Miclaus <antoniu.miclaus@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Marcus Folkesson <marcus.folkesson@gmail.com>, 
 Kent Gustavsson <kent@minoris.se>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Heiko Stuebner <heiko@sntech.de>, 
 Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Francesco Dolcini <francesco@dolcini.it>, 
 =?utf-8?q?Jo=C3=A3o_Paulo_Gon=C3=A7alves?= <jpaulo.silvagoncalves@gmail.com>, 
 Haibo Chen <haibo.chen@nxp.com>, Michal Simek <michal.simek@amd.com>, 
 Benson Leung <bleung@chromium.org>, Guenter Roeck <groeck@chromium.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982177; l=1283;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HE1VRfKigITTw2AxPcLnqYl/S+jcBrR+clI++DNvuZY=;
 b=9eZZNY65VYVI3/oJnoG7KIr0BFD5g/ISCZ/fLKLzQaQJqqaSP9foay89jKBytQDgUTA3QmIcJ
 3R8FxHZNySCAfVlpHSCHjNUtqxxlKO42/2PQuPodX4RejQRdzIKMq6v
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/stm32-adc.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/stm32-adc.c b/drivers/iio/adc/stm32-adc.c
index 375aa7720f80..c901ba1bc6ba 100644
--- a/drivers/iio/adc/stm32-adc.c
+++ b/drivers/iio/adc/stm32-adc.c
@@ -1261,7 +1261,7 @@ static int stm32_adc_conf_scan_seq(struct iio_dev *indio_dev,
 	stm32_adc_writel(adc, adc->cfg->regs->smpr[0], adc->smpr_val[0]);
 	stm32_adc_writel(adc, adc->cfg->regs->smpr[1], adc->smpr_val[1]);
 
-	for_each_set_bit(bit, scan_mask, indio_dev->masklength) {
+	for_each_set_bit(bit, scan_mask, iio_get_masklength(indio_dev)) {
 		chan = indio_dev->channels + bit;
 		/*
 		 * Assign one channel per SQ entry in regular
@@ -1619,7 +1619,7 @@ static int stm32_adc_update_scan_mode(struct iio_dev *indio_dev,
 	if (ret < 0)
 		return ret;
 
-	adc->num_conv = bitmap_weight(scan_mask, indio_dev->masklength);
+	adc->num_conv = bitmap_weight(scan_mask, iio_get_masklength(indio_dev));
 
 	ret = stm32_adc_conf_scan_seq(indio_dev, scan_mask);
 	pm_runtime_mark_last_busy(dev);

-- 
2.45.2

