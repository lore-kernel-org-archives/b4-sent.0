From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Tue, 10 Nov 2026 07:18:31 +0000
Subject: [PATCH 2/2] media: rkvdec: vdpu381: Compress the co-located motion
 vectors of HEVC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-rkvdec-colmv-v1-2-012b84ea43f7@gmail.com>
References: <20261110-rkvdec-colmv-v1-0-012b84ea43f7@gmail.com>
In-Reply-To: <20261110-rkvdec-colmv-v1-0-012b84ea43f7@gmail.com>
To: Detlev Casanova <detlev.casanova@collabora.com>, 
 Ezequiel Garcia <ezequiel@vanguardiasur.com.ar>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Heiko Stuebner <heiko@sntech.de>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794295110; l=1292;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=aR2E6mm8VmFdhqxcYYQcTYrdQAfdhAGApJk/FfwVCSs=;
 b=Nvipk1pBnacMtoHPhiijMXW93iXUPSvrqtmt0lMr1tJZacZiL4eED7FMRpbuGsIKUa1Msib3t
 TFp4Pa0RMT0Duq3WRTpwMMWQ0EvjVbUxGJdFEv3Dw+olWBZPvBj1N1O
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Like for H.264, store the co-located motion vectors of HEVC frames
compressed, which the vendor code (MPP, hal_h265d_vdpu34x.c) always
does. The previous commit reserved space for the compressed layout.

On RK3588, a 24 Mbit/s 3840x2160 HEVC stream (240 frames, x265
ultrafast) decodes at 104.6 fps instead of 98.6-102.8 fps, and the
decoded frames are identical.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c
index e1936e87f45b..2473c176b319 100644
--- a/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c
+++ b/drivers/media/platform/rockchip/rkvdec/rkvdec-vdpu381-hevc.c
@@ -404,6 +404,9 @@ static void config_registers(struct rkvdec_ctx *ctx,
 	/* Set HEVC mode */
 	regs->common.reg009_dec_mode.dec_mode = VDPU381_MODE_HEVC;
 
+	/* Store the co-located motion vectors compressed, as for H.264 */
+	regs->common.reg012_secondary_en.colmv_compress_en = 1;
+
 	/* Set config */
 	regs->common.reg011_important_en.buf_empty_en = 1;
 	regs->common.reg011_important_en.dec_clkgate_e = 1;

-- 
2.55.0

