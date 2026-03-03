From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/5] dmaengine: dma-axi-dmac: Add cyclic transfer
 support and graceful termination
Date: Tue, 03 Mar 2026 10:24:59 +0000
Message-Id: <20260303-axi-dac-cyclic-support-v2-0-0db27b4be95a@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNwQqDMBBEf6XsuVuStRjoqf9RPKxrqgvWSGJFE
 f+9qdBjj2+GebNB8lF9gttpg+hnTRqGDHQ+gXQ8tB61yQxkqDSWSuRFsWFBWaVXwfQexxAnZFM
 6sjV5axzk8Rj9U5dD/Kgyd5qmENfjZ7bf9Kd0/5SzRYN1Qbnia12Iu/PAfWgvEl5Q7fv+AZqi+
 fi9AAAA
X-Change-ID: 20260126-axi-dac-cyclic-support-a06721b2e107
To: dmaengine@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, Vinod Koul <vkoul@kernel.org>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772533501; l=3322;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=5w7fBeke7v9YYNTBIFpMrarSRv6BPkQaYufv7XgHXE4=;
 b=g5QOgICB0KLtNVxTU1Y5x8hfqCLCgIjbdQQj2lvERSzwC0fZju40o+ffVvvq+AsuX9RKMhnSk
 YlXEB1BtZvYBKZv/NIJFFexBBcNebXTeCYuemeHGt6+tMvUDFVDOUa1
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

Frank, I opted to not go with your style suggestion for axi_dmac_get_next_desc()
given that it seems to boil down to preference preference (there's no
80 col limit cross) and I do have a slight preference for the current
style. So, unless Vinod jumps in with some preference, I would prefer to
keep it.

Another meaningful change is that ADI hdl team will start to use
semantic versioning for the hdl cores [2]. So increasing the minor number to
6 will lead to 4.6.0 instead of 4.6.a.

[1]: https://lore.kernel.org/dmaengine/ZhJW9JEqN2wrejvC@matsya/
[2]: https://github.com/analogdevicesinc/hdl/pull/1831

---
Changes in v2:
- All patches but 1:
  * Be consistent with git subject.
- Patch 4:
  * Refactor commit message to avoid "we".
- Patch 5:
  * Use semantic versioning for the condition detecting
    hw_cyclic_hotfix. 
- Link to v1: https://lore.kernel.org/r/20260127-axi-dac-cyclic-support-v1-0-b32daca4b3c7@analog.com

---
Nuno Sá (5):
      dmaengine: Document cyclic transfer for dmaengine_prep_peripheral_dma_vec()
      dmaengine: dma-axi-dmac: Add cyclic transfers in .device_prep_peripheral_dma_vec()
      dmaengine: dma-axi-dmac: Add helper for getting next desc
      dmaengine: dma-axi-dmac: Gracefully terminate SW cyclic transfers
      dmaengine: dma-axi-dmac: Gracefully terminate HW cyclic transfers

 drivers/dma/dma-axi-dmac.c | 170 +++++++++++++++++++++++++++++++++++++++------
 include/linux/dmaengine.h  |   3 +-
 2 files changed, 151 insertions(+), 22 deletions(-)
---
base-commit: c8e9b1d9febc83ee94944695a07cfd40a1b29743
change-id: 20260126-axi-dac-cyclic-support-a06721b2e107
--

Thanks!
- Nuno Sá

