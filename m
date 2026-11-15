From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Date: Sun, 15 Nov 2026 19:01:57 +0100
Subject: [PATCH 2/2] serial: fsl_lpuart: Enable DMA for TX in console mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-fsl_lpuart_8_bit_break_detection-v1-2-b7ac2307dd55@liebherr.com>
References: <20261115-fsl_lpuart_8_bit_break_detection-v1-0-b7ac2307dd55@liebherr.com>
In-Reply-To: <20261115-fsl_lpuart_8_bit_break_detection-v1-0-b7ac2307dd55@liebherr.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 michael@walle.cc, sherry.sun@nxp.com, 
 Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794765771; l=1112;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=zZRMKoyeC9YMN9R+VfYb8J2pz3w2Cn5KLcq4SMSFGqo=;
 b=ZrF0cygrknpH4jHd2y0FEXoyanAO02iZiHY6APb+nEpCl3hINnwKyED8EOcxFwYsC674YELSE
 x4bRmdzCd09C+sb7s3nq6jKvZFXv5GrPF4GsuX9u6mLvj1uggpvD7Pu
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the check that disabled TX DMA if the device is in console mode.

The reason for this check was that break detection cannot be efficiently
implemented with DMA. See commit 8cac2f6eb854 ("serial: fsl_lpuart:
disable DMA for console and fix sysrq").
However, break detection only affects the RX path, not the TX path.

The 8-bit LPUART hardware supports using DMA only for TX and not for RX.
I do not have a CPU with the 32-bit LPUART hardware to verify that this
change also work with the 32-bit LPUART. It probably does.

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
 drivers/tty/serial/fsl_lpuart.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/drivers/tty/serial/fsl_lpuart.c b/drivers/tty/serial/fsl_lpuart.c
index 5817c47e4db3..e569e2c6ffe9 100644
--- a/drivers/tty/serial/fsl_lpuart.c
+++ b/drivers/tty/serial/fsl_lpuart.c
@@ -1765,9 +1765,6 @@ static void lpuart_tx_dma_startup(struct lpuart_port *sport)
 	u32 uartbaud;
 	int ret;
 
-	if (uart_console(&sport->port))
-		goto err;
-
 	if (!sport->dma_tx_chan)
 		goto err;
 

-- 
2.43.0

