From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 13 Oct 2026 03:21:11 +0000
Subject: [PATCH v2] dmaengine: amlogic: Fix little-endian variable
 operations issue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-fix-a9-dma-v2-1-860146b2ef57@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAKajzWoC/22Myw6CMBBFf4XM2jF9aEVX/odhUdoBJhFKWtNoS
 P/dytrluTfnbJAoMiW4NRtEypw4LBXUoQE32WUkZF8ZlFBGCqlw4DfaK/rZ4qmnCxnZW3PWUIU
 1Un332KOrPHF6hfjZ21n+1r+ZLFGi8q0Woh00aXW38zOM7I4uzNCVUr5HiWJypgAAAA==
X-Change-ID: 20261012-fix-a9-dma-4be7e61ba653
To: Vinod Koul <vkoul@kernel.org>, Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791861804; l=1372;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=OZigb4en2c93sg6DmkSHlPZQyczro7uHkaw6ZWL3yJI=;
 b=Opkm9CijTWMJQVlrV4DIhfX6pYsuf2M4OAlshy3Enz6HJKjzfIBIJ62flw8Gc8SXal7Xj+5BH
 r8xHqf/gSxqAri6a9j3i1w8NAOZ3F+NxWD62J5HERDOspwkr0wl1iJy
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In dma_async_tx_descriptor function,fix the situation where the operation
processing of the little-endian variable requires corresponding conversion.

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202610060235.PuCxWQdk-lkp@intel.com/
Fixes: b84b5197e344 ("dmaengine: amlogic: Add general DMA driver for A9")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Fix the operation little-endian variable issue.
---
Changes in v2:
- Simplify processing and rename subject to 'dmaengine', suggested by Frank.
- Link to v1: https://lore.kernel.org/r/20261012-fix-a9-dma-v1-1-2d83008f3e32@amlogic.com
---
 drivers/dma/amlogic-dma.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/dma/amlogic-dma.c b/drivers/dma/amlogic-dma.c
index 78ee2337ae71..dbd23d29397d 100644
--- a/drivers/dma/amlogic-dma.c
+++ b/drivers/dma/amlogic-dma.c
@@ -321,7 +321,7 @@ static struct dma_async_tx_descriptor *aml_dma_prep_slave_sg
 
 	/* the last sg set eoc flag */
 	sg_link--;
-	sg_link->ctl |= LINK_EOC;
+	sg_link->ctl |= cpu_to_le32(LINK_EOC);
 
 	return vchan_tx_prep(&aml_chan->vchan, &aml_desc->vd, flags);
 }

---
base-commit: 42c31fec1ca76b8b5f7759def122d418dff2cd4b
change-id: 20261012-fix-a9-dma-4be7e61ba653

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

