From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Thu, 12 Nov 2026 08:30:49 +0000
Subject: [PATCH v2 3/6] media: verisilicon: Enable the Rockchip encoder
 interrupt again after a reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261112-hantro-robust-v2-3-18561fd48838@gmail.com>
References: <20261112-hantro-robust-v2-0-18561fd48838@gmail.com>
In-Reply-To: <20261112-hantro-robust-v2-0-18561fd48838@gmail.com>
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
 Jernej Skrabec <jernej.skrabec@gmail.com>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Sergei Khomenkov <shomenkow@gmail.com>, 
 Tharit Tangkijwanichakul <tharitt97@gmail.com>, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794472247; l=2118;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=/pdV5Ao1nfGJCAVq9CfIzOPUMn8hmIXBimy2UnM/Qpk=;
 b=ft5+zd+VMM7oNCjDiVVEWeZlc3SSoAWnTT6gIEqUHrWWoRnoY+fjjX7uOstpMkkQs3JCHDa2w
 y0Ch1+HeEICDFvreFFH8syfHKBG6uUPEluWPx/0eyl9oBMCcxhBMFAn
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The reset operations of the Rockchip VEPU1 and VEPU2 encoders, which
hantro_watchdog() calls when a job times out, disable the encoder
interrupt before stopping the encoder. Nothing enables it again: the
encoder run functions don't write the interrupt register, only the
interrupt handler does, and it no longer runs. Every later job on the
encoder then times out as well.

Clear the interrupt register at the end of the reset, as the interrupt
handler does after each frame.

Fixes: 775fec69008d ("media: add Rockchip VPU JPEG encoder driver")
Cc: stable@vger.kernel.org
Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
 drivers/media/platform/verisilicon/rockchip_vpu_hw.c | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
index 02673be9878e..5d4e46bd9cd6 100644
--- a/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/rockchip_vpu_hw.c
@@ -475,6 +475,12 @@ static void rockchip_vpu1_enc_reset(struct hantro_ctx *ctx)
 	vepu_write(vpu, H1_REG_INTERRUPT_DIS_BIT, H1_REG_INTERRUPT);
 	vepu_write(vpu, 0, H1_REG_ENC_CTRL);
 	vepu_write(vpu, 0, H1_REG_AXI_CTRL);
+	/*
+	 * The encoder runs don't write the interrupt register, only the
+	 * interrupt handler clears it after each frame. Clear it here too,
+	 * or the interrupt stays disabled and all later jobs time out.
+	 */
+	vepu_write(vpu, 0, H1_REG_INTERRUPT);
 }
 
 static void rockchip_vpu2_dec_reset(struct hantro_ctx *ctx)
@@ -493,6 +499,12 @@ static void rockchip_vpu2_enc_reset(struct hantro_ctx *ctx)
 	vepu_write(vpu, VEPU_REG_INTERRUPT_DIS_BIT, VEPU_REG_INTERRUPT);
 	vepu_write(vpu, 0, VEPU_REG_ENCODE_START);
 	vepu_write(vpu, 0, VEPU_REG_AXI_CTRL);
+	/*
+	 * The encoder runs don't write the interrupt register, only the
+	 * interrupt handler clears it after each frame. Clear it here too,
+	 * or the interrupt stays disabled and all later jobs time out.
+	 */
+	vepu_write(vpu, 0, VEPU_REG_INTERRUPT);
 }
 
 /*

-- 
2.55.0

