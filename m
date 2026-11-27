From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:25:32 +0000
Subject: [PATCH 6.6.y] media: verisilicon: Fix kernel panic due to
 __initconst misuse
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-hantro-66-v1-1-aba19fe8802e@certik.com>
X-B4-Tracking: v=1; b=H4sIAFsiCWsC/1WNyw7CIBBFf6WZtVOBKE38FdMFj8FiDBgGjabpv
 wu6cnnPfa3AVCIxnIYVCj0jx5yakLsB3GLShTD6pkEJpaVUE3I+YjNqyag1SiWMDX4Sh6Chde6
 FQnx9986gRz2+Yf5hftgrudq3etAaJrTFJLd0xJR8zfmGne//PmDbPkbY7DGmAAAA
X-Change-ID: 20261127-so5-hantro-66-120abfd704f6
To: stable@vger.kernel.org
Cc: Ming Qian <ming.qian@oss.nxp.com>, linux-media@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795760731; l=3408;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Ad6RJTkF+6/+3vTssn3nKs2XylgDjMRr7Z2PcXcc+fQ=;
 b=zCmTakDP5f5qErT1jAVzgJt63slLKKZE/RkO9ede/VeTk+aop/XfnX18h4CGob6/xdxSozWUt
 Avz/YI5aDKCDNX/hXxK1nGOJLkz+G72BidAQ88FDtBcPzMHbx8jTzOS
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Ming Qian <ming.qian@oss.nxp.com>

commit e8d97c270cb46a2a88739019d0f8547adc7d97da upstream.

Fix a kernel panic when probing the driver as a module:

  Unable to handle kernel paging request at virtual address
  ffffd9c18eb05000
  of_find_matching_node_and_match+0x5c/0x1a0
  hantro_probe+0x2f4/0x7d0 [hantro_vpu]

The imx8mq_vpu_shared_resources array is referenced by variant
structures through their shared_devices field. When built as a
module, __initconst causes this data to be freed after module
init, but it's later accessed during probe, causing a page fault.

The imx8mq_vpu_shared_resources is referenced from non-init code,
so keeping __initconst or __initconst_or_module here is wrong.

Drop the __initconst annotation and let it live in the normal .rodata
section.

A bug of __initconst called from regular non-init probe code
leading to bugs during probe deferrals or during unbind-bind cycles.

Reported-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Closes: https://lore.kernel.org/all/68ef934f-baa0-4bf6-93d8-834bbc441e66@kernel.org/
Reported-by: Franz Schnyder <franz.schnyder@toradex.com>
Closes: https://lore.kernel.org/all/n3qmcb62tepxltoskpf7ws6yiirc2so62ia23b42rj3wlmpl67@rvkbuirx7kkp/
Fixes: e0203ddf9af7 ("media: verisilicon: Avoid G2 bus error while decoding H.264 and HEVC")
Suggested-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Suggested-by: Marco Felsch <m.felsch@pengutronix.de>
Reviewed-by: Marco Felsch <m.felsch@pengutronix.de>
Signed-off-by: Ming Qian <ming.qian@oss.nxp.com>
Reviewed-by: Frank Li <Frank.Li@nxp.com>
Reviewed-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Cc: stable@kernel.org
Signed-off-by: Nicolas Dufresne <nicolas.dufresne@collabora.com>
Signed-off-by: Hans Verkuil <hverkuil+cisco@kernel.org>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.12.y and newer already have this fix.

Tested on v6.6.163:
- x86_64 allmodconfig W=1 build of imx8m_vpu_hw.o with
  VIDEO_HANTRO_IMX8M=y, base vs patched, no new warnings; the table
  moves from .init.rodata to .rodata
- booted the patched kernel under QEMU/KVM. I don't have i.MX8MQ
  hardware, so the G1/G2 probe wasn't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

drivers/media/platform/verisilicon/imx8m_vpu_hw.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
---
 drivers/media/platform/verisilicon/imx8m_vpu_hw.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/media/platform/verisilicon/imx8m_vpu_hw.c b/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
index cdaac2f18fb5..de27c142b7fe 100644
--- a/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
+++ b/drivers/media/platform/verisilicon/imx8m_vpu_hw.c
@@ -361,7 +361,7 @@ const struct hantro_variant imx8mq_vpu_variant = {
 	.num_regs = ARRAY_SIZE(imx8mq_reg_names)
 };
 
-static const struct of_device_id imx8mq_vpu_shared_resources[] __initconst = {
+static const struct of_device_id imx8mq_vpu_shared_resources[] = {
 	{ .compatible = "nxp,imx8mq-vpu-g1", },
 	{ .compatible = "nxp,imx8mq-vpu-g2", },
 	{ /* sentinel */ }

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261127-so5-hantro-66-120abfd704f6

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

