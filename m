From: Rouven Czerwinski <rouven.czerwinski@linaro.org>
Date: Fri, 10 Apr 2026 08:15:42 +0200
Subject: [PATCH] media: verisilicon: remove hantro_run declaration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260410-hantro-dangling-declaration-v1-1-9a5cd401e1e8@linaro.org>
X-B4-Tracking: v=1; b=H4sIAI2V2GkC/yWM0QrCMAxFf2Xk2UDXDUV/RXyITTojo5O0ijD27
 0Z9PPdyzgpVTKXCqVvB5KVVl+LQ7zpINyqToLIzxBD3YQxH9LHZguzfrGVCljSTUXMPaRgOnHu
 mPEbwwsMk6/tXP1/+XJ/Xu6T2TcK2fQCtNtI5fwAAAA==
X-Change-ID: 20260409-hantro-dangling-declaration-a337df1daf42
To: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Benjamin Gaignard <benjamin.gaignard@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Rouven Czerwinski <rouven.czerwinski@linaro.org>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775801743; l=1100;
 i=rouven.czerwinski@linaro.org; s=20260126; h=from:subject:message-id;
 bh=S0B4Mku1guaft4/xRhZzu1ThAb3ZD3LGOoP/Tz4zCTw=;
 b=7E6nGoMWJBA5PgHEOkOKz1jYhKj6PFmoJ6mDMXpGK+YWJZp4CEAev4BXVwo+lLQaef01nbT5p
 3g3pCcNPbjyAgv6neHlgj05TGfATo/w8fx9F2WK5CfrarKI9VZgMIOu
X-Developer-Key: i=rouven.czerwinski@linaro.org; a=ed25519;
 pk=/5pmUK/XIAIIo8JA0axgfy1k8NRhRTQkxVwZYa1ga7U=
X-Endpoint-Received: by B4 Relay for rouven.czerwinski@linaro.org/20260126 with auth_id=616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The function hantro_run() is declared but never defined nor used, remove
the dangling declaration.

Signed-off-by: Rouven Czerwinski <rouven.czerwinski@linaro.org>
---
 drivers/media/platform/verisilicon/hantro_hw.h | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/hantro_hw.h b/drivers/media/platform/verisilicon/hantro_hw.h
index 5f2011529f02..13e573f1f19d 100644
--- a/drivers/media/platform/verisilicon/hantro_hw.h
+++ b/drivers/media/platform/verisilicon/hantro_hw.h
@@ -427,7 +427,6 @@ extern const struct hantro_postproc_ops rockchip_vpu981_postproc_ops;
 extern const u32 hantro_vp8_dec_mc_filter[8][6];
 
 void hantro_watchdog(struct work_struct *work);
-void hantro_run(struct hantro_ctx *ctx);
 void hantro_irq_done(struct hantro_dev *vpu,
 		     enum vb2_buffer_state result);
 void hantro_start_prepare_run(struct hantro_ctx *ctx);

---
base-commit: 591cd656a1bf5ea94a222af5ef2ee76df029c1d2
change-id: 20260409-hantro-dangling-declaration-a337df1daf42

Best regards,
--  
Rouven Czerwinski <rouven.czerwinski@linaro.org>

