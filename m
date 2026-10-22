From: "Jeff C. Jensen" <kernel@nullptr.com>
Subject: [PATCH 0/5] dmaengine: xilinx_dma: Fix AXI DMA descriptor ring
 ordering and failed resets
Date: Thu, 22 Oct 2026 15:11:29 -0700
Message-Id: <20261022-xilinx-dma-work-v1-0-20faea2e7a80@nullptr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABKK2moC/yXM0QrCMAyF4VcZuTa4BnXiq8gusjXdgtpKCloYe
 3c7d/nBOf8CWUwlw61ZwOSjWVOscIcGxpnjJKi+Gqili2uJsOhTY0H/Yvwme+ApUGDfXTvvzlB
 fb5Og5V+899UDZ8HBOI7z1kmmk8bjPlnXH1n7ociAAAAA
To: Vinod Koul <vkoul@kernel.org>, dmaengine@vger.kernel.org
Cc: Frank Li <Frank.Li@kernel.org>, Michal Simek <michal.simek@amd.com>, 
 Suraj Gupta <suraj.gupta2@amd.com>, 
 Radhey Shyam Pandey <radhey.shyam.pandey@amd.com>, 
 Alex Bereza <alex@bereza.email>, 
 Folker Schwesinger <dev@folker-schwesinger.de>, 
 Tomi Valkeinen <tomi.valkeinen@ideasonboard.com>, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 "Jeff C. Jensen" <kernel@nullptr.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=6127; i=kernel@nullptr.com;
 s=openpgp-2026; h=from:subject:message-id;
 bh=eGGG8wA+y+NtY4UpiQBnKJPCNIOzsy4/k4haVJRR+vg=;
 b=owGbwMvMwCV2439B4wpuQQ7G02pJDFm3ugIOXgh746050+f73oYjm/9fdrt91KDubDL7Pafqk
 mt5nA/edJSyMIhxMciKKbIcPzZtZ76tf11R9f0qmDmsTCBDGLg4BWAiHl8Z/sdvLC39uerD+rpJ
 Zk4h+Y8WFMzp3ZzPJv70+IGKbbXiR04w/NOol1vfs2YXRyS/vvFWfY7dzmr+y6JZ2v4ly0RJ7nS
 Zyw8A
X-Developer-Key: i=kernel@nullptr.com; a=openpgp;
 fpr=C7C696B96F3D4F7E727BDF7AD8FF7081A80B1108
X-Endpoint-Received: by B4 Relay for kernel@nullptr.com/openpgp-2026 with auth_id=1265
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes descriptor handling problems in the AXI DMA driver
that I ran into while streaming from programmable logic into a single
S2MM channel on a Zynq-7020.

Patches 1-4 are fixes. Patch 5 is an RFC and is not meant to be applied
with them; patches 1-4 do not depend on it.

Patches 1 and 2 are small fixes to the preparation paths. A transfer
whose entries are all zero length built a descriptor with no segments,
and the cyclic period count could be truncated on 64-bit builds.

Patch 3 is the main change. The driver hands out segments from a free
list, while the engine follows the descriptor ring in pool order, so the
two must stay in step. Commit cee9c863ee68 fixed one way they drift
apart. The Sashiko review of that commit [1] pointed out three more, and
patch 3 removes them all by allocating consecutive ring positions
instead of free list entries.

Patch 4 handles a reset that does not complete. Today the terminate path
frees the descriptors anyway, although the engine may still be using
them. With this patch the engine is withheld instead: its channels keep
their descriptors and take no new work.

Patch 5 lets a withheld channel recover: the next terminate resets the
engine, and synchronize reclaims the descriptors once the completion
tasklet has been killed. My question for this RFC is whether a completed
engine reset, followed by synchronize, is an acceptable point to reclaim
the descriptors of a withheld channel, given that the driver instance
manages no other channel of that engine.

The series is based on v7.3-rc4, the dmaengine fixes branch at
93f51579e7df, and builds on cee9c863ee68 and 7ed1e3070c9b, both of which
are in v7.3-rc4.

Testing
=======

