From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:22:57 +0200
Subject: [PATCH 05/23] iio: adc: mt6360-adc: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-5-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982177; l=948;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=taLxe9Vc9oQlWigvEjOpJItzkkFm/mOSh+oraOTypJU=;
 b=extdcZH9h4D5owPJaeCrVkF5FRVuEYGg6WbJK9beg7bryIg+ygmXm/j2ykUISALFdDeQnTfaa
 IsedS9SScB/B2t79pK0aTzgi1Ux1+hLmhPK15J4yRJbpOIbfgW9ZJrc
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/mt6360-adc.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/adc/mt6360-adc.c b/drivers/iio/adc/mt6360-adc.c
index 3710473e526fc..f74347663ad80 100644
--- a/drivers/iio/adc/mt6360-adc.c
+++ b/drivers/iio/adc/mt6360-adc.c
@@ -268,7 +268,7 @@ static irqreturn_t mt6360_adc_trigger_handler(int irq, void *p)
 	int i = 0, bit, val, ret;
 
 	memset(&data, 0, sizeof(data));
-	for_each_set_bit(bit, indio_dev->active_scan_mask, indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, bit) {
 		ret = mt6360_adc_read_channel(mad, bit, &val);
 		if (ret < 0) {
 			dev_warn(&indio_dev->dev, "Failed to get channel %d conversion val\n", bit);

-- 
2.45.2

