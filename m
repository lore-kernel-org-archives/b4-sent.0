From: Chris Strong <chris.strong@flocksafety.com>
Date: Tue, 22 Sep 2026 00:01:06 -0400
Subject: [PATCH net] can: mcp251xfd: flush RX offload queue during long
 IRQs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260922-upstream-can-rx-offload-batching-v1-1-099e7ca12c91@flocksafety.com>
X-B4-Tracking: v=1; b=H4sIAIH9sWoC/x3NwQrCMAyA4VcZORtYCxb1VcRDTNMtoOloqwzG3
 n1lx+/y/xtUKSoVHsMGRf5aNVuHuwzAM9kkqLEb/OjDePcOf0ttReiLTIZlxZzSJ1PENzWe1SY
 MfEskMbC7BuiZpUjS9Vw8waTBa98PF2oXC3cAAAA=
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thomas Kopp <thomas.kopp@microchip.com>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chris Strong <chris.strong@flocksafety.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790049670; l=4672;
 i=chris.strong@flocksafety.com; s=flock-workstation;
 h=from:subject:message-id; bh=cskt+YdEtLxQStS/fLK7DOH7XqLqAzUDgewjiKglDsY=;
 b=aHH8RjEDzUBE5vvjZ4EdcLlHCP6FyDuwoTZT4l57FsvKPzJVu1UozqYJzhIZpwqkxDXuGyo8p
 XyTYVMGslGKAncu81tSHk1QQweOMlvg0pl51QHx0bvPgWV0rZAc1wMY
X-Developer-Key: i=chris.strong@flocksafety.com; a=ed25519;
 pk=IaEYd0fwBUeOKjqZzp2UKZY1tn3CLcPh6JpOKznZyRE=
X-Endpoint-Received: by B4 Relay for chris.strong@flocksafety.com/flock-workstation with auth_id=1045
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Under sustained receive traffic, the threaded interrupt handler can
continue draining the controller indefinitely. Received SKBs accumulate
in skb_irq_queue, but can_rx_offload_threaded_irq_finish() only splices
them into the NAPI-visible skb_queue when the handler finishes.

The RX-offload overflow checks inspect skb_queue rather than
skb_irq_queue. If the handler does not return, the IRQ-local queue can
therefore grow without bound while NAPI remains unscheduled. This can
exhaust memory and prevent received frames from reaching the networking
stack.

Add a small RX-offload predicate that reports when the IRQ-local queue
has reached the NAPI weight. Use it to stop the dedicated RX interrupt
loop, process TEF and the other pending interrupt sources, and then
publish the batch. Publish additional batches from the main interrupt
loop while the controller remains busy. Since one RX pass can enqueue a
complete hardware ring, this keeps each splice near the NAPI weight
rather than enforcing a strict limit.

Keep this policy in mcp251xfd because its controller-draining loops are
the source of the unbounded handler. Accounting for skb_irq_queue in the
generic overflow check would cap memory use by dropping frames, but
would still leave NAPI unscheduled.

Publishing smaller batches narrows the timestamp sorting window.
Ordering across batches is already best-effort; RX and TEF events from
each controller-status pass are processed before the batch is published.

Fixes: c757096ea103 ("can: rx-offload: add skb queue for use during ISR")
Assisted-by: LLM
Signed-off-by: Chris Strong <chris.strong@flocksafety.com>
---
Hi all,

This is my first upstream Linux kernel patch submission, so feedback on both
the implementation and the submission format would be appreciated.

An equivalent backport was tested on a Qualcomm QRB5165 (msm-qrb5165-4.19
vendor tree, with mcp251xfd and rx-offload backported from v5.15+) driving
an MCP251863 over GENI SPI at 125 kbit/s. The system remained operational
overnight under 100% CAN bus load while receiving more than 51 million
frames.

This mainline version passes checkpatch and an x86_64 build with
MCP251XFD enabled. I don't have a setup that can run mainline with an
MCP251863, so it is build-tested only -- a hardware test would be welcome.
---
 drivers/net/can/spi/mcp251xfd/mcp251xfd-core.c | 14 +++++++++++++-
 include/linux/can/rx-offload.h                 |  7 +++++++
 2 files changed, 20 insertions(+), 1 deletion(-)

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
 
diff --git a/include/linux/can/rx-offload.h b/include/linux/can/rx-offload.h
index d29bb4521947..f9b9474f7190 100644
--- a/include/linux/can/rx-offload.h
+++ b/include/linux/can/rx-offload.h
@@ -62,4 +62,11 @@ static inline void can_rx_offload_disable(struct can_rx_offload *offload)
 	napi_disable(&offload->napi);
 }
 
+static inline bool
+can_rx_offload_irq_queue_needs_flush(const struct can_rx_offload *offload)
+{
+	/* skb_irq_queue is owned by the interrupt context queuing the SKBs. */
+	return skb_queue_len(&offload->skb_irq_queue) >= offload->napi.weight;
+}
+
 #endif /* !_CAN_RX_OFFLOAD_H */

---
base-commit: f0b88fade64c6fe52e15b246097d10bb115d8af3
change-id: 20260921-upstream-can-rx-offload-batching-6c8faed6c156

Best regards,
-- 
Chris Strong <chris.strong@flocksafety.com>

