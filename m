From: Austin Schlegel <schlegelas@outlook.com>
Date: Thu, 22 Oct 2026 17:10:25 -0400
Subject: [PATCH v3 2/3] serial: tegra: fix TX DMA descriptor use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-serial-tegra-dma-uaf-v3-2-129f6d67f673@outlook.com>
References: <20261022-serial-tegra-dma-uaf-v3-0-129f6d67f673@outlook.com>
In-Reply-To: <20261022-serial-tegra-dma-uaf-v3-0-129f6d67f673@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792703432; l=3749;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=E1KIGpMCN0NqKhQC503EJ//NG4Rqh9bWOmc0ND6MkLQ=;
 b=8FBZr+mxrPqSGlbtRQAqZjOOVYVmx2tgifR6ngSG685uH8QOsh+zjLPOTbXUDlfWxzHCr9c0V
 HC9FZNVDe1dB2vCNN5N0ehbMMe2qlKLMuIrXIWN0H/WrBD2XXTo5Ny7
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_uart_stop_tx() calls dmaengine_terminate_all() and then
async_tx_ack(tup->tx_dma_desc) on the descriptor that was just
terminated. With the GPC DMA driver, dmaengine_terminate_all() frees
the active descriptor immediately, so the ack call that follows
touches freed memory.

This is the same use-after-free pattern fixed for the RX path in
tegra_uart_terminate_rx_dma() ("serial: tegra: fix RX DMA descriptor
use-after-free"). dmaengine clients must not touch a descriptor once
dmaengine_terminate_all() has returned.

Move the ack before dmaengine_terminate_all(), while the descriptor
is still valid.

tegra_uart_flush_buffer() reaches the same freed descriptor by another
route. It terminates the TX channel but leaves tx_in_progress set to
TEGRA_UART_TX_DMA, so a later tegra_uart_stop_tx() still sees a DMA
transfer in flight and acks the descriptor that
dmaengine_terminate_all() freed. Ack the descriptor before terminating
there too, and clear tx_in_progress so that nothing touches it
afterwards. Only clear it for a DMA transfer: a PIO transfer still has
the THRI interrupt enabled and is finished by the ISR.

Acking before terminating keeps descriptors reusable on APB DMA, which
only recycles a descriptor once it has been acked.

Found by code inspection while fixing the analogous RX bug and through
Sashiko automated review (see Link below); not reproduced on hardware,
since triggering it requires stopping or flushing an in-flight TX DMA
transfer at the right moment.

The ordering has been wrong since the driver was added; it became a
use-after-free once serial-tegra could use the GPC DMA driver,
which frees descriptors on terminate.

Fixes: e9ea096dd225 ("serial: tegra: add serial driver")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/sashiko-outbox-172211@kernel.org/
Assisted-by: LLM
Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
v3:
 - Also fix tegra_uart_flush_buffer(), which terminated the TX channel
   without clearing tx_in_progress, so a later tegra_uart_stop_tx()
   acked the freed descriptor (reported by Sashiko review of v2
   https://lore.kernel.org/all/sashiko-outbox-172211@kernel.org/).
 - The tegra_uart_tx_dma_complete() race reported in the same review
   is fixed separately in new patch 3/3.

v2:
 - Reworded commit: Removed inaccurate flush example
 - Switched to personal email (v1 sent from austin.schlegel@arthrex.com)

v1: https://lore.kernel.org/all/20261001-tty-linus-v1-2-ecb8576c802d@arthrex.com/
---
 drivers/tty/serial/serial-tegra.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index a23a92cebe0d..c179a09b8fe2 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -639,9 +639,9 @@ static void tegra_uart_stop_tx(struct uart_port *u)
 
 	dmaengine_pause(tup->tx_dma_chan);
 	dmaengine_tx_status(tup->tx_dma_chan, tup->tx_cookie, &state);
+	async_tx_ack(tup->tx_dma_desc);
 	dmaengine_terminate_all(tup->tx_dma_chan);
 	count = tup->tx_bytes_requested - state.residue;
-	async_tx_ack(tup->tx_dma_desc);
 	uart_xmit_advance(&tup->uport, count);
 	tup->tx_in_progress = 0;
 }
@@ -1275,8 +1275,14 @@ static void tegra_uart_flush_buffer(struct uart_port *u)
 	struct tegra_uart_port *tup = to_tegra_uport(u);
 
 	tup->tx_bytes = 0;
-	if (tup->tx_dma_chan)
+	if (tup->tx_dma_chan) {
+		if (tup->tx_in_progress == TEGRA_UART_TX_DMA) {
+			async_tx_ack(tup->tx_dma_desc);
+			tup->tx_in_progress = 0;
+		}
+
 		dmaengine_terminate_all(tup->tx_dma_chan);
+	}
 }
 
 static void tegra_uart_shutdown(struct uart_port *u)

-- 
2.53.0

