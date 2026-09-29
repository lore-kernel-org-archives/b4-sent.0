From: Chris Strong <chris.strong@flocksafety.com>
Date: Tue, 29 Sep 2026 11:35:02 -0400
Subject: [PATCH net v2 2/2] can: mcp251xfd: flush RX offload queue during
 long IRQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-upstream-can-rx-offload-batching-v2-2-3b587c519f5d@flocksafety.com>
References: <20260929-upstream-can-rx-offload-batching-v2-0-3b587c519f5d@flocksafety.com>
In-Reply-To: <20260929-upstream-can-rx-offload-batching-v2-0-3b587c519f5d@flocksafety.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thomas Kopp <thomas.kopp@microchip.com>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chris Strong <chris.strong@flocksafety.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790696109; l=2363;
 i=chris.strong@flocksafety.com; s=flock-workstation;
 h=from:subject:message-id; bh=Irg7Hh/rvvN2ZObBa7XWor4c8mF34tGo8/fv+q/HTp4=;
 b=3CqhrRsFq8VMT7W+g6O72MKf23v3bAJnQUYsrntLTjq3NGoHzf9u3IhG1UDHuS4Sk1OT4y841
 j0cDFcdJ2JZBjR32/0nE1TRJ4bw1wVuGIJDGmlAIJxY0NtDU0t4jfW+
X-Developer-Key: i=chris.strong@flocksafety.com; a=ed25519;
 pk=IaEYd0fwBUeOKjqZzp2UKZY1tn3CLcPh6JpOKznZyRE=
X-Endpoint-Received: by B4 Relay for chris.strong@flocksafety.com/flock-workstation with auth_id=1045
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under sustained receive traffic, the threaded interrupt handler can
continue draining the controller indefinitely. Received SKBs remain in
skb_irq_queue until the handler returns, but the overflow checks inspect
the NAPI-visible skb_queue instead. The IRQ-local queue can therefore
grow without bound while NAPI remains unscheduled, potentially
exhausting memory.

Stop the dedicated RX loop when the IRQ-local queue reaches the NAPI
weight so TEF and other pending interrupts are processed before
publishing the batch. Publish further batches from the main interrupt
loop while the controller remains busy. This bounds IRQ-local
accumulation and keeps RX and TEF timestamps from each controller-status
pass in the same sort window.

Fixes: c757096ea103 ("can: rx-offload: add skb queue for use during ISR")
Assisted-by: LLM
Signed-off-by: Chris Strong <chris.strong@flocksafety.com>
---
 drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c b/drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c
index f441f2265299..d8078895b6d4 100644
--- a/drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c
+++ b/drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c
@@ -1498,8 +1498,14 @@ static irqreturn_t mcp251xfd_irq(int irq, void *dev_id)
 			/* We don't know which RX-FIFO is pending, but only
 			 * handle the 1st RX-FIFO. Leave loop here if we have
 			 * more than 1 RX-FIFO to avoid starvation.
+			 *
+			 * Once the IRQ queue reaches the NAPI weight, process
+			 * TEF and other pending interrupts before publishing
+			 * the batch, keeping RX and TEF timestamps in the same
+			 * sort window.
 			 */
-		} while (priv->rx_ring_num == 1);
+		} while (priv->rx_ring_num == 1 &&
+			 !can_rx_offload_irq_queue_needs_flush(&priv->offload));
 
 	do {
 		u32 intf_pending, intf_pending_clearable;
@@ -1615,6 +1621,12 @@ static irqreturn_t mcp251xfd_irq(int irq, void *dev_id)
 			}
 		}
 
+		/* Keep each splice into the offload queue near one NAPI poll
+		 * budget when a busy controller keeps this handler running.
+		 */
+		if (can_rx_offload_irq_queue_needs_flush(&priv->offload))
+			can_rx_offload_threaded_irq_finish(&priv->offload);
+
 		handled = IRQ_HANDLED;
 	} while (1);
 

-- 
2.43.0

