From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v2 0/2] dmaengine: Kill channel tasklets in remove again
Date: Mon, 23 Nov 2026 01:17:36 +0000
Message-Id: <20261123-dma-chancnt-v2-0-241b1672883e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADCUA2sC/yXM0QpAMBTG8VfRubayqUNeRS5mOzjKaBspeXfD5
 a+v739BIM8UoMku8HRw4NUlqDwDM2k3kmCbDKpQKKUqhV20eBfjokDEuqoNUiktpMfmaeDzq7X
 d77D3M5n4JuC+H4UEbkFvAAAA
X-Change-ID: 20261123-dma-chancnt-666878c6e31d
To: ludovic.desroches@microchip.com, vkoul@kernel.org
Cc: Frank.Li@kernel.org, dave.jiang@intel.com, linux-kernel@vger.kernel.org, 
 andriy.shevchenko@linux.intel.com, dmaengine@vger.kernel.org, 
 allen.lkml@gmail.com, linux-arm-kernel@lists.infradead.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795396657; l=1886;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=M5gstoa5unIW6ysGcN08lUHOdZ09B3VvbPuhdhXnsik=;
 b=LQs0pOspOgbUIO95yvZexbf4sS3I8++eHStsRQwYgm2jYqaZHEriAT7k94R/Nd/SEVvR1qzKk
 Ztf/Alz9L51DCtlvbeNuOaqeczz3adTd1LScgJyiWWTK6z3k5yjeTHp
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

at_xdmac and idma64 kill their channel tasklets in remove() with a loop
over dma.chancnt after dma_async_device_unregister(). Since commit
e81274cd6b52, dma_async_device_unregister() unregisters each channel
and decrements dma.chancnt for it, so chancnt is 0 when the loops run,
they do nothing, and a tasklet scheduled by an interrupt can run after
the devm-allocated driver data is gone.

For at_xdmac, just making the loop run again is not enough, as the
Sashiko review of v1 pointed out: the tasklets and
at_xdmac_free_chan_resources() would then run after the channel
devices are freed and the clock is disabled. v2 moves the IRQ, tasklet
and channel cleanup in front of dma_async_device_unregister() and
clk_disable_unprepare() instead. idma64 has no clock to disable and its
virt-dma tasklet uses neither the registers nor the channel device, so
patch 2 is unchanged.

These loops are also touched by Allen's "dmaengine: migrate channel
tasklets to WQ_BH" series (v4, 01/33 and 04/33). The two fixes don't
depend on that series. Whichever goes in second needs a trivial rebase.

Found with a static analysis tool and checked by hand. Compile tested
on x86_64 with COMPILE_TEST (W=1); I don't have the hardware.

Changes in v2:
- 1/2: move free_irq(), the tasklet kills and the channel cleanup before
  dma_async_device_unregister() and clk_disable_unprepare(), instead of
  saving chancnt; add the Fixes tag for the original driver (Sashiko).
- 2/2: unchanged.

v1: https://lore.kernel.org/all/20261123-dma-chancnt-v1-0-f0eea0a4bb63@gmail.com/
---
Suyuan Wang (2):
      dmaengine: at_xdmac: Kill the channel tasklets before unregistering
      dmaengine: idma64: Kill the channel tasklets in remove again

 drivers/dma/at_xdmac.c | 19 ++++++++++++-------
 drivers/dma/idma64.c   |  4 +++-
 2 files changed, 15 insertions(+), 8 deletions(-)

