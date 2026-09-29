From: Chris Strong <chris.strong@flocksafety.com>
Date: Tue, 29 Sep 2026 11:35:01 -0400
Subject: [PATCH net v2 1/2] can: rx-offload: add IRQ queue flush predicate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-upstream-can-rx-offload-batching-v2-1-3b587c519f5d@flocksafety.com>
References: <20260929-upstream-can-rx-offload-batching-v2-0-3b587c519f5d@flocksafety.com>
In-Reply-To: <20260929-upstream-can-rx-offload-batching-v2-0-3b587c519f5d@flocksafety.com>
To: Marc Kleine-Budde <mkl@pengutronix.de>, 
 Vincent Mailhol <mailhol@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Thomas Kopp <thomas.kopp@microchip.com>
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chris Strong <chris.strong@flocksafety.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790696109; l=1321;
 i=chris.strong@flocksafety.com; s=flock-workstation;
 h=from:subject:message-id; bh=QTrXEykdZqhdnMZDN6EuT4udd2059pFwyS2sp8cy81A=;
 b=7KUGkgsxVKmAsKHjJqIG0y2nwS7PbG4PGdycE0YPk7BGX7ro96+RWJlPPDbrwC6m2UvbDEjgz
 7GCjvhX9v3kAXXdhlAbKpUU1Pq7huULOGvcVjqsyANJgE7Nu6vx9p8x
X-Developer-Key: i=chris.strong@flocksafety.com; a=ed25519;
 pk=IaEYd0fwBUeOKjqZzp2UKZY1tn3CLcPh6JpOKznZyRE=
X-Endpoint-Received: by B4 Relay for chris.strong@flocksafety.com/flock-workstation with auth_id=1045
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Drivers that queue received SKBs from a threaded interrupt may need to
publish a partial batch before the handler returns. The existing overflow
check covers only the NAPI-visible queue after the IRQ-local queue has
been spliced, so it cannot guide that decision.

Add can_rx_offload_irq_queue_needs_flush() to report when the IRQ-local
queue reaches the NAPI poll weight. Keep the query separate from the
flush operation so callers can finish processing related interrupt
sources before publishing the batch.

Assisted-by: LLM
Signed-off-by: Chris Strong <chris.strong@flocksafety.com>
---
 include/linux/can/rx-offload.h | 7 +++++++
 1 file changed, 7 insertions(+)

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

-- 
2.43.0

