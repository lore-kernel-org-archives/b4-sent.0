From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:12 +0200
Subject: [PATCH 20/23] iio: adc: xilinx-xadc-core: use new '.masklength'
 accessors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-20-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982178; l=1223;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=scLE0UCeIsTTRIkD5FhFjjiMruTUs4kHDToEaMN+2fA=;
 b=fPUYTrXv9f+DbYcT3DuLtq1kkiqy0vvvUX2/HLQS7pe71YnjlgXn/aXKkrDQj0QtC4Y1KNlrc
 JJBBK+55QndChONkflxjKr/JbhgcUSRJIzOJYlFQT6YpbaelHO2Qo5X
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of iio_get_masklength) and iio_for_each_active_channel() to
access '.masklength' so it can be annotated as __private when there
are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/xilinx-xadc-core.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/adc/xilinx-xadc-core.c b/drivers/iio/adc/xilinx-xadc-core.c
index 564c0cad0fc79..cfbfcaefec0fc 100644
--- a/drivers/iio/adc/xilinx-xadc-core.c
+++ b/drivers/iio/adc/xilinx-xadc-core.c
@@ -628,7 +628,7 @@ static int xadc_update_scan_mode(struct iio_dev *indio_dev,
 	size_t n;
 	void *data;
 
-	n = bitmap_weight(mask, indio_dev->masklength);
+	n = bitmap_weight(mask, iio_get_masklength(indio_dev));
 
 	data = devm_krealloc_array(indio_dev->dev.parent, xadc->data,
 				   n, sizeof(*xadc->data), GFP_KERNEL);
@@ -681,8 +681,7 @@ static irqreturn_t xadc_trigger_handler(int irq, void *p)
 		goto out;
 
 	j = 0;
-	for_each_set_bit(i, indio_dev->active_scan_mask,
-		indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		chan = xadc_scan_index_to_channel(i);
 		xadc_read_adc_reg(xadc, chan, &xadc->data[j]);
 		j++;

-- 
2.45.2

