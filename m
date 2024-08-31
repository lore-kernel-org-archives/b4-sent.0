From: Keguang Zhang <keguang.zhang@gmail.com>
Date: Sat, 31 Aug 2024 17:41:09 +0800
Subject: [PATCH] dmaengine: loongson1-apb-dma: Fix the build warning caused
 by the size of pdev_irqname
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240831-fix-loongson1-dma-v1-1-91376d87695c@gmail.com>
X-B4-Tracking: v=1; b=H4sIADTl0mYC/x2MQQqAIBAAvyJ7bsG1oOgr0UF0q4XSUIhA/HvSc
 WBmCmROwhlmVSDxI1liaECdAnfYsDOKbwxGm0FPPeEmL54xhj3HQOgvi9s42d5pr4kIWncnbtL
 /XNZaPwxfKyFjAAAA
To: Vinod Koul <vkoul@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel test robot <lkp@intel.com>, 
 Keguang Zhang <keguang.zhang@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725097485; l=2069;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=9F7l316ps9HN6pWRl3U35o6ZL8rlcyn9cYcUpzY8XIk=;
 b=q0fD0o+6qKstKnpPMNAUzLR8RiMcfvfrzXUgn/Py5cvAoOcaqibaJjDj6Wuz2FVZ1p8I+Nj22
 2WIq9qcO7t+DZ6lfXoQscu7uebAmAmmQeuOb1EdwU+zn3S7QpMMEDcf
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

drivers/dma/loongson1-apb-dma.c: In function 'ls1x_dma_probe':
drivers/dma/loongson1-apb-dma.c:531:42: warning: '%d' directive writing between 1 and 8 bytes into a region of size 2 [-Wformat-overflow=]
  531 |                 sprintf(pdev_irqname, "ch%d", id);
      |                                          ^~
In function 'ls1x_dma_chan_probe',
    inlined from 'ls1x_dma_probe' at drivers/dma/loongson1-apb-dma.c:605:8:
drivers/dma/loongson1-apb-dma.c:531:39: note: directive argument in the range [0, 19522579]
  531 |                 sprintf(pdev_irqname, "ch%d", id);
      |                                       ^~~~~~
drivers/dma/loongson1-apb-dma.c:531:17: note: 'sprintf' output between 4 and 11 bytes into a destination of size 4
  531 |                 sprintf(pdev_irqname, "ch%d", id);
      |                 ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Fix the array size and use snprintf() instead of sprintf().

Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202408302108.xIR18jmD-lkp@intel.com/
Signed-off-by: Keguang Zhang <keguang.zhang@gmail.com>
---
 drivers/dma/loongson1-apb-dma.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/dma/loongson1-apb-dma.c b/drivers/dma/loongson1-apb-dma.c
index ca43c67a8203..255fe7eca212 100644
--- a/drivers/dma/loongson1-apb-dma.c
+++ b/drivers/dma/loongson1-apb-dma.c
@@ -526,9 +526,9 @@ static int ls1x_dma_chan_probe(struct platform_device *pdev,
 
 	for (id = 0; id < dma->nr_chans; id++) {
 		struct ls1x_dma_chan *chan = &dma->chan[id];
-		char pdev_irqname[4];
+		char pdev_irqname[16];
 
-		sprintf(pdev_irqname, "ch%d", id);
+		snprintf(pdev_irqname, sizeof(pdev_irqname), "ch%d", id);
 		chan->irq = platform_get_irq_byname(pdev, pdev_irqname);
 		if (chan->irq < 0)
 			return dev_err_probe(&pdev->dev, chan->irq,

---
base-commit: 985bf40edf4343dcb04c33f58b40b4a85c1776d4
change-id: 20240831-fix-loongson1-dma-f78a3c0d0111

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

