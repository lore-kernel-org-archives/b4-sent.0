From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:13 +0200
Subject: [PATCH 21/23] iio: common: cros_ec_sensors_core: use new
 '.masklength' accessors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-21-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982178; l=1662;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=S8zIGb8Q4J9OHT5HsG9OinrLXTwNMakjT8op5GXXE1Q=;
 b=NK1YNz2usGK6ZYEbW1KxXqE/y+5B8S9jPIFusiFf8GoS2xQqvs/foDTlHzqAb+wzExuDIJ4Cd
 Jf4LQ7byffkCFvUqaIcW+M4XkU2ITSkc9AVnPhiLqqd9hXJVqAXKYgU
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Make use of iio_get_masklength) and iio_for_each_active_channel() to
access '.masklength' so it can be annotated as __private when there
are no more direct users of it.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c b/drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c
index 6bfe5d6847e75..9fc71a73caa12 100644
--- a/drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c
+++ b/drivers/iio/common/cros_ec_sensors/cros_ec_sensors_core.c
@@ -198,9 +198,7 @@ int cros_ec_sensors_push_data(struct iio_dev *indio_dev,
 		return 0;
 
 	out = (s16 *)st->samples;
-	for_each_set_bit(i,
-			 indio_dev->active_scan_mask,
-			 indio_dev->masklength) {
+	iio_for_each_active_channel(indio_dev, i) {
 		*out = data[i];
 		out++;
 	}
@@ -587,7 +585,7 @@ static int cros_ec_sensors_read_data_unsafe(struct iio_dev *indio_dev,
 	int ret;
 
 	/* Read all sensors enabled in scan_mask. Each value is 2 bytes. */
-	for_each_set_bit(i, &scan_mask, indio_dev->masklength) {
+	for_each_set_bit(i, &scan_mask, iio_get_masklength(indio_dev)) {
 		ret = cros_ec_sensors_cmd_read_u16(ec,
 					     cros_ec_sensors_idx_to_reg(st, i),
 					     data);
@@ -683,7 +681,7 @@ int cros_ec_sensors_read_cmd(struct iio_dev *indio_dev,
 		return ret;
 	}
 
-	for_each_set_bit(i, &scan_mask, indio_dev->masklength) {
+	for_each_set_bit(i, &scan_mask, iio_get_masklength(indio_dev)) {
 		*data = st->resp->data.data[i];
 		data++;
 	}

-- 
2.45.2

