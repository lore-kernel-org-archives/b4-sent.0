From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:05 +0200
Subject: [PATCH 13/23] iio: adc: ti-ads1119: make use of
 iio_get_masklength()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-13-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982178; l=1136;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=HnDbSftd+e0Ucp5FBdQe7pOcKFrEr/hE1TurBJs2zNI=;
 b=3FAN4ZBfLYDF7k1ISI+aJeeV5O6Otw0p/Vs1ESTmIKNRpp/aEygYyDiCwgjT6pOjx3UiXV9oA
 7T7b7WBBP2tDiGj5Ap9GHkFNoRjocoiSYz1mP93QZ1YXMZUqQ+QX19G
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use iio_get_masklength() to access '.masklength' so it can be annotated
as __private when there are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/adc/ti-ads1119.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/iio/adc/ti-ads1119.c b/drivers/iio/adc/ti-ads1119.c
index 630f5d5f9a60..44d9f69c9df3 100644
--- a/drivers/iio/adc/ti-ads1119.c
+++ b/drivers/iio/adc/ti-ads1119.c
@@ -435,7 +435,7 @@ static int ads1119_triggered_buffer_preenable(struct iio_dev *indio_dev)
 	int ret;
 
 	index = find_first_bit(indio_dev->active_scan_mask,
-			       indio_dev->masklength);
+			       iio_get_masklength(indio_dev));
 
 	ret = ads1119_set_conv_mode(st, true);
 	if (ret)
@@ -508,7 +508,7 @@ static irqreturn_t ads1119_trigger_handler(int irq, void *private)
 
 	if (!iio_trigger_using_own(indio_dev)) {
 		index = find_first_bit(indio_dev->active_scan_mask,
-				       indio_dev->masklength);
+				       iio_get_masklength(indio_dev));
 
 		ret = ads1119_poll_data_ready(st, &indio_dev->channels[index]);
 		if (ret) {

-- 
2.45.2

