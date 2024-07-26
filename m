From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:22:53 +0200
Subject: [PATCH 01/23] iio: accel: adxl380: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-1-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982177; l=837;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=4H4gd1mTf71nKs//tKbiKvw51/pe/swi+OU/DwsYlO8=;
 b=UhNwEc2LqguPS+kPVUDA3jFFCWJYp2ygQzUmLt4TUoc4j/3SCy796NjQe2DVNWwATHkADS92n
 /ts7cNrtSGSDG6wZF7Jo7VJ+3xKUGw5HwS5ljjFkj5TFmWOq+0aNNl8
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/accel/adxl380.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/iio/accel/adxl380.c b/drivers/iio/accel/adxl380.c
index 41b01792161c..98863e22bb6b 100644
--- a/drivers/iio/accel/adxl380.c
+++ b/drivers/iio/accel/adxl380.c
@@ -1110,7 +1110,7 @@ static int adxl380_buffer_postenable(struct iio_dev *indio_dev)
 	}
 
 	st->fifo_set_size = bitmap_weight(indio_dev->active_scan_mask,
-					  indio_dev->masklength);
+					  iio_get_masklength(indio_dev));
 
 	if ((st->watermark * st->fifo_set_size) > ADXL380_FIFO_SAMPLES)
 		st->watermark = (ADXL380_FIFO_SAMPLES  / st->fifo_set_size);

-- 
2.45.2

