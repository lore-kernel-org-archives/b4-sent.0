From: Fan Ye <fy15309206903@gmail.com>
Date: Mon, 10 Aug 2026 12:14:13 +0000
Subject: [PATCH v2] thunderbolt: Clamp DMA tunnel credits to what a hop
 register can hold
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-tb-dma-credit-clamp-v2-1-e81af742994d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJTAeWoC/yXMSwqDMBRG4a3IHfdCjFhit1I6yONve6VaSaII4
 t6N7fAbnLNRQhQkulUbRSyS5DsW6EtF/m3HF1hCMWmlr8rUirPjMFj2EUEy+48dJoZruqZGa1t
 jqJRTxFPW3/X++DvNrofP54r2/QDDHSSsdwAAAA==
X-Change-ID: 20260810-tb-dma-credit-clamp-eb3931e5a588
To: Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fan Ye <fy15309206903@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786364052; l=2813;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=KBUQ47DnBp3QLMg8TJHD2p+uE/UzAFnilfTEhi9eTUs=;
 b=aq/DQVlltc9t1J6XnhVF3zVK1D7g3GWhN/YV5BFD5Z5A4zZ34QW1rBSBDI/Fup+ykvBLLbuCQ
 FHRMRNvnq1cDvsZ0xCXRdxj3AQzEbMi2SjJb1Op5Yst9/Q8A7M7xmgZ
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct tb_regs_hop::initial_credits is 7 bits wide, but neither of the
values tb_tunnel_alloc_dma() picks from is bounded by that: the
dma_credits module parameter has no upper limit, and neither does the
host router's baMaxHI. A larger count survives until tb_path_activate()
copies it into the register and keeps the low bits, leaving the path on
a credit count nobody asked for.

Clamp it in tb_tunnel_alloc_dma(), the only entry point for DMA tunnels;
every step below it can only lower the value further. Carry the count in
an unsigned int while at it.

Assisted-by: Claude:claude-opus-5
Signed-off-by: Fan Ye <fy15309206903@gmail.com>
---
Reproduced by dropping the baMaxHI cap with a debug patch and asking an
ASMedia ASM4242 host router, whose lane adapters report 174 buffers, for
172 credits: reading the hop back after tb_path_activate() showed 44,
that is 172 & 0x7f.  With this patch it shows 127.  The defaults do not
reach it - dma_credits is 14 and this router reports baMaxHI 32.

v2:
- Trim the commit message and these notes.
- Drop the Fixes: tag.
- Rename TB_MAX_HOP_CREDITS to TB_MAX_CREDITS and cut the comment above
  it down to one line.

v1: https://lore.kernel.org/r/20260810-tb-dma-credit-clamp-v1-1-69610146d164@gmail.com
---
 drivers/thunderbolt/tunnel.c | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/drivers/thunderbolt/tunnel.c b/drivers/thunderbolt/tunnel.c
index b7f32305f14a..da4fa7b1b248 100644
--- a/drivers/thunderbolt/tunnel.c
+++ b/drivers/thunderbolt/tunnel.c
@@ -48,6 +48,9 @@
 #define TB_DP_AUX_PRIORITY		2
 #define TB_DP_AUX_WEIGHT		1
 
+/* struct tb_regs_hop::initial_credits is 7 bits wide */
+#define TB_MAX_CREDITS			127
+
 /* Minimum number of credits needed for PCIe path */
 #define TB_MIN_PCIE_CREDITS		6U
 /*
@@ -1908,7 +1911,7 @@ struct tb_tunnel *tb_tunnel_alloc_dma(struct tb *tb, struct tb_port *nhi,
 	struct tb_tunnel *tunnel;
 	size_t npaths = 0, i = 0;
 	struct tb_path *path;
-	int credits;
+	unsigned int credits;
 
 	/* Ring 0 is reserved for control channel */
 	if (WARN_ON(!receive_ring || !transmit_ring))
@@ -1931,6 +1934,11 @@ struct tb_tunnel *tb_tunnel_alloc_dma(struct tb *tb, struct tb_port *nhi,
 	tunnel->destroy = tb_dma_destroy;
 
 	credits = min_not_zero(dma_credits, nhi->sw->max_dma_credits);
+	if (credits > TB_MAX_CREDITS) {
+		tb_tunnel_dbg(tunnel, "%u credits do not fit a hop, using %u\n",
+			      credits, TB_MAX_CREDITS);
+		credits = TB_MAX_CREDITS;
+	}
 
 	if (receive_ring > 0) {
 		path = tb_path_alloc(tb, dst, receive_path, nhi, receive_ring, 0,

---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260810-tb-dma-credit-clamp-eb3931e5a588

Best regards,
--  
Fan Ye <fy15309206903@gmail.com>

