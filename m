From: Austin Schlegel <schlegelas@outlook.com>
Date: Thu, 22 Oct 2026 17:10:26 -0400
Subject: [PATCH v3 3/3] serial: tegra: ignore stale DMA completion
 callbacks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-serial-tegra-dma-uaf-v3-3-129f6d67f673@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792703432; l=5372;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=XIQgFR0YA9L/OYKz/mlqsFGtu4QcgWxRk6Z+7ffAujs=;
 b=wKx2KDmxE0HiCL165F6nbqu2ktPKd7UvBfshgOHxHmqBochQ3q8DFDXuQ0mPS5MV4U6AsBFtr
 RwaxyTKm4e4DSFlA+XBy6RM0rYILdQJ+BONGlPmJC9k9qvuWfT0HS2z
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The TX and RX DMA completion callbacks run from the DMA engine's
tasklet. tegra_uart_stop_tx(), tegra_uart_flush_buffer() and
tegra_uart_terminate_rx_dma() can stop the same transfer under the port
lock, and dmaengine_terminate_all() does not wait for a callback that
is already running. A callback can therefore be waiting on the port
lock for a transfer that the driver has already stopped and accounted
for.

tegra_uart_tx_dma_complete() reads the DMA status and acks the
descriptor before it takes the port lock, then advances the xmit FIFO
by the whole transfer and starts the next one unconditionally. If
tegra_uart_stop_tx() got there first, the bytes it already accounted
for are advanced a second time, skipping data that was never sent.
After tegra_uart_flush_buffer() the FIFO is empty and the advance runs
past it. If a new transfer was started in between, the stale callback
reads the new transfer's cookie, acks its descriptor and clears
tx_in_progress while that transfer is still running.

tegra_uart_rx_dma_complete() has the same problem: after
tegra_uart_terminate_rx_dma() has pushed the received data and cleared
rx_dma_active, the callback pushes the whole buffer again and restarts
RX DMA, even if RX has been stopped.

Take the port lock before looking at the transfer in the TX callback,
and in both callbacks return early unless the transfer is still the
driver's current one: tx_in_progress is still TEGRA_UART_TX_DMA and the
cookie is complete for TX, rx_dma_active is still set for RX. The stop
paths clear these flags under the port lock, and a transfer started
after them is normally still in progress, so the existing
DMA_IN_PROGRESS check in the RX callback and the new DMA_COMPLETE check
in the TX callback skip it. If it has already completed, the stale
callback handles it, and its own callback then finds it is no longer
current.

Found by Sashiko automated review (see Link below). Not reproduced on
hardware. Tested together with the rest of the series on Tegra234
(Jetson AGX Orin) with a UART loopback test that also stops and flushes
TX while DMA is running: no KFENCE reports and no data mismatches in a
10-minute run with kfence.sample_interval=1.

Fixes: e9ea096dd225 ("serial: tegra: add serial driver")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/all/sashiko-outbox-172211@kernel.org/
Assisted-by: LLM
Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
v3:
 - New patch, addressing the Sashiko review of v2:
   https://sashiko.dev/#/patchset/20261014-serial-tegra-dma-uaf-v2-0-b142b31b67e3@outlook.com?part=1
---
 drivers/tty/serial/serial-tegra.c | 43 +++++++++++++++++++++++++++++++++++++--
 1 file changed, 41 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index c179a09b8fe2..6e1a67d83e0e 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -532,16 +532,39 @@ static void tegra_uart_tx_dma_complete(void *args)
 	struct dma_tx_state state;
 	unsigned long flags;
 	unsigned int count;
+	enum dma_status status;
+
+	uart_port_lock_irqsave(&tup->uport, &flags);
+
+	/*
+	 * dmaengine_terminate_all() does not wait for a callback that is
+	 * already running. If tegra_uart_stop_tx() or
+	 * tegra_uart_flush_buffer() stopped this transfer while we were
+	 * waiting for the port lock, they have already handled it and
+	 * cleared tx_in_progress, so there is nothing left to do.
+	 */
+	if (tup->tx_in_progress != TEGRA_UART_TX_DMA)
+		goto out;
+
+	/*
+	 * A new transfer may have been started after this one was stopped.
+	 * Its cookie is normally still in progress, so leave it to its own
+	 * callback. If it has already completed, handling it here is fine:
+	 * its own callback will then find it is no longer current.
+	 */
+	status = dmaengine_tx_status(tup->tx_dma_chan, tup->tx_cookie, &state);
+	if (status != DMA_COMPLETE)
+		goto out;
 
-	dmaengine_tx_status(tup->tx_dma_chan, tup->tx_cookie, &state);
 	count = tup->tx_bytes_requested - state.residue;
 	async_tx_ack(tup->tx_dma_desc);
-	uart_port_lock_irqsave(&tup->uport, &flags);
 	uart_xmit_advance(&tup->uport, count);
 	tup->tx_in_progress = 0;
 	if (kfifo_len(&tport->xmit_fifo) < WAKEUP_CHARS)
 		uart_write_wakeup(&tup->uport);
 	tegra_uart_start_next_tx(tup);
+
+out:
 	uart_port_unlock_irqrestore(&tup->uport, flags);
 }
 
@@ -748,6 +771,22 @@ static void tegra_uart_rx_dma_complete(void *args)
 
 	uart_port_lock_irqsave(u, &flags);
 
+	/*
+	 * dmaengine_terminate_all() does not wait for a callback that is
+	 * already running. If tegra_uart_terminate_rx_dma() stopped this
+	 * transfer while we were waiting for the port lock, it has already
+	 * pushed the received data and cleared rx_dma_active, so there is
+	 * nothing left to do.
+	 */
+	if (!tup->rx_dma_active)
+		goto done;
+
+	/*
+	 * A new transfer may have been started after this one was stopped.
+	 * Its cookie is normally still in progress, so leave it to its own
+	 * callback. If it has already completed, handling it here is fine:
+	 * its own callback will then find it is no longer current.
+	 */
 	status = dmaengine_tx_status(tup->rx_dma_chan, tup->rx_cookie, &state);
 
 	if (status == DMA_IN_PROGRESS) {

-- 
2.53.0

