From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:10 +0200
Subject: [PATCH 18/23] iio: adc: ti-ads8688: make use of
 iio_for_each_active_channel()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-18-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982178; l=915;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=CXE9n1OTERPreNfjFIenBnsa4hUQh2QY6CgmvZVjglQ=;
 b=2LKulSG61dERd041aYUSUleOkTZyYUSHMCQBWl82M2dCuByYPlBFm7A9NwRxgLfy8l3ZQnOo5
 8+I8g2/S+1/DVXeMdvi9BcrLXIIY1TRZW5Yln/Tm2DfMzISokyqEPyO
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_for_each_active_channel() to iterate over active channels
accessing '.masklength' so it can be annotated as __private when there are
no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ti-ads8688.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/iio/adc/ti-ads8688.c b/drivers/iio/adc/ti-ads8688.c
index 7a79f0cebfbf..94cc823b26f3 100644
--- a/drivers/iio/adc/ti-ads8688.c
+++ b/drivers/iio/adc/ti-ads8688.c
@@ -384,9 +384,7 @@ static irqreturn_t ads8688_trigger_handler(int irq, void *p)
 	u16 buffer[ADS8688_MAX_CHANNELS + sizeof(s64)/sizeof(u16)] __aligned(8);
 	int i, j = 0;
 
-	for (i = 0; i < indio_dev->masklength; i++) {
-		if (!test_bit(i, indio_dev->active_scan_mask))
-			continue;
+	iio_for_each_active_channel(indio_dev, i) {
 		buffer[j] = ads8688_read(indio_dev, i);
 		j++;
 	}

-- 
2.45.2

