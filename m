From: Austin <austin.schlegel@arthrex.com>
Date: Thu, 01 Oct 2026 15:04:01 -0400
Subject: [PATCH 1/2] serial: tegra: fix RX DMA descriptor use-after-free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261001-tty-linus-v1-1-ecb8576c802d@arthrex.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790881447; l=3441;
 i=austin.schlegel@arthrex.com; s=20261001; h=from:subject:message-id;
 bh=a9gypNE0mfJajV1X659vToaTbA9I6csWkcB59J0acgg=;
 b=NHY/qyiZCnI2p/6hilX93ug+DeIeZfdFNQDqiIFayTGjlr0q4nmpfuue1k2bc2ZmzTORf/cue
 918vfPVMyU2DUCqwXO2Sl8PHl/VgtDM+vxZowjk9mhQkGgzRycpXV2u
X-Developer-Key: i=austin.schlegel@arthrex.com; a=ed25519;
 pk=IGtNH5dFuS24wm8/+OsmhjREhHB9V7zR8eOgh3sZo3s=
X-Endpoint-Received: by B4 Relay for austin.schlegel@arthrex.com/20261001 with auth_id=1096
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_uart_terminate_rx_dma() calls dmaengine_terminate_all() and then
tegra_uart_rx_buffer_push(), which calls async_tx_ack(tup->rx_dma_desc)
on the just-terminated descriptor. With the GPC DMA driver,
dmaengine_terminate_all() frees the active descriptor immediately, so
the subsequent async_tx_ack() touches freed memory. dmaengine clients
are not allowed to touch a descriptor once it has been terminated.

The same freed-descriptor access happens via tegra_uart_rx_dma_complete(),
which also reaches tegra_uart_rx_buffer_push() after RX has stopped.

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

Soak tested on Tegra234 (Jetson AGX Orin) for 13+ hours with
kfence.sample_interval=1 and continuous UART loopback traffic: zero
KFENCE reports, tx/rx byte counts in /proc/tty/driver/tegra_hsuart
remained equal throughout with no framing or break errors.

Fixes: b31245b94207 ("serial: tegra: ack the rx dma desc after transfer terminated")
Signed-off-by: Austin <austin.schlegel@arthrex.com>
---
 drivers/tty/serial/serial-tegra.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index 8004fc00fb9c..c9ec633e7164 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -716,7 +716,6 @@ static void tegra_uart_rx_buffer_push(struct tegra_uart_port *tup,
 	struct tty_port *port = &tup->uport.state->port;
 	unsigned int count;
 
-	async_tx_ack(tup->rx_dma_desc);
 	count = tup->rx_bytes_requested - residue;
 
 	/* If we are here, DMA is stopped */
@@ -747,6 +746,7 @@ static void tegra_uart_rx_dma_complete(void *args)
 		set_rts(tup, false);
 
 	tup->rx_dma_active = false;
+	async_tx_ack(tup->rx_dma_desc);
 	tegra_uart_rx_buffer_push(tup, 0);
 	tegra_uart_start_rx_dma(tup);
 
@@ -769,6 +769,7 @@ static void tegra_uart_terminate_rx_dma(struct tegra_uart_port *tup)
 
 	dmaengine_pause(tup->rx_dma_chan);
 	dmaengine_tx_status(tup->rx_dma_chan, tup->rx_cookie, &state);
+	async_tx_ack(tup->rx_dma_desc);
 	dmaengine_terminate_all(tup->rx_dma_chan);
 
 	tegra_uart_rx_buffer_push(tup, state.residue);

-- 
2.53.0

