From: Austin <austin.schlegel@arthrex.com>
Date: Thu, 01 Oct 2026 15:04:02 -0400
Subject: [PATCH 2/2] serial: tegra: fix TX DMA descriptor use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-tty-linus-v1-2-ecb8576c802d@arthrex.com>
References: <20261001-tty-linus-v1-0-ecb8576c802d@arthrex.com>
In-Reply-To: <20261001-tty-linus-v1-0-ecb8576c802d@arthrex.com>
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Austin <austin.schlegel@arthrex.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790881447; l=1877;
 i=austin.schlegel@arthrex.com; s=20261001; h=from:subject:message-id;
 bh=EMsy9Br5xSelbXG4rnyA2/UBqNiR5fGd7V9vJ3r0J7g=;
 b=aBZdd0zi3InfuISzL706K+GAJ8ezKP7VhIrjg+LdtoLIQS24CuYoV+SzXwa0ITCY/2k9glNSj
 3XLzMXG8yO9Alh156F4Cz8d3d4kki7vrdQIYTlhE2YYs6m5yn11klgE
X-Developer-Key: i=austin.schlegel@arthrex.com; a=ed25519;
 pk=IGtNH5dFuS24wm8/+OsmhjREhHB9V7zR8eOgh3sZo3s=
X-Endpoint-Received: by B4 Relay for austin.schlegel@arthrex.com/20261001 with auth_id=1096
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_uart_stop_tx() calls dmaengine_terminate_all() and then
async_tx_ack(tup->tx_dma_desc) on the descriptor that was just
terminated. With the GPC DMA driver, dmaengine_terminate_all() frees
the active descriptor immediately, so the ack call that follows
touches freed memory, the same use-after-free pattern fixed for the
RX path in tegra_uart_terminate_rx_dma() ("serial: tegra: fix RX DMA
descriptor use-after-free"). dmaengine clients must not touch a
descriptor once dmaengine_terminate_all() has returned.

Move the ack before dmaengine_terminate_all(), while the descriptor
is still owned by the driver. tegra_uart_tx_dma_complete() already
acks inside the completion callback, where the descriptor is valid,
and is unaffected.

Found by code inspection while fixing the analogous RX bug; not
reproduced on hardware, since triggering it requires stopping an
in-flight TX DMA transfer (e.g. via a modem control line or flush)
at the right moment. The RX and TX paths share the same
dmaengine_terminate_all()-then-ack structure and the same root cause.

Signed-off-by: Austin <austin.schlegel@arthrex.com>
---
 drivers/tty/serial/serial-tegra.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index c9ec633e7164..0d1a2ebe2a59 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -625,9 +625,9 @@ static void tegra_uart_stop_tx(struct uart_port *u)
 
 	dmaengine_pause(tup->tx_dma_chan);
 	dmaengine_tx_status(tup->tx_dma_chan, tup->tx_cookie, &state);
+	async_tx_ack(tup->tx_dma_desc);
 	dmaengine_terminate_all(tup->tx_dma_chan);
 	count = tup->tx_bytes_requested - state.residue;
-	async_tx_ack(tup->tx_dma_desc);
 	uart_xmit_advance(&tup->uport, count);
 	tup->tx_in_progress = 0;
 }

-- 
2.53.0

