From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Sat, 28 Nov 2026 17:35:52 +0000
Subject: [PATCH v2 1/2] media: cedrus: fail buffer allocations that do not
 fit with -ENOMEM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-b4-cedrus-generic-fixes-v2-1-af8472be660b@gmail.com>
References: <20261128-b4-cedrus-generic-fixes-v2-0-af8472be660b@gmail.com>
In-Reply-To: <20261128-b4-cedrus-generic-fixes-v2-0-af8472be660b@gmail.com>
To: Maxime Ripard <mripard@kernel.org>, 
 Paul Kocialkowski <paulk@sys-base.io>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Chen-Yu Tsai <wens@kernel.org>, Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>, Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, linux-staging@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-sunxi@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795887352; l=1307;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=GKc4myzCoKXcSVUjdfaxlMm9I9Iejl8cgwb8m6lxa2g=;
 b=HDrLG0HP1UVKFvL84PbBf2CZVHd6CCYBbjQnJgLfZ84ypLJbzlKz5EjdsiWqzOcKrltiMozKQ
 SDuf+7RxpmADaBjCR6V2quKey31b0BjGgkMsGyWKaAQqLrkkCw/TkJJ
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Behind an IOMMU, vb2-dma-contig builds buffers from GFP_KERNEL pages,
so a buffer pool that does not fit in memory invokes the OOM killer.
CMA allocations fail directly and are not affected.

Set __GFP_RETRY_MAYFAIL on both queues: the request then returns fewer
buffers or -ENOMEM.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/staging/media/sunxi/cedrus/cedrus_video.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/staging/media/sunxi/cedrus/cedrus_video.c b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
index ad4ec3490775..9b2d24e77fdb 100644
--- a/drivers/staging/media/sunxi/cedrus/cedrus_video.c
+++ b/drivers/staging/media/sunxi/cedrus/cedrus_video.c
@@ -602,6 +602,7 @@ int cedrus_queue_init(void *priv, struct vb2_queue *src_vq,
 	src_vq->dev = ctx->dev->dev;
 	src_vq->supports_requests = true;
 	src_vq->requires_requests = true;
+	src_vq->gfp_flags = __GFP_RETRY_MAYFAIL;
 
 	ret = vb2_queue_init(src_vq);
 	if (ret)
@@ -616,6 +617,7 @@ int cedrus_queue_init(void *priv, struct vb2_queue *src_vq,
 	dst_vq->timestamp_flags = V4L2_BUF_FLAG_TIMESTAMP_COPY;
 	dst_vq->lock = &ctx->dev->dev_mutex;
 	dst_vq->dev = ctx->dev->dev;
+	dst_vq->gfp_flags = __GFP_RETRY_MAYFAIL;
 
 	return vb2_queue_init(dst_vq);
 }

-- 
2.55.0

