From: Siddarth Chilukuri <siddarth@nexthop.ai>
Date: Mon, 05 Oct 2026 18:50:57 +0000
Subject: [PATCH] i2c: xiic: don't fail a read whose data is already in the
 RX FIFO
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261005-i2c-xiic-rx-fifo-v1-1-0177ac5f72d7@nexthop.ai>
X-B4-Tracking: v=1; b=H4sIAJDxw2oC/yXMQQ6DIBBG4auYWTsJQmxMr2JcCAzt34UaUENiu
 HupXX6L9y5KEiGJns1FUU4krEtF1zbk3vPyEoavJq30o1OqZ2jHGXAcMweElY0xNgx+9nawVLM
 tSkC+l+P0dzrsR9z++1ApXykwNPZ0AAAA
X-Change-ID: 20261005-i2c-xiic-rx-fifo-333bf8dadb8b
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Siddarth Chilukuri <siddarth@nexthop.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791226262; l=3974;
 i=siddarth@nexthop.ai; s=20261005; h=from:subject:message-id;
 bh=+OMLHRv9yGnRH1ltNBvfAy2ZGPv/CunRdqkdVFB3ta4=;
 b=fRMJFO9GuGN1sByoQ3O+tITvMHEb87DpmbBz/kSKqiCXKGR0xFvy7Cu/78q8cQeHEANs8ySrl
 9e7sjYJ3fR+Bb9YTlpfxfO6Of53gcBwmKoea1n5iPAVPsWioHPVgFW3
X-Developer-Key: i=siddarth@nexthop.ai; a=ed25519;
 pk=mqZgV5HLHwCtP2hfnYLQEnd3V9s5LQLC664snM9/mlQ=
X-Endpoint-Received: by B4 Relay for siddarth@nexthop.ai/20261005 with auth_id=1116
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the controller is the master receiver, TX_ERROR is set once the
core has NACKed the last byte ("transmit complete" in PG090). We have
seen xiic_process() run with TX_ERROR set but RX_FULL not yet set,
while the RX FIFO already holds all of the remaining bytes of the
message.

xiic_process() treats TX_ERROR without RX_FULL as an error, so in this
case it reinitializes the core, the data in the FIFO is lost, and the
read returns -EIO even though it finished on the bus. The next read on
the same adapter can also return stale data without reporting an error.

Fix this by checking the RX FIFO in the error path. If the message is
a read, there was no arbitration loss, and the FIFO has all of the
remaining bytes, handle it the same way as RX_FULL and complete the
message. Since IISR is toggle-on-write, only clear RX_FULL if it was
actually set.

We found this on a system with several AXI IIC controllers in one PCIe
FPGA that share an interrupt. It only happens when at least two
controllers are busy at the same time. With 12 QSFP-DD modules being
read in parallel for 480 seconds, the failures went from 2083 -EIO and
1158 reads with wrong data (out of 11.2M reads) to none.

Fixes: e1d5b6598cdc ("i2c: Add support for Xilinx XPS IIC Bus Interface")
Cc: stable@vger.kernel.org
Signed-off-by: Siddarth Chilukuri <siddarth@nexthop.ai>
---
I tested this on hardware with the 6.11 kernel we found the problem
on. On mainline it is compile-tested only.
---
 drivers/i2c/busses/i2c-xiic.c | 26 ++++++++++++++++++++++++++
 1 file changed, 26 insertions(+)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 5e397a7e6..11319ac09 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -755,6 +755,7 @@ static irqreturn_t xiic_process(int irq, void *dev_id)
 	int wakeup_req = 0;
 	enum xilinx_i2c_state wakeup_code = STATE_DONE;
 	int ret;
+	bool rx_done_no_rx_full = false;
 
 	/* Get the interrupt Status from the IPIF. There is no clearing of
 	 * interrupts in the IPIF. Interrupts must be cleared at the source.
@@ -787,6 +788,27 @@ static irqreturn_t xiic_process(int irq, void *dev_id)
 
 		dev_dbg(i2c->adap.dev.parent, "%s error\n", __func__);
 
+		/*
+		 * For a master receiver TX_ERROR also means "transfer complete" and
+		 * can be seen before RX_FULL. If the FIFO already holds the rest of
+		 * the message, finish the read instead of resetting the core.
+		 */
+		if (i2c->rx_msg && !(pend & XIIC_INTR_ARB_LOST_MASK) &&
+		    !(xiic_getreg8(i2c, XIIC_SR_REG_OFFSET) &
+		      XIIC_SR_RX_FIFO_EMPTY_MASK)) {
+			unsigned int in_fifo =
+				xiic_getreg8(i2c, XIIC_RFO_REG_OFFSET) + 1;
+			unsigned int space = xiic_rx_space(i2c);
+
+			if (space && in_fifo >= space) {
+				rx_done_no_rx_full =
+					!(isr & XIIC_INTR_RX_FULL_MASK);
+				pend |= XIIC_INTR_RX_FULL_MASK;
+				clr |= XIIC_INTR_TX_ERROR_MASK;
+				goto rx_complete;
+			}
+		}
+
 		/* dynamic mode seem to suffer from problems if we just flushes
 		 * fifos and the next message is a TX with len 0 (only addr)
 		 * reset the IP instead of just flush fifos
@@ -806,6 +828,7 @@ static irqreturn_t xiic_process(int irq, void *dev_id)
 		/* don't try to handle other events */
 		goto out;
 	}
+rx_complete:
 	if (pend & XIIC_INTR_RX_FULL_MASK) {
 		/* Receive register/FIFO is full */
 
@@ -911,6 +934,9 @@ static irqreturn_t xiic_process(int irq, void *dev_id)
 out:
 	dev_dbg(i2c->adap.dev.parent, "%s clr: 0x%x\n", __func__, clr);
 
+	/* IISR is toggle-on-write: don't toggle an RX_FULL bit that wasn't set */
+	if (rx_done_no_rx_full)
+		clr &= ~XIIC_INTR_RX_FULL_MASK;
 	xiic_setreg32(i2c, XIIC_IISR_OFFSET, clr);
 	if (xfer_more)
 		__xiic_start_xfer(i2c);

---
base-commit: 67f0943b394d920b6c142aad8c6af94340342ae7
change-id: 20261005-i2c-xiic-rx-fifo-333bf8dadb8b

Best regards,
--  
Siddarth Chilukuri <siddarth@nexthop.ai>

