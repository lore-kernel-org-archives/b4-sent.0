From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Fri, 13 Nov 2026 16:40:34 +0000
Subject: [PATCH v3 03/12] media: verisilicon: Complete the request when the
 VPU can't resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-hantro-robust-v3-3-82383c722ad2@gmail.com>
References: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
In-Reply-To: <20261113-hantro-robust-v3-0-82383c722ad2@gmail.com>
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Nicolas Frattaroli <frattaroli.nicolas@gmail.com>, 
 Andrzej Pietrasiewicz <andrzej.p@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>
Cc: linux-media@vger.kernel.org, iommu@lists.linux.dev, 
 linux-rockchip@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sergei Khomenkov <shomenkow@gmail.com>, 
 Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794588032; l=1356;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dcuFbBUH76d1uZ1BUVv0QU7AVt7L3akWWbZ+Mrdvg+I=;
 b=YS62kIkVRY6LHDmN/vH4lFvz33jKVGNFKm/SlC2vyNIpKbNOEVMlQ4zjchnMUSOlOD9PgdR/D
 nojFp3hpkZwCWE0o5NH26npE1Kg342s81Ds9ADxyFjTFwHYy7gEZsbN
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If pm_runtime_resume_and_get() fails, device_run() returns the buffers
without completing the controls of the request, and the request stays
queued forever. Complete them on that path.

Fixes: 7d47b45dc590 ("media: rockchip/vpu: Support the Request API")
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/hantro_drv.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/media/platform/verisilicon/hantro_drv.c b/drivers/media/platform/verisilicon/hantro_drv.c
index e86eb943d16a..42822b2b376c 100644
--- a/drivers/media/platform/verisilicon/hantro_drv.c
+++ b/drivers/media/platform/verisilicon/hantro_drv.c
@@ -176,16 +176,20 @@ static void device_run(void *priv)
 	dst = hantro_get_dst_buf(ctx);
 
 	ret = pm_runtime_resume_and_get(vpu->dev);
-	if (ret < 0) {
-		hantro_job_finish_no_pm(ctx, VB2_BUF_STATE_ERROR);
-		return;
-	}
+	if (ret < 0)
+		goto err_cancel_job;
 
 	v4l2_m2m_buf_copy_metadata(src, dst);
 
 	ret = ctx->codec_ops->run(ctx);
 	if (ret)
 		hantro_job_finish(ctx, VB2_BUF_STATE_ERROR);
+
+	return;
+
+err_cancel_job:
+	v4l2_ctrl_request_complete(src->vb2_buf.req_obj.req, &ctx->ctrl_handler);
+	hantro_job_finish_no_pm(ctx, VB2_BUF_STATE_ERROR);
 }
 
 static const struct v4l2_m2m_ops vpu_m2m_ops = {

-- 
2.55.0

