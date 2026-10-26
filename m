From: Andrea Amer <and.amer@gmail.com>
Date: Mon, 26 Oct 2026 11:57:38 +0100
Subject: [PATCH v3] iio: afe: rescale: expose offset if rescaler or source
 has one
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-iio-rescale-offset-v3-1-7cf6540111dc@gmail.com>
X-B4-Tracking: v=1; b=H4sIACEy32oC/33NwQ6CMAyA4VchOzvDOhjOk+9hPMzRQRNgZiOLh
 vDuDk4cjOnpb9KvC4sYCCO7FgsLmCiSn3LIU8Fsb6YOObW5GZSgRCmAE3keMFozIPfORZx5JaC
 ujJRP1SqWD18BHb139P7I3VOcffjsP5LYtn+5JHieCltR60Y7B7duNDScrR/ZxiU4EuonAZkow
 V6g1qoRUh+JdV2/kbOZ/PcAAAA=
X-Change-ID: 20261012-iio-rescale-offset-41254a33b6d6
To: Peter Rosin <peda@lysator.liu.se>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Cameron <jic23@kernel.org>, Andrea Amer <and.amer@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793012260; l=1684;
 i=and.amer@gmail.com; s=20261012; h=from:subject:message-id;
 bh=7+5E3nPFEdzUpCLuOKaAoA53dGKvrkfb4WX9YIOvEws=;
 b=VDVUdoBQYQZjXbvlRrnjs9xQP1nPAFe0JmJx9Tt2pyo1JnTRYUYHBNNdwsLcBoThKUmDJOkI+
 LeUx+i9zr0pBbYdo5hBBJ0UiHzzisYggm3mVKvnJ68WPXD1vwwYeTyl
X-Developer-Key: i=and.amer@gmail.com; a=ed25519;
 pk=TiMK202FvcPM+yKGkAI4hsAZA7QkwyEgru97PAFa4pg=
X-Endpoint-Received: by B4 Relay for and.amer@gmail.com/20261012 with auth_id=1165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A rescale channel advertises IIO_CHAN_INFO_OFFSET only when its own
offset is non-zero. A child rescale therefore hides a source offset,
and consumers apply raw * scale and drop it, even though
rescale_read_raw() folds the source offset in.

Expose the attribute when either the rescaler or the source channel
provides an offset.

Fixes: a29c3283653b ("iio: afe: rescale: add offset support")
Signed-off-by: Andrea Amer <and.amer@gmail.com>
---
Changes in v3:
- Only expose offset if the rescaler or the source has one (Jonathan Cameron)
- Link to v2: https://lore.kernel.org/r/20261016-iio-rescale-offset-v2-1-02c825967139@gmail.com

Changes in v2:
- Keep the IIO_CHAN_INFO_SCALE line unchanged (Andy Shevchenko)
- Link to v1: https://lore.kernel.org/r/20261012-iio-rescale-offset-v1-1-14ed15979ff2@gmail.com
---
 drivers/iio/afe/iio-rescale.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/iio/afe/iio-rescale.c b/drivers/iio/afe/iio-rescale.c
index 3a6a09ffa5267ddfd5131fbd04a5df928836589d..c01292a15a29d02afa8de80a778c2c2a2aeecd3f 100644
--- a/drivers/iio/afe/iio-rescale.c
+++ b/drivers/iio/afe/iio-rescale.c
@@ -303,7 +303,8 @@ static int rescale_configure_channel(struct device *dev,
 	chan->info_mask_separate = BIT(IIO_CHAN_INFO_RAW) |
 		BIT(IIO_CHAN_INFO_SCALE);
 
-	if (rescale->offset)
+	if (rescale->offset ||
+	    iio_channel_has_info(schan, IIO_CHAN_INFO_OFFSET))
 		chan->info_mask_separate |= BIT(IIO_CHAN_INFO_OFFSET);
 
 	/*

---
base-commit: a3b3580713f3ac5a32dc2874ee546828977a1d68
change-id: 20261012-iio-rescale-offset-41254a33b6d6

Best regards,
-- 
Andrea Amer <and.amer@gmail.com>

