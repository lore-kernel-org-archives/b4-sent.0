From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Thu, 26 Nov 2026 16:55:45 -0800
Subject: [PATCH 1/4] media: tegra-vde: size the bitstream buffer from the
 frame size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-tegra-vde-fixes-v1-1-fa4a7c1d24cc@proton.me>
References: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
In-Reply-To: <20261126-tegra-vde-fixes-v1-0-fa4a7c1d24cc@proton.me>
To: Dmitry Osipenko <digetx@gmail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-media@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2227;
 i=jerome.berclaz@proton.me; s=2026-11; h=from:subject:message-id;
 bh=of+v03Cai+sc1Z1OBE6gFSTjg74YDAkDoxW4asgwOx4=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNkcV4UeLUtdzHLyAV+H5FRLx3mKMwTSNou+vOnvLTvL8
 jBf5Aq+jlIWBjEuBlkxRRbWBsPU+SfYAgr15x2CmcPKBDKEgYtTACayjZmRYfdCjh9fFDg3zbz2
 Zs/nj1L5omvTblXPfm9kaL5Ca2FOWCjDP+Xj0YmSnJ1XJxhUGdX8O/ik8XkPw1tnxucKBoKPPt+
 czAQA
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/2026-11 with auth_id=1658
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_try_coded_fmt() makes every bitstream (OUTPUT) buffer at least 2 MiB.
When the decoder sits behind the SMMU, the buffers use vb2_dma_sg_memops,
i.e. cached pages, and videobuf2 cleans the whole plane for every queued
buffer (once in dma_buf_end_cpu_access() when user space has written the
slice data, once more in __buf_prepare()). With 2 MiB per buffer that is
about 4 MiB of cache maintenance per decoded frame, although a 720p frame
is typically well below 200 KiB.

Use three quarters of a raw 4:2:0 frame as the default minimum instead
(704 KiB at 1280x720, 1.5 MiB at 1920x1080), still aligned to
SXE_BUFFER and never below 256 KiB. User space can still ask for more.

Measured on a Microsoft Surface RT (Tegra 30) with GStreamer
v4l2slh264dec on a 720p Constrained Baseline file: the v7/l2c210 clean
and invalidate functions in the decoding thread were about 21% of all CPU
samples before the change.

Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
 drivers/media/platform/nvidia/tegra-vde/v4l2.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/media/platform/nvidia/tegra-vde/v4l2.c b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
index f2ca1c7ed9ba..9fe31b5c0275 100644
--- a/drivers/media/platform/nvidia/tegra-vde/v4l2.c
+++ b/drivers/media/platform/nvidia/tegra-vde/v4l2.c
@@ -635,6 +635,7 @@ static int tegra_try_coded_fmt(struct file *file, void *priv,
 	const struct tegra_vde_soc *soc = ctx->vde->soc;
 	int size = pix_mp->plane_fmt[0].sizeimage;
 	const struct tegra_coded_fmt_desc *desc;
+	unsigned int min_size;
 
 	desc = tegra_find_coded_fmt_desc(ctx, pix_mp->pixelformat);
 	if (!desc) {
@@ -646,7 +647,11 @@ static int tegra_try_coded_fmt(struct file *file, void *priv,
 				       &pix_mp->height,
 				       &desc->frmsize);
 
-	pix_mp->plane_fmt[0].sizeimage = max(ALIGN(size, SXE_BUFFER), SZ_2M);
+	min_size = ALIGN(pix_mp->width * pix_mp->height * 3 / 4, SXE_BUFFER);
+	min_size = max_t(unsigned int, min_size, SZ_256K);
+
+	pix_mp->plane_fmt[0].sizeimage =
+		max_t(unsigned int, ALIGN(size, SXE_BUFFER), min_size);
 	pix_mp->field = V4L2_FIELD_NONE;
 	pix_mp->num_planes = 1;
 

-- 
2.53.0

