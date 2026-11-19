From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 19 Nov 2026 04:40:08 +0000
Subject: [PATCH v2 2/2] media: verisilicon: av1: Read the segmentation map
 at the reference's offset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-b4-vpu981-av1-refs-v2-2-7c270158b20e@gmail.com>
References: <20261119-b4-vpu981-av1-refs-v2-0-7c270158b20e@gmail.com>
In-Reply-To: <20261119-b4-vpu981-av1-refs-v2-0-7c270158b20e@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 stable@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795063206; l=2044;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=M5VkkkdflunTVyGr1Nz/gUu/uiqdpj4/jtKjFiX6La8=;
 b=PfK2nx60qvDot3pPQb8sNiCu7mL5/ewrHcGUlIufCanfGvZ8XhvDNrx0yefrmEzuRKSNZUrUH
 Ixd6+x30474A9F/JgkuxopzmZSIhV5QmLK6it7TPuRYw7xa3sJjGH/q
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The segmentation map of the primary reference is read at the motion
vector offset of the current CAPTURE format. After a switch to a larger
format, that is past the end of a reference held in a smaller buffer.

Use the reference's own offset, and skip the map of a reference of
another size (the spec then uses segment 0, load_previous_segment_ids()
in section 6.8.2).

Fixes: 727a400686a2 ("media: verisilicon: Add Rockchip AV1 decoder")
Cc: stable@vger.kernel.org
Reviewed-by: Benjamin Gaignard <benjamin.gaignard@collabora.com>
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c | 8 +++++---
 1 file changed, 5 insertions(+), 3 deletions(-)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
index b331ff234878..21a97a57328a 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu981_hw_av1_dec.c
@@ -910,13 +910,15 @@ static void rockchip_vpu981_av1_dec_set_segmentation(struct hantro_ctx *ctx)
 	    frame->primary_ref_frame < V4L2_AV1_REFS_PER_FRAME) {
 		int idx = rockchip_vpu981_get_frame_index(ctx, frame->primary_ref_frame);
 		struct hantro_decoded_buffer *ref = rockchip_vpu981_av1_dec_ref_buf(ctx, idx);
+		int mi_cols = DIV_ROUND_UP(frame->frame_width_minus_1 + 1, 8);
+		int mi_rows = DIV_ROUND_UP(frame->frame_height_minus_1 + 1, 8);
 
-		if (ref) {
+		if (ref && av1_dec->frame_refs[idx].mi_cols == mi_cols &&
+		    av1_dec->frame_refs[idx].mi_rows == mi_rows) {
 			dma_addr_t luma_addr, mv_addr = 0;
-			size_t mv_offset = rockchip_vpu981_av1_dec_chroma_size(ctx);
 
 			luma_addr = hantro_get_dec_buf_addr(ctx, &ref->base.vb.vb2_buf);
-			mv_addr = luma_addr + mv_offset;
+			mv_addr = luma_addr + ref->av1.mv_offset;
 
 			hantro_write_addr(vpu, AV1_SEGMENTATION, mv_addr);
 			hantro_reg_write(vpu, &av1_use_temporal3_mvs, 1);

-- 
2.55.0