Every patch builds for arm (multi_v7_defconfig) and arm64 (defconfig),
with the driver built in and as a module, with W=1 and sparse, and
passes checkpatch --strict. I tested the series on hardware as a
backport to the AMD vendor kernel, described below; the patches as
posted, against v7.3-rc4, are build-tested only.

The backport ran on the AMD 6.12.40 vendor kernel together with
aa99c4d1d63b, cee9c863ee68 and 7ed1e3070c9b, on a Zynq-7020 with one AXI
DMA v7.1 S2MM channel: scatter-gather, 32-bit, no DRE and the
512-segment pool. The vendor kernel has no dma_vec path and lacks
607869003479, so the dma_vec path and the transfer chaining that commit
adds are build-tested only with these changes.

 - A test client streamed 640128-byte packets at 80 per second from a
   pattern generator, refilled the channel from the completion callback
   and from a thread on the other CPU, and checked every sample. Two 60
   s runs passed, each running out of segments about 15000 times. Cases
   for pool capacity, a zero-length scatterlist, the buffer-length
   boundary and cyclic followed by slave-sg also passed.

 - Our production client streamed nine sessions, more than 160000
   packets, with every sample checked on the receiving host.

 - Failed resets were injected with fail_function on
   xilinx_dma_chan_reset(), through an ALLOW_ERROR_INJECTION() added for
   the test only. Withholding after one and two failed resets, an
   asynchronous terminate, 20 withhold and recover cycles, a failed
   recovery and streaming after recovery all passed, and a withheld
   channel released by its client kept its memory and refused the next
   allocation. The halt before each skipped reset completed, so this
   tests the state handling of patches 4 and 5 with a stopped engine,
   not an engine that cannot be stopped.

To reproduce what patch 3 fixes: without the series, the test client ran
for 10 minutes without an error, both on the vendor kernel with the
three backports and on the vendor kernel with aa99c4d1d63b alone. The
windows are small, so I added a test-only 500 us busy-wait between the
completion callback and the free in xilinx_dma_chan_desc_cleanup(). The
test client terminates the channel once at the start of each run while
packets keep arriving. On the vendor kernel with the backports, all
three 20 s runs failed, one with a DMA internal error and two with the
channel stalled. With patches 1-3 added, the same three runs passed, and
so did one with a 2000 us busy-wait. I could not reproduce the
partial-preparation case: the test client serializes its preparations
against its own callback, which leaves that window open only between the
callback and the free.

Not tested: MM2S, two-channel controllers, CDMA, VDMA and MCDMA, and an
engine that really cannot be stopped.

Known limitations
=================

 - The AXI MCDMA pool keeps its free list, so the terminate and
   partial-preparation problems remain there. My design does not use AXI
   MCDMA, and I did not test it. Extending the reservation to MCDMA
   would be possible future work.

 - xilinx_vdma_channel_set_config() with .reset set reports a failed
   reset without withholding the engine. A terminate that follows resets
   again, and withholds the engine if that reset fails too.

 - The other two issues in the Sashiko review, the chan->terminating
   race with submit and dma_run_dependencies() under chan->lock, are not
   addressed here.

This series was developed with the help of Claude Code, an LLM coding
assistant; I reviewed all of the code and text.

[1] https://lore.kernel.org/all/20260817094004.A74621F000E9@smtp.kernel.org/

---
Jeff C. Jensen (5):
      dmaengine: xilinx_dma: Reject transfers that map no data
      dmaengine: xilinx_dma: Fix cyclic period count truncation
      dmaengine: xilinx_dma: Allocate AXI DMA segments in ring order
      dmaengine: xilinx_dma: Withhold an AXI DMA engine whose reset did not complete
      dmaengine: xilinx_dma: Recover a withheld AXI DMA channel

 drivers/dma/xilinx/xilinx_dma.c | 533 +++++++++++++++++++++++++++++++++++-----
 1 file changed, 466 insertions(+), 67 deletions(-)
---
base-commit: 93f51579e7df248780214094418f205253383cc5
change-id: 20261022-xilinx-dma-work-4f2fad787d15

Best regards,
-- 
Jeff C. Jensen <kernel@nullptr.com>

