From: Nuno Sa <nuno.sa@analog.com>
Date: Fri, 26 Jul 2024 10:23:15 +0200
Subject: [PATCH 23/23] iio: core: annotate masklength as __private
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240726-dev-iio-masklength-private3-v1-23-82913fc0fb87@analog.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721982178; l=1709;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=j64bS8AlbPEaXDKOf/24fcP0//ABTNMV+H57fOfioL0=;
 b=SqZqmPuN3DkvmQIpd3N42mKg1nerY7jzP7iAtnBI7wcyiGwg8NfCTvLb+HIxSYWS2uqA7Xsk+
 GnOcDRGd0Y7DoHUHxvqRqJiMfulWw0FRfgtpb+Y10pKwol9SoVNnfI1
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that all users are using the proper accessors, we can mark
masklength as __private so that no one tries to write. We also get help
from checkers in warning us in case someone does it.

To access the private field from IIO core code, we need to use the
ACCESS_PRIVATE() macro.

Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 drivers/iio/industrialio-buffer.c | 2 +-
 include/linux/iio/iio.h           | 4 ++--
 2 files changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/iio/industrialio-buffer.c b/drivers/iio/industrialio-buffer.c
index 3d0b1d25fdd7..8104696cd475 100644
--- a/drivers/iio/industrialio-buffer.c
+++ b/drivers/iio/industrialio-buffer.c
@@ -2269,7 +2269,7 @@ int iio_buffers_alloc_sysfs_and_mask(struct iio_dev *indio_dev)
 
 		for (i = 0; i < indio_dev->num_channels; i++)
 			ml = max(ml, channels[i].scan_index + 1);
-		indio_dev->masklength = ml;
+		ACCESS_PRIVATE(indio_dev, masklength) = ml;
 	}
 
 	if (!iio_dev_opaque->attached_buffers_cnt)
diff --git a/include/linux/iio/iio.h b/include/linux/iio/iio.h
index dd6bbc468283..f6c0499853bb 100644
--- a/include/linux/iio/iio.h
+++ b/include/linux/iio/iio.h
@@ -609,7 +609,7 @@ struct iio_dev {
 	int				scan_bytes;
 
 	const unsigned long		*available_scan_masks;
-	unsigned			masklength;
+	unsigned			__private masklength;
 	const unsigned long		*active_scan_mask;
 	bool				scan_timestamp;
 	struct iio_trigger		*trig;
@@ -861,7 +861,7 @@ static inline const struct iio_scan_type
  */
 static inline unsigned int iio_get_masklength(const struct iio_dev *indio_dev)
 {
-	return indio_dev->masklength;
+	return ACCESS_PRIVATE(indio_dev, masklength);
 }
 
 /**

-- 
2.45.2

