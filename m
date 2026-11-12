From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:54:59 +0000
Subject: [PATCH v2 5/6] media: verisilicon: Reject AV1 frames without tiles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-codec-fixes-v2-5-f44424df585b@gmail.com>
References: <20261112-hantro-codec-fixes-v2-0-f44424df585b@gmail.com>
In-Reply-To: <20261112-hantro-codec-fixes-v2-0-f44424df585b@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Sebastian Fricke <sebastian.fricke@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Boris Brezillon <boris.brezillon@collabora.com>, 
 Jonas Karlman <jonas@kwiboo.se>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Jeffy Chen <jeffy.chen@rock-chips.com>, Tomasz Figa <tfiga@chromium.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794473695; l=1803;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=w0RsTz4T3CdOdGdBS9xKk8Iq1upmKZ/s7yYs4Iwwoq4=;
 b=1jIzt0YpSLyNUN1i3u8sdgp/pwRCteGQqy10eDWnlsJ1plRYZEtzBS5wV1vYcztYvLdYwST2j
 YQ95e/YnnimD6li5/hGlc7vLZxUI7uJdnpN1//BScgKO9mR+lG0n3qq
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AV1 control validation only checks the upper bounds of tile_cols
and tile_rows, and rockchip_vpu981_av1_dec_prepare_run() only checks the
number of tiles against the tile group entries and the tile buffer, so
a frame with tile_cols or tile_rows set to 0 is accepted. With no tile
columns, rockchip_vpu981_av1_dec_tiles_reallocate() computes a size of
0 for each of the five tile column buffers, which the buffers it has
always satisfy, so it allocates nothing. On the first frame of a context
the decoder is then started without tile column buffers (DMA address 0),
and after a failed allocation with the addresses of the freed ones.

Every AV1 frame has at least one tile, reject frames without any.

Fixes: 65e9f52ffdc8 ("media: verisilicon: Fix auxiliary buffer allocation size")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
index e817c91224d3..8154b405ca63 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
@@ -526,6 +526,13 @@ static int rockchip_vpu981_av1_dec_prepare_run(struct hantro_ctx *ctx)
 	if (num_tiles > tge->elems || num_tiles > AV1_MAX_TILES)
 		return -EINVAL;
 
+	/*
+	 * Every AV1 frame has at least one tile. Without tile columns, the
+	 * tile column buffers would be sized to zero and not allocated.
+	 */
+	if (!num_tiles)
+		return -EINVAL;
+
 	ctrls->film_grain =
 	    hantro_get_ctrl(ctx, V4L2_CID_STATELESS_AV1_FILM_GRAIN);
 

-- 
2.55.0

