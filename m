From: Fan Ye <fy15309206903@gmail.com>
Date: Mon, 10 Aug 2026 09:38:30 +0000
Subject: [PATCH] thunderbolt: Clamp DMA tunnel credits to what a hop
 register can hold
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-tb-dma-credit-clamp-v1-1-69610146d164@gmail.com>
X-B4-Tracking: v=1; b=H4sIABWceWoC/yXMSwqDMBRG4a3IHfdColhit1I6yONve6VaSaII4
 t6N7fAbnLNRQhQkulUbRSyS5DsW6EtF/m3HF1hCMdWqviqjFWfHYbDsI4Jk9h87TAzXdI1Ga1t
 jqJRTxFPW3/X++DvNrofP54r2/QA3H4IGdwAAAA==
X-Change-ID: 20260810-tb-dma-credit-clamp-eb3931e5a588
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-usb@vger.kernel.org, 
 Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786354709; l=6038;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=sH5s661mYHQVXNWt2E9soxhgbibtEzecbaMoOwZi+Fk=;
 b=4GxCjJOPsvbZXUft4clBvXYrN5xgdpNnye8LCpCADk8rEYIXBWPL3FO/oDtfoHtXDnZVwrvNK
 iN49Ods2vxOD7ewAl7l+vcsnqSomzXGyP94ENg6OJs5RxaPZADbvWA2
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct tb_regs_hop::initial_credits is 7 bits wide, so a hop can be
programmed with 127 credits at most. tb_tunnel_alloc_dma() picks the
credit count for a DMA tunnel out of two values that are not bounded by
that: the dma_credits module parameter, which has no upper limit at all,
and the host router's baMaxHI, which usb4_switch_credits_init() reads
out of a 16-bit field and only checks for presence, never for magnitude.

What comes out is handed to tb_dma_init_rx_path() and
tb_dma_init_tx_path(), which lower it to what the adapter has room for
and store the result in struct tb_path_hop::initial_credits. That field
is an unsigned int, so an oversized number survives until
tb_path_activate() copies it into the 7-bit register field and keeps
only the low bits. The path then runs on a credit count that neither
the driver nor the user chose, while port->dma_credits goes on
accounting for the number that was asked for. Nothing reports the
difference.

The adapter has to have that many buffers for the truncation to be
reachable, and ADP_CS_4_TOTAL_BUFFERS_MASK leaves room for it: the lane
adapters of an ASMedia ASM4242 host router report 174. Asking such a
router for 172 credits leaves 172 & 0x7f == 44 in the hop.

Clamp the count where it is chosen. tb_tunnel_alloc_dma() is the only
entry point for DMA tunnels, the clamp sits ahead of every hop
assignment and every credit accounting update, and each step below it
can only lower the value further, so one bound covers the whole tunnel
and the driver's bookkeeping stays in step with the hardware. Before the
module parameter existed this line read min_not_zero(TB_DMA_CREDITS,
nhi->sw->max_dma_credits) and could not yield more than 14.

While at it, carry the count in an unsigned int. Both min_not_zero()
operands and every function it is passed to are unsigned already, so the
int only added a signed detour in the middle of an otherwise unsigned
path.

Fixes: 7ee20d0afb69 ("thunderbolt: Allow specifying custom credits for DMA tunnels")
Assisted-by: Claude:claude-opus-5
Signed-off-by: Fan Ye <fy15309206903@gmail.com>
---
The truncation is not reachable with the defaults. dma_credits is 14 and
the ASM4242 in front of me reports baMaxHI 32, so 127 is never
approached; I had to drop the baMaxHI cap with a local debug patch and
ask for 172 to see it. Reading the hop straight back after
tb_path_activate() had written it then showed 44 in the register. With
this patch it shows 127.

That is not an argument for 127 being a good number to run on. On this
hardware anything above what the router asks for costs packets - the
receiving adapter starts dropping around 35 credits, and further up the
control channel stops answering altogether - so the clamp is a statement
about what the field can hold, not a recommendation.

The same 7-bit field is assigned from three other places: USB3
(sw->max_usb3_credits, with no min() at all), DP AUX
(sw->min_dp_aux_credits) and PCIe (min(sw->max_pcie_credits,
available)). usb4_switch_credits_init() only checks that those buffer
allocation values are present, never how large they are, so nothing in
the driver stops them from passing 127 either. I left them alone because
I have no evidence any router advertises that much there - the one I can
read out reports 64/2/64 for USB3/DP AUX/PCIe, and the bad advertisement
already handled in tree, quirk_dp_credit_allocation(), is 56. Should
those get the same treatment, or does the spec bound them in a way that
makes it unnecessary?

One thing I deliberately left alone: tb_available_credits() computes
spare = min_not_zero(sw->max_dma_credits, dma_credits) without this
bound, so with dma_credits set above 127 it now reserves more than a DMA
tunnel can take, at the expense of the DP stream count. Clamping there
too is one more line, but it changes how many DP streams fit, which is
more than a truncation fix should do on its own.

No Cc: stable, since reaching this needs either dma_credits set by hand
or a router advertising baMaxHI above 127, and I have not seen the
latter. Happy to add it if you disagree.
---
 drivers/thunderbolt/tunnel.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index b7f32305f14a..b2a8e4950200 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -48,6 +48,15 @@
 #define TB_DP_AUX_PRIORITY		2
 #define TB_DP_AUX_WEIGHT		1
 
+/*
+ * struct tb_regs_hop::initial_credits is 7 bits wide, so this is the most a
+ * hop can be programmed with. What feeds it is not bounded by that:
+ * ADP_CS_4_TOTAL_BUFFERS_MASK is 10 bits and the dma_credits module
+ * parameter has no upper limit at all. A larger value is stored with its
+ * top bits cut off, leaving the path on a credit count nobody asked for.
+ */
+#define TB_MAX_HOP_CREDITS		127
+
 /* Minimum number of credits needed for PCIe path */
 #define TB_MIN_PCIE_CREDITS		6U
 /*
@@ -1908,7 +1917,7 @@ struct tb_tunnel *tb_tunnel_alloc_dma(struct tb *tb, struct tb_port *nhi,
 	struct tb_tunnel *tunnel;
 	size_t npaths = 0, i = 0;
 	struct tb_path *path;
-	int credits;
+	unsigned int credits;
 
 	/* Ring 0 is reserved for control channel */
 	if (WARN_ON(!receive_ring || !transmit_ring))
@@ -1931,6 +1940,11 @@ struct tb_tunnel *tb_tunnel_alloc_dma(struct tb *tb, struct tb_port *nhi,
 	tunnel->destroy = tb_dma_destroy;
 
 	credits = min_not_zero(dma_credits, nhi->sw->max_dma_credits);
+	if (credits > TB_MAX_HOP_CREDITS) {
+		tb_tunnel_dbg(tunnel, "%u credits do not fit a hop, using %u\n",
+			      credits, TB_MAX_HOP_CREDITS);
+		credits = TB_MAX_HOP_CREDITS;
+	}
 
 	if (receive_ring > 0) {
 		path = tb_path_alloc(tb, dst, receive_path, nhi, receive_ring, 0,

---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260810-tb-dma-credit-clamp-eb3931e5a588

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>

