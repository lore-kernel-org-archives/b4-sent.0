From: Austin Schlegel <schlegelas@outlook.com>
Subject: [PATCH v3 0/3] serial: tegra: fix DMA descriptor use-after-free
 and stale completions
Date: Thu, 22 Oct 2026 17:10:23 -0400
Message-Id: <20261022-serial-tegra-dma-uaf-v3-0-129f6d67f673@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6DIBSEr2Leuq/hx2DaVe/RuAB5KqlKA0raG
 O5e9AJdfpOZb3aIFBxFuFc7BEouOr8UkJcKulEvA6GzhUEwoTjjNR59PeFKQ9BoZ42b7lHeyCr
 RMK6NgjJ9B+rd59Q+28Kji6sP3/MliSP9I0wCGRpeCyO5UQ3Jh9/WyfvXtfMztDnnH8fhk8y6A
 AAA
X-Change-ID: 20261014-serial-tegra-dma-uaf-39ed62701ab6
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Alan Cox <alan@linux.intel.com>, 
 Stephen Warren <swarren@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Austin Schlegel <austin.schlegel@arthrex.com>, 
 Austin Schlegel <schlegelas@outlook.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792703432; l=3329;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=2u6x42Zc4M/sCENwrwvS9ZYmDV6qxlXnokQ8LOPtSWw=;
 b=9J9PKfD7iRpIx6qLoMhEbfERW7lDm6JDuJNkioe31lVgZrA5KLKeoMNdv/ynkNWJB1BQfWo8c
 oAJOWDjkH9NCxqWeHmfmNb3QxOvDs8tsij0WCIyNu4TznQQTE2tW7Tk
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Patches 1 and 2 fix the same bug pattern in
drivers/tty/serial/serial-tegra.c: async_tx_ack() is called on a DMA
descriptor after dmaengine_terminate_all() has terminated it. With the
GPC DMA driver (tegra186-gpc-dma.c, used on Tegra186 and later),
terminating a channel frees the active descriptor synchronously via
vchan_dma_desc_free_list(), so the ack touches freed memory. dmaengine
clients are not allowed to touch a descriptor once it has been
terminated.

Patch 1 (RX) was found via a KFENCE use-after-free report on a Jetson
AGX Orin (Tegra234) under UART loopback traffic. It keeps the
descriptor-leak fix from commit b31245b94207 ("serial: tegra: ack the
rx dma desc after transfer terminated") intact: the ack still happens
for every terminated RX transfer, just before the descriptor is freed
instead of after.

Patch 2 (TX) fixes the same ordering bug in tegra_uart_stop_tx().
It also fixes tegra_uart_flush_buffer(), which terminated the TX
channel without clearing tx_in_progress, so a later
tegra_uart_stop_tx() acked the freed descriptor.

Patch 3 is new in v3. It makes the TX and RX DMA completion callbacks
return early when the transfer they were raised for has already been
stopped, flushed or terminated, instead of accounting for it a second
time.

The bugs fixed by patches 2 and 3 were found in review (Sashiko, on v2)
and have not been reproduced on hardware. In a 10-minute loopback test
with KFENCE sampling every 1 ms, which also stops and flushes TX during
DMA, the unfixed kernel produced 1635 use-after-free KFENCE
errors, all from RX. With this patch series applied there were none.

Testing was done on Tegra234 (Jetson AGX Orin) with GPC DMA only. The
APB DMA driver (Tegra20-Tegra210) recycles descriptors only after they
are acked; the series keeps every ack but has not been tested there.

Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
Changes in v3:
- Patch 2: also fix tegra_uart_flush_buffer(), which left
  tx_in_progress set after terminating TX DMA (Sashiko review).
- New patch 3: ignore TX/RX DMA completion callbacks for transfers that
  were already stopped or terminated (Sashiko review).
- Patch 1: no code changes.
- Link to v2: https://lore.kernel.org/r/20261014-serial-tegra-dma-uaf-v2-0-b142b31b67e3@outlook.com

Changes in v2:
- Commit message updates only; no code changes.
- Patch 1: removed an inaccurate statement that the freed descriptor
  is accessed in tegra_uart_rx_dma_complete(); updated the soak test
  duration to 24+ hours.
- Patch 2: removed an inaccurate flush example; added Fixes: tag.
- Switched to my personal email address (v1 was sent from
  austin.schlegel@arthrex.com).
- Link to v1: https://lore.kernel.org/r/20261001-tty-linus-v1-0-ecb8576c802d@arthrex.com

---
Austin Schlegel (3):
      serial: tegra: fix RX DMA descriptor use-after-free
      serial: tegra: fix TX DMA descriptor use-after-free
      serial: tegra: ignore stale DMA completion callbacks

 drivers/tty/serial/serial-tegra.c | 56 +++++++++++++++++++++++++++++++++++----
 1 file changed, 51 insertions(+), 5 deletions(-)
---
base-commit: a90ee4305c4a5df72c11b31dacfdc76e00fcf78a
change-id: 20261014-serial-tegra-dma-uaf-39ed62701ab6

Best regards,
-- 
Austin Schlegel <schlegelas@outlook.com>

