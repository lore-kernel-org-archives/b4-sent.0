From: Austin Schlegel <schlegelas@outlook.com>
Date: Wed, 14 Oct 2026 23:30:01 -0400
Subject: [PATCH v2 2/2] serial: tegra: fix TX DMA descriptor use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-serial-tegra-dma-uaf-v2-2-b142b31b67e3@outlook.com>
References: <20261014-serial-tegra-dma-uaf-v2-0-b142b31b67e3@outlook.com>
In-Reply-To: <20261014-serial-tegra-dma-uaf-v2-0-b142b31b67e3@outlook.com>
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, Austin Schlegel <austin.schlegel@arthrex.com>, 
 Austin Schlegel <schlegelas@outlook.com>, stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792035000; l=2167;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=1rmzYHaRgOYHPq/n3d0+QHrr9+Anehm1RKT/x2oyhLw=;
 b=VyrKW3991vxpqEQIG7mJvzxRJF+Hhv7+XFExLgZz8TPd9ZS2XFflhfd/9iyIWYkR3VSfWD3Zg
 ztNHhv2PWxmDQP974e6dPfHfymcRyfsgD3gvSJ4Y0E6AewmDBb8op7G
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
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
in-flight TX DMA transfer at the right moment. The RX and TX
paths share the same dmaengine_terminate_all()-then-ack structure
and the same root cause.

Fixes: e9ea096dd225 ("serial: tegra: add serial driver")
Assisted-by: LLM
Cc: stable@vger.kernel.org
Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
v2:
 - Reworded commit: Removed inaccurate flush example
 - Switched to personal email (v1 sent from austin.schlegel@arthrex.com)

v1: https://lore.kernel.org/all/20261001-tty-linus-v1-2-ecb8576c802d@arthrex.com/
---
 drivers/tty/serial/serial-tegra.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index a23a92cebe0d..306a38b2fb1e 100644
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

-- 
2.53.0

