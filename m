From: Sven Peter <sven@kernel.org>
Date: Sun, 06 Sep 2026 20:36:38 +0200
Subject: [PATCH v2 15/22] thunderbolt: Add ring_configure to tb_nhi_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-b4-apple-soc-tbt-v2-15-1f80085f93fb@kernel.org>
References: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
In-Reply-To: <20260906-b4-apple-soc-tbt-v2-0-1f80085f93fb@kernel.org>
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4518; i=sven@kernel.org;
 h=from:subject:message-id; bh=WVMy1qg0prw15BOC/1aO59pKjAwSsJirT8ivotx4wRA=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9bcTUel/SJz/2/Un5uyeW9eiMTBq65LT0XWhi1IT3r2t
 GLf3CbZjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEtk1l+Ct+wfOL91PHi7H+
 Zp9rZM/+a/WqbTqTtink5/MfFWx5eiUM/3Rjo2bNNFP4dvP0m6jyAq6sKstc5hNvGZWWHtSWTU1
 p4gEA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Apple NHI also uses a separate register range for the receive ring
PDF masks. Add an optional tb_nhi_ops hook for it which falls back to
the standard USB4 NHI method when it is not set.

For the standard method also just write E2E flow control at the same
time the rest of the configuration is written.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 drivers/thunderbolt/nhi.c | 48 +++++++++++++++++++++++++++--------------------
 drivers/thunderbolt/nhi.h |  4 ++++
 2 files changed, 32 insertions(+), 20 deletions(-)

diff --git a/drivers/thunderbolt/nhi.c b/drivers/thunderbolt/nhi.c
index 4ef86e7c0285..2d622b365c4f 100644
--- a/drivers/thunderbolt/nhi.c
+++ b/drivers/thunderbolt/nhi.c
@@ -244,6 +244,24 @@ static void ring_iowrite32options(struct tb_ring *ring, u32 value, u32 offset)
 	iowrite32(value, nhi_ring_options_base(ring) + offset);
 }
 
+static void ring_configure(struct tb_ring *ring, u32 flags, u32 e2e_flags)
+{
+	if (ring->is_tx)
+		ring_iowrite32options(ring, 0, 4);
+	else
+		ring_iowrite32options(ring, ring->sof_mask << 16 | ring->eof_mask, 4);
+
+	ring_iowrite32options(ring, flags | e2e_flags, 0);
+}
+
+static void nhi_ring_configure(struct tb_ring *ring, u32 flags, u32 e2e_flags)
+{
+	if (ring->nhi->ops->ring_configure)
+		ring->nhi->ops->ring_configure(ring, flags, e2e_flags);
+	else
+		ring_configure(ring, flags, e2e_flags);
+}
+
 static bool ring_full(struct tb_ring *ring)
 {
 	return ((ring->head + 1) % ring->size) == ring->tail;
@@ -699,6 +717,7 @@ EXPORT_SYMBOL_GPL(tb_ring_alloc_rx);
  */
 void tb_ring_start(struct tb_ring *ring)
 {
+	u32 e2e_flags = 0;
 	u16 frame_size;
 	u32 flags;
 
@@ -722,30 +741,13 @@ void tb_ring_start(struct tb_ring *ring)
 		flags = RING_FLAG_ENABLE | RING_FLAG_RAW;
 	}
 
-	ring_iowrite64desc(ring, ring->descriptors_dma, 0);
-	if (ring->is_tx) {
-		ring_iowrite32desc(ring, ring->size, 12);
-		ring_iowrite32options(ring, 0, 4);
-		ring_iowrite32options(ring, flags, 0);
-	} else {
-		u32 sof_eof_mask = ring->sof_mask << 16 | ring->eof_mask;
-
-		ring_iowrite32desc(ring, (frame_size << 16) | ring->size, 12);
-		ring_iowrite32options(ring, sof_eof_mask, 4);
-		ring_iowrite32options(ring, flags, 0);
-	}
-
-	/*
-	 * Now that the ring valid bit is set we can configure E2E if
-	 * enabled for the ring.
-	 */
 	if (ring->flags & RING_FLAG_E2E) {
 		if (!ring->is_tx) {
 			u32 hop;
 
 			hop = ring->e2e_tx_hop << REG_RX_OPTIONS_E2E_HOP_SHIFT;
 			hop &= REG_RX_OPTIONS_E2E_HOP_MASK;
-			flags |= hop;
+			e2e_flags |= hop;
 
 			dev_dbg(ring->nhi->dev,
 				"enabling E2E for %s %d with TX HopID %d\n",
@@ -755,10 +757,16 @@ void tb_ring_start(struct tb_ring *ring)
 				RING_TYPE(ring), ring->hop);
 		}
 
-		flags |= RING_FLAG_E2E_FLOW_CONTROL;
-		ring_iowrite32options(ring, flags, 0);
+		e2e_flags |= RING_FLAG_E2E_FLOW_CONTROL;
 	}
 
+	ring_iowrite64desc(ring, ring->descriptors_dma, 0);
+	if (ring->is_tx)
+		ring_iowrite32desc(ring, ring->size, 12);
+	else
+		ring_iowrite32desc(ring, (frame_size << 16) | ring->size, 12);
+	nhi_ring_configure(ring, flags, e2e_flags);
+
 	if (!(ring->flags & RING_FLAG_NO_INTERRUPT))
 		nhi_ring_interrupt_active(ring, true);
 	ring->running = true;
diff --git a/drivers/thunderbolt/nhi.h b/drivers/thunderbolt/nhi.h
index ca3eddf862e0..e4964772a442 100644
--- a/drivers/thunderbolt/nhi.h
+++ b/drivers/thunderbolt/nhi.h
@@ -62,6 +62,9 @@ extern const struct dev_pm_ops nhi_pm_ops;
  * @ring_interrupt_mask: NHI specific hook to mask/unmask the interrupt of a
  *			 single ring. If not set the standard USB4 NHI
  *			 registers are used.
+ * @ring_configure: NHI specific hook to program the ring options registers
+ *		    and enable the ring with the given flags. If not set
+ *		    the standard USB4 NHI registers are used.
  * @is_present: Whether the device is currently present on the parent bus
  * @init_interrupts: NHI specific interrupt initialization hook
  * @reset_interface: Resets the host interface
@@ -81,6 +84,7 @@ struct tb_nhi_ops {
 	void __iomem *(*ring_options_base)(struct tb_ring *ring);
 	void (*ring_interrupt_active)(struct tb_ring *ring, bool active);
 	void (*ring_interrupt_mask)(struct tb_ring *ring, bool mask);
+	void (*ring_configure)(struct tb_ring *ring, u32 flags, u32 e2e_flags);
 	bool (*is_present)(struct tb_nhi *nhi);
 	int (*init_interrupts)(struct tb_nhi *nhi);
 	void (*reset_interface)(struct tb_nhi *nhi);

-- 
2.55.0

