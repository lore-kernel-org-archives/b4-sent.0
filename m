From: Austin Schlegel <schlegelas@outlook.com>
Date: Wed, 14 Oct 2026 23:30:00 -0400
Subject: [PATCH v2 1/2] serial: tegra: fix RX DMA descriptor use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261014-serial-tegra-dma-uaf-v2-1-b142b31b67e3@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792035000; l=3717;
 i=schlegelas@outlook.com; s=20261001; h=from:subject:message-id;
 bh=fYkOZsjdfbB9egxPKKzaQM+qpHDgDOAl27fV27CupX8=;
 b=IoNoP3r+ucITznuye+bvYZ3A/W7YVPQOJPLQTseNhvh5sObPgXcBtFUR0l097EDtLIFKWslBn
 omuQC/EbTDJDlvlk3ZjzEGXHNaR1c+dhehcnRNNjFpIIe0woNLU675B
X-Developer-Key: i=schlegelas@outlook.com; a=ed25519;
 pk=ddgmH7VQaSWderjJFy4hDyq+P7hdHupPxQvwnGRBzCs=
X-Endpoint-Received: by B4 Relay for schlegelas@outlook.com/20261001 with auth_id=1098
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_uart_terminate_rx_dma() calls dmaengine_terminate_all() and then
tegra_uart_rx_buffer_push(), which calls async_tx_ack(tup->rx_dma_desc)
on the just-terminated descriptor. With the GPC DMA driver,
dmaengine_terminate_all() frees the active descriptor immediately, so
the subsequent async_tx_ack() touches freed memory. dmaengine clients
are not allowed to touch a descriptor once it has been terminated.

Move the ack into the two call sites that still own a live descriptor:
tegra_uart_rx_dma_complete() (before the completion callback hands the
descriptor back) and tegra_uart_terminate_rx_dma() (before terminating),
and drop it from tegra_uart_rx_buffer_push() itself, since that function
no longer has a descriptor it's safe to ack.

The ack was originally added in commit b31245b94207 ("serial: tegra:
ack the rx dma desc after transfer terminated") to avoid a descriptor
leak with the Tegra20 APB DMA driver. Keep that fix intact: the ack
still happens for every terminated RX transfer, just before the
descriptor is freed instead of after.

Found by inspection while chasing the KFENCE report below on a Jetson
AGX Orin (Tegra234) with UART loopback:

BUG: KFENCE: use-after-free read in tegra_uart_rx_buffer_push+0x38/0x168
 tegra_uart_rx_buffer_push+0x38/0x168
 tegra_uart_terminate_rx_dma+0x88/0xf8
 tegra_uart_isr+0x380/0x470

allocated by task 0 on cpu 0 (~9 ms earlier):
 tegra_dma_prep_slave_sg+0x134/0x3c0
 tegra_uart_start_rx_dma.isra.0+0xc4/0x138
 tegra_uart_isr+0x340/0x470

freed by task 0 on cpu 0:
 tegra_dma_desc_free+0x1c/0x30
 vchan_dma_desc_free_list+0x10c/0x160
 tegra_dma_terminate_all+0x21c/0x290
 tegra_uart_terminate_rx_dma+0x7c/0xf8

Soak tested on Tegra234 (Jetson AGX Orin) for 24+ hours with
kfence.sample_interval=1 and continuous UART loopback traffic: zero
KFENCE reports, tx/rx byte counts in /proc/tty/driver/tegra_hsuart
remained equal throughout with no framing or break errors.

Fixes: b31245b94207 ("serial: tegra: ack the rx dma desc after transfer terminated")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Austin Schlegel <schlegelas@outlook.com>
---
v2:
 - Reworded commit: Removed inaccurate statement claiming the freed-descriptor is accessed
   in tegra_uart_rx_dma_complete().
 - Reworded commit: Soak test ran for 24+ hours, so updated from 13 to 24.
 - Switched to personal email (v1 sent from austin.schlegel@arthrex.com)

v1: https://lore.kernel.org/all/20261001-tty-linus-v1-1-ecb8576c802d@arthrex.com/
---
 drivers/tty/serial/serial-tegra.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index b0fc4ae3686f..a23a92cebe0d 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -730,7 +730,6 @@ static void tegra_uart_rx_buffer_push(struct tegra_uart_port *tup,
 	struct tty_port *port = &tup->uport.state->port;
 	unsigned int count;
 
-	async_tx_ack(tup->rx_dma_desc);
 	count = tup->rx_bytes_requested - residue;
 
 	/* If we are here, DMA is stopped */
@@ -761,6 +760,7 @@ static void tegra_uart_rx_dma_complete(void *args)
 		set_rts(tup, false);
 
 	tup->rx_dma_active = false;
+	async_tx_ack(tup->rx_dma_desc);
 	tegra_uart_rx_buffer_push(tup, 0);
 	tegra_uart_start_rx_dma(tup);
 
@@ -783,6 +783,7 @@ static void tegra_uart_terminate_rx_dma(struct tegra_uart_port *tup)
 
 	dmaengine_pause(tup->rx_dma_chan);
 	dmaengine_tx_status(tup->rx_dma_chan, tup->rx_cookie, &state);
+	async_tx_ack(tup->rx_dma_desc);
 	dmaengine_terminate_all(tup->rx_dma_chan);
 
 	tegra_uart_rx_buffer_push(tup, state.residue);

-- 
2.53.0

