From: Anthony Brandon <anthony@amarulasolutions.com>
Date: Mon, 13 Oct 2025 17:48:49 +0200
Subject: [PATCH v5] dmaengine: xilinx: xdma: Fix regmap max_register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251013-xdma-max-reg-v5-1-83efeedce19d@amarulasolutions.com>
X-B4-Tracking: v=1; b=H4sIAGAf7WgC/33OSw6CMBCA4auYrq1h+uDhynsYFwOt0ASoaYFgC
 Hd3cGVIZPlPZr7MwqINzkZ2PS0s2MlF53sKfT6xqsG+ttwZaiYSoZMiAT6bDnmHMw+25pCqokq
 VLqTOGZ28gn26+cvdH9SNi4MP768+wTb9A03AgZcpJkqnYE0JN+wwjC1G344D/RQvle/YZk7iy
 BHkPFFmQmIGeWUOHPnriJ0jydEbVOZGlKAPHPXryJ2jyMkLlQmATNPKH2dd1w9iAz6ziwEAAA=
 =
X-Change-ID: 20250901-xdma-max-reg-1649c6459358
To: Lizhi Hou <lizhi.hou@amd.com>, Brian Xu <brian.xu@amd.com>, 
 Raj Kumar Rampelli <raj.kumar.rampelli@amd.com>, 
 Vinod Koul <vkoul@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Sonal Santan <sonal.santan@amd.com>, Max Zhen <max.zhen@amd.com>
Cc: dmaengine@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, 
 Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>, 
 Alexander Stein <alexander.stein@ew.tq-group.com>, 
 Anthony Brandon <anthony@amarulasolutions.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3329;
 i=anthony@amarulasolutions.com; h=from:subject:message-id;
 bh=zm9B3BfNwF6YoIlqBfCv8ID8sIfD6lc0Mod18hncI6s=;
 b=owGbwMvMwCUWIi5b4HjluATjabUkhoy38i3rlObXltcKZGfnZTPlh9lcYd6vyn/49ZLII2Z7V
 zfmbuLqKGVhEONikBVTZCnXkef1UK4rV5r5xBhmDisTyBAGLk4BmIjSK0aG74I+Eye1VMtoRaSf
 vfenvyH4HtOzP/dPvvCf3pkzt2STEcP/ml6O2V2P+g8ziN2LO621z2pZv9of2R0yt3/ofpY4s72
 eDwA=
X-Developer-Key: i=anthony@amarulasolutions.com; a=openpgp;
 fpr=772C1F0D48237E772299E43354171D7041D4C718
X-Endpoint-Received: by B4 Relay for anthony@amarulasolutions.com/default with auth_id=505
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The max_register field is assigned the size of the register memory
region instead of the offset of the last register.
The result is that reading from the regmap via debugfs can cause
a segmentation fault:

tail /sys/kernel/debug/regmap/xdma.1.auto/registers
Unable to handle kernel paging request at virtual address ffff800082f70000
Mem abort info:
  ESR = 0x0000000096000007
  EC = 0x25: DABT (current EL), IL = 32 bits
  SET = 0, FnV = 0
  EA = 0, S1PTW = 0
  FSC = 0x07: level 3 translation fault
[...]
Call trace:
 regmap_mmio_read32le+0x10/0x30
 _regmap_bus_reg_read+0x74/0xc0
 _regmap_read+0x68/0x198
 regmap_read+0x54/0x88
 regmap_read_debugfs+0x140/0x380
 regmap_map_read_file+0x30/0x48
 full_proxy_read+0x68/0xc8
 vfs_read+0xcc/0x310
 ksys_read+0x7c/0x120
 __arm64_sys_read+0x24/0x40
 invoke_syscall.constprop.0+0x64/0x108
 do_el0_svc+0xb0/0xd8
 el0_svc+0x38/0x130
 el0t_64_sync_handler+0x120/0x138
 el0t_64_sync+0x194/0x198
Code: aa1e03e9 d503201f f9400000 8b214000 (b9400000)
---[ end trace 0000000000000000 ]---
note: tail[1217] exited with irqs disabled
note: tail[1217] exited with preempt_count 1
Segmentation fault

Fixes: 17ce252266c7 ("dmaengine: xilinx: xdma: Add xilinx xdma driver")
Reviewed-by: Lizhi Hou <lizhi.hou@amd.com>
Reviewed-by: Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>
Reviewed-by: Alexander Stein <alexander.stein@ew.tq-group.com>
Signed-off-by: Anthony Brandon <anthony@amarulasolutions.com>
---
Changes in v5:
- Update Reviewed-by
- Link to v4: https://lore.kernel.org/r/20250903-xdma-max-reg-v4-1-894721175025@amarulasolutions.com

Changes in v4:
- Reorder Reviewed-by
- Link to v3: https://lore.kernel.org/r/20250902-xdma-max-reg-v3-1-5fa37b8d2b15@amarulasolutions.com

Changes in v3:
- Add Fixes tag
- Link to v2: https://lore.kernel.org/r/20250901-xdma-max-reg-v2-1-fa3723a718cd@amarulasolutions.com

Changes in v2:
- Define new constant XDMA_MAX_REG_OFFSET and use that.
- Link to v1: https://lore.kernel.org/r/20250901-xdma-max-reg-v1-1-b6a04561edb1@amarulasolutions.com
---
 drivers/dma/xilinx/xdma-regs.h | 1 +
 drivers/dma/xilinx/xdma.c      | 2 +-
 2 files changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/dma/xilinx/xdma-regs.h b/drivers/dma/xilinx/xdma-regs.h
index 6ad08878e93862b770febb71b8bc85e66813428e..70bca92621aa41b0367d1e236b3e276344a26320 100644
--- a/drivers/dma/xilinx/xdma-regs.h
+++ b/drivers/dma/xilinx/xdma-regs.h
@@ -9,6 +9,7 @@
 
 /* The length of register space exposed to host */
 #define XDMA_REG_SPACE_LEN	65536
+#define XDMA_MAX_REG_OFFSET	(XDMA_REG_SPACE_LEN - 4)
 
 /*
  * maximum number of DMA channels for each direction:
diff --git a/drivers/dma/xilinx/xdma.c b/drivers/dma/xilinx/xdma.c
index 0d88b1a670e142dac90d09c515809faa2476a816..5ecf8223c112e468c79ce635398ba393a535b9e0 100644
--- a/drivers/dma/xilinx/xdma.c
+++ b/drivers/dma/xilinx/xdma.c
@@ -38,7 +38,7 @@ static const struct regmap_config xdma_regmap_config = {
 	.reg_bits = 32,
 	.val_bits = 32,
 	.reg_stride = 4,
-	.max_register = XDMA_REG_SPACE_LEN,
+	.max_register = XDMA_MAX_REG_OFFSET,
 };
 
 /**

---
base-commit: 52ba76324a9d7c39830c850999210a36ef023cde
change-id: 20250901-xdma-max-reg-1649c6459358

Best regards,
-- 
Anthony Brandon <anthony@amarulasolutions.com>

