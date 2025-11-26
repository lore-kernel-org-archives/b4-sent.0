From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Subject: [PATCH v2 0/5] dma: fsl/mcf-edma: Bug fixes and enhancements for
 ColdFire support
Date: Wed, 26 Nov 2025 09:36:01 +0100
Message-Id: <20251126-dma-coldfire-v2-0-5b1e4544d609@yoseli.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPG7JmkC/1XMSwrCMBSF4a2UOzbSvEp15D6kg5jctBdqUxIJl
 pK9GwsOHP4HzrdDwkiY4NrsEDFTorDUEKcG7GSWERm52iBaoTkXkrmnYTbMzlNEpr3sDCJX8iG
 hXtaInt4Hdx9qT5ReIW6Hnvl3/UHqH8qctczZ3l8k77Xq1G0LCWc6hzjCUEr5APeA+fepAAAA
X-Change-ID: 20251123-dma-coldfire-5f36aee143b3
To: Frank Li <Frank.Li@nxp.com>, Vinod Koul <vkoul@kernel.org>, 
 Angelo Dureghello <angelo@sysam.it>
Cc: Greg Ungerer <gerg@linux-m68k.org>, imx@lists.linux.dev, 
 dmaengine@vger.kernel.org, linux-m68k@lists.linux-m68k.org, 
 linux-kernel@vger.kernel.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764146162; l=1724;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=6/eSDcaslo9+vYL42NakAq96GQDj2C5lZPUYENmliC4=;
 b=fC5GVRJPXlfdpSiN+oM08RMzdhnInV/phbe9d8m3soqlu4CGAT57yFCvITtNID/Mhwtzo+rKz
 HymH4w0dgnSCYLt80WZyTR2umnlzBWarKN8YEjIHtMxEOho8dK79CCj
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses several bugs in the fsl-edma and mcf-edma drivers
affecting MCF54418 ColdFire processors.

Patch 1 adds the FSL_EDMA_DRV_MCF flag to fix byte-lane addressing for
MCF54418.

Patch 2 adds per-channel IRQ naming for easier debugging.

Patches 3-5 fix the interrupt and error handlers for all 64 DMA
channels:
- Patch 3 fixes the interrupt handler to process all 64 channels
- Patch 4 moves the error handler out of the header file for clarity
- Patch 5 fixes the error handler for all 64 channels with proper types

Tested on a custom MCF54418-based platform with slave DMA transfers.

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
Changes in v2:
- Check devm_kasprintf() return value
- Keep request_irq on one line in naming patch
- Remove non needed memory barrier
- Remove the interleave patch for now
- Link to v1: https://lore.kernel.org/r/20251124-dma-coldfire-v1-0-dc8f93185464@yoseli.org

---
Jean-Michel Hautbois (5):
      dma: fsl-edma: Add FSL_EDMA_DRV_MCF flag for ColdFire eDMA
      dma: mcf-edma: Add per-channel IRQ naming for debugging
      dma: mcf-edma: Fix interrupt handler for 64 DMA channels
      dma: fsl-edma: Move error handler out of header file
      dma: mcf-edma: Fix error handler for all 64 DMA channels

 drivers/dma/fsl-edma-common.c |  5 +++
 drivers/dma/fsl-edma-common.h | 11 +++----
 drivers/dma/mcf-edma-main.c   | 72 +++++++++++++++++++++++++------------------
 3 files changed, 52 insertions(+), 36 deletions(-)
---
base-commit: ac3fd01e4c1efce8f2c054cdeb2ddd2fc0fb150d
change-id: 20251123-dma-coldfire-5f36aee143b3

Best regards,
--  
Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>

