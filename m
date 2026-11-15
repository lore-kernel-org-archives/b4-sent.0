From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sun, 15 Nov 2026 08:39:46 +0000
Subject: [PATCH v2 1/4] media: verisilicon: Size the VP8 segment map for
 the largest frame
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-hantro-fixes-v2-1-bfecfb07a3e7@gmail.com>
References: <20261115-hantro-fixes-v2-0-bfecfb07a3e7@gmail.com>
In-Reply-To: <20261115-hantro-fixes-v2-0-bfecfb07a3e7@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794731985; l=1178;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=HL3Blb6OWyDUqsGQviHP7B92VIrg7DTEXdqj8j/7nqU=;
 b=URFopEk5oS38P36Xwr5aN0tmKgXZZJP3hjScqQ7OJNMmx9tPMQBLbZNUh1y3wt6NuOamQ+j0N
 +ANmer4lhJKAinZXiGcHEnq5GMutHJAjFs7HSl2II1X3w3Sm2sHoQy7
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The segment map is sized at STREAMON, but the CAPTURE format can grow
while streaming and overrun it. Size it for the largest frame, as VP9
does.

Fixes: bbd267daf4fc ("media: verisilicon: vp9: Allow to change resolution while streaming")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_vp8.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_vp8.c b/drivers/media/platform/verisilicon/hantro_vp8.c
index 381bc1d3bfda..98ad86269bc3 100644
--- a/drivers/media/platform/verisilicon/hantro_vp8.c
+++ b/drivers/media/platform/verisilicon/hantro_vp8.c
@@ -151,8 +151,8 @@ int hantro_vp8_dec_init(struct hantro_ctx *ctx)
 	int ret;
 
 	/* segment map table size calculation */
-	mb_width = DIV_ROUND_UP(ctx->dst_fmt.width, 16);
-	mb_height = DIV_ROUND_UP(ctx->dst_fmt.height, 16);
+	mb_width = DIV_ROUND_UP(ctx->vpu_src_fmt->frmsize.max_width, 16);
+	mb_height = DIV_ROUND_UP(ctx->vpu_src_fmt->frmsize.max_height, 16);
 	segment_map_size = round_up(DIV_ROUND_UP(mb_width * mb_height, 4), 64);
 
 	/*

-- 
2.55.0

