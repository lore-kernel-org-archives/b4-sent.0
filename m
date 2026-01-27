From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/5] dma: dma-axi-dmac: Add cyclic transfer support and
 graceful termination
Date: Tue, 27 Jan 2026 14:28:21 +0000
Message-Id: <20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQqAMAxA0atIZgNthgpeRRxqGjUgWloVRby7x
 fEN/z+QJalkaKsHkpyadVsLbF0Bz36dBDUUAxlyxpJDfykGz8g3L8qYjxi3tKM3riE7kFjTQIl
 jklGvf9z17/sBqTiTdGgAAAA=
X-Change-ID: 20260126-axi-dac-cyclic-support-a06721b2e107
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769524107; l=2413;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=3HvqTBYkV3aATja0J5KbViF7E4aOH3n6falxINzDQoc=;
 b=SKdghfEKEFUwl8IYf7tgeKB/NB4V6xg6OM4tUd4y7LQBtZtAONewZnjW70nLg+JCC+XGPplbH
 TgE6qNxTz5FCZfJ50lQ80G2sYQyDczNgrwElEDrpMgEQJaprDUEFF2T
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for cyclic transfers in the .device_prep_peripheral_dma_vec()
callback and implements graceful termination of cyclic transfers using the
DMA_PREP_LOAD_EOT flag. Using DMA_PREP_REPEAT and DMA_PREP_LOAD_EOT is
based on the discussion in [1].

Currently, the only way to stop a cyclic transfer is through brute force using
.device_terminate_all(), which terminates all pending transfers. This series
introduces a mechanism to gracefully terminate individual cyclic transfers when
a new transfer flagged with DMA_PREP_LOAD_EOT is queued.

We need two different approaches:

1. Software-managed cyclic transfers: These generate EOT (End-Of-Transfer)
   interrupts for each cycle. Hence, termination can be handled directly
   in the interrupt handler when the EOT interrupt fires, making the
   transition to the next transfer straightforward.

2. Hardware-managed cyclic transfers: These are optimized to avoid interrupt
   overhead by suppressing EOT interrupts. Since there are no EOT interrupts,
   termination must be detected at SOF (Start-Of-Frame) when new transfers
   are being considered. The transfer is marked for termination and the
   hardware is configured to end the current cycle gracefully.

For HW-managed cyclic mode, the series handles both scatter-gather and non-SG
variants. With SG support, the last segment flags are modified to trigger EOT.
Without SG, the CYCLIC flag is cleared to allow natural completion. A workaround
is included for older IP cores (pre-4.6.a) that can prefetch data incorrectly
when clearing the CYCLIC flag, requiring a core disable/enable cycle.

[1]: https://lore.kernel.org/dmaengine/ZhJW9JEqN2wrejvC@matsya/

---
Nuno Sá (5):
      dmaengine: Document cyclic transfer for dmaengine_prep_peripheral_dma_vec()
      dma: dma-axi-dmac: add cyclic transfers in .device_prep_peripheral_dma_vec()
      dma: dma-axi-dmac: add helper for getting next desc
      dma: dma-axi-dmac: Gracefully terminate SW cyclic transfers
      dma: dma-axi-dmac: gracefully terminate HW cyclic transfers

 drivers/dma/dma-axi-dmac.c | 170 +++++++++++++++++++++++++++++++++++++++------
 include/linux/dmaengine.h  |   3 +-
 2 files changed, 151 insertions(+), 22 deletions(-)
---
base-commit: 3c8a86ed002ab8fb287ee4ec92f0fd6ac5b291d2
change-id: 20260126-axi-dac-cyclic-support-a06721b2e107
--

Thanks!
- Nuno Sá

