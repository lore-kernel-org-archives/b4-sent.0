From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Thu, 26 Nov 2026 16:55:46 -0800
Subject: [PATCH 2/4] media: tegra-vde: allow cache hints on the capture
 queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tegra-vde-fixes-v1-2-fa4a7c1d24cc@proton.me>
References: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
In-Reply-To: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
To: Dmitry Osipenko <digetx@gmail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-media@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1318;
 i=jerome.berclaz@proton.me; s=2026-11; h=from:subject:message-id;
 bh=zLiW2FSkpXZ0lI6JCWYLwvCRGSU1EAnRKmDeIdvXN4w=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNkcV4VWqzXuZJ1mpRj3xPfMG+YES+9T0W0fvux4YHsm5
 K6xsUB0RykLgxgXg6yYIgtrg2Hq/BNsAYX68w7BzGFlAhnCwMUpABPx2sjI8HR97oGZc4/FdJ68
 l7/JokFpV2w576HqtDkSRcc8597cuYrhN/vOk6sPPOX0XfukpGVWk6DjyeO5Dk2huw+2ne2e6Fp
 9nRkA
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/2026-11 with auth_id=1658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the decoder sits behind the SMMU, buffers use vb2_dma_sg_memops,
i.e. cached pages, and vb2 cleans and invalidates every decoded frame
(1.4 MB at 720p) on each QBUF and DQBUF. A client that hands the frames
to the display or GPU as dma-bufs never reads them through the CPU, and
when it does, the dma-buf begin/end_cpu_access ops do the sync.

Set allow_cache_hints on the capture queue so that such clients can pass
V4L2_BUF_FLAG_NO_CACHE_CLEAN / V4L2_BUF_FLAG_NO_CACHE_INVALIDATE, as the
MediaTek decoder already allows.

Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
 drivers/media/platform/nvidia/tegra-vde/v4l2.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/media/platform/nvidia/tegra-vde/v4l2.c b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
index 9fe31b5c0275..cd25307ad9db 100644
--- a/drivers/media/platform/nvidia/tegra-vde/v4l2.c
+++ b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
@@ -385,6 +385,7 @@ static int tegra_queue_init(void *priv,
 	dst_vq->timestamp_flags = V4L2_BUF_FLAG_TIMESTAMP_COPY;
 	dst_vq->type = V4L2_BUF_TYPE_VIDEO_CAPTURE_MPLANE;
 	dst_vq->io_modes = VB2_DMABUF | VB2_MMAP;
+	dst_vq->allow_cache_hints = 1;
 	dst_vq->lock = &vde->v4l2_lock;
 	dst_vq->dma_attrs = dma_attrs;
 	dst_vq->mem_ops = mem_ops;

-- 
2.53.0

