From: Christian Taedcke <christian.taedcke@weidmueller.com>
Date: Mon, 06 Jul 2026 16:02:15 +0200
Subject: [PATCH net 2/2] net: macb: mask TXUBR during TX NAPI poll to
 prevent IRQ storms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-upstreaming-macb-irq-storm-v1-2-ab3115b5a13a@weidmueller.com>
References: <20260706-upstreaming-macb-irq-storm-v1-0-ab3115b5a13a@weidmueller.com>
In-Reply-To: <20260706-upstreaming-macb-irq-storm-v1-0-ab3115b5a13a@weidmueller.com>
To: christian.taedcke-oss@weidmueller.com, 
 =?utf-8?q?Th=C3=A9o_Lebrun?= <theo.lebrun@bootlin.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Kevin Hao <haokexin@gmail.com>, Simon Horman <horms@kernel.org>, 
 Sebastian Andrzej Siewior <bigeasy@linutronix.de>, 
 Clark Williams <clrkwllms@kernel.org>, Steven Rostedt <rostedt@goodmis.org>, 
 Robert Hancock <robert.hancock@calian.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-rt-devel@lists.linux.dev, 
 Christian Taedcke <christian.taedcke@weidmueller.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783346550; l=3260;
 i=christian.taedcke@weidmueller.com; s=20260702; h=from:subject:message-id;
 bh=qBAhD1fzYGVIv2HSHAY5AonQugiJMQCwmywRThD7Rc4=;
 b=lcab6wkUlVeW0bvlaxZSpaBZqBvr6Zx9OuvIStOIGAmSoiW9ZJf6A8IlFCP42Kzx4ozF9l8b3
 OSRsiux4tV7AmDByrJMRhxrRmeXmwTNs9x4S9R9JnCKcYZc351QLXnW
X-Developer-Key: i=christian.taedcke@weidmueller.com; a=ed25519;
 pk=fVCoBhFV3uMogA2nxIOU/rynNY+O2TDJgWvWjR06TrQ=
X-Endpoint-Received: by B4 Relay for christian.taedcke@weidmueller.com/20260702 with auth_id=847
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

macb_interrupt() defers TX completion handling to NAPI, but when it
schedules the poll it only masks TCOMP, even though TXUBR is enabled
alongside it (both are part of MACB_TX_INT_FLAGS). macb_tx_poll() is
asymmetric in the same way and only re-enables TCOMP. TXUBR is thus
left unmasked while responsibility for handling it has been deferred
to NAPI.

Unlike an edge event, TXUBR is a persistent condition: the controller
keeps it asserted for as long as the transmitter reads a buffer
descriptor whose used bit is set. Leaving a level-triggered source
enabled while NAPI owns its processing means the interrupt refires
immediately after the handler returns, before the poll has had a
chance to clear the underlying condition. This turns into a hard
interrupt storm that pegs a CPU in the (threaded) MAC IRQ handler and,
on PREEMPT_RT, triggers RT throttling ("sched: RT throttling
activated"), taking the network interface down.

Several situations can keep the used-bit read asserted across a poll -
for example unreaped completed descriptors still sitting at tx_tail,
or a transmit restart racing with macb_start_xmit(). The specific
trigger does not matter: as long as the source stays unmasked, any
persistent assertion is enough to storm, so the interrupt handling
itself must be made self-limiting.

Mask TXUBR together with TCOMP in the IDR write when scheduling the TX
NAPI, and re-enable both from the napi_complete path in
macb_tx_poll(), making the TX interrupt mask/unmask symmetric and
consistent with how the driver already treats every other
NAPI-serviced source. The pending TXUBR is still recorded in
queue->txubr_pending before masking and acted on by macb_tx_restart(),
so no event is lost. A persistent TXUBR now degrades to NAPI-paced
polling instead of a CPU-pegging hard interrupt storm.

Fixes: 138badbc21a0 ("net: macb: use NAPI for TX completion path")
Cc: stable@vger.kernel.org
Assisted-by: Claude:claude-opus-4-8
Signed-off-by: Christian Taedcke <christian.taedcke@weidmueller.com>
---
 drivers/net/ethernet/cadence/macb_main.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/net/ethernet/cadence/macb_main.c b/drivers/net/ethernet/cadence/macb_main.c
index b11cb8f068b7..f75cf2ffdf6f 100644
--- a/drivers/net/ethernet/cadence/macb_main.c
+++ b/drivers/net/ethernet/cadence/macb_main.c
@@ -1971,7 +1971,7 @@ static int macb_tx_poll(struct napi_struct *napi, int budget)
 		    (unsigned int)(queue - bp->queues), work_done, budget);
 
 	if (work_done < budget && napi_complete_done(napi, work_done)) {
-		queue_writel(queue, IER, MACB_BIT(TCOMP));
+		queue_writel(queue, IER, MACB_BIT(TCOMP) | MACB_BIT(TXUBR));
 
 		/* Packet completions only seem to propagate to raise
 		 * interrupts when interrupts are enabled at the time, so if
@@ -2161,7 +2161,8 @@ static irqreturn_t macb_interrupt(int irq, void *dev_id)
 
 		if (status & (MACB_BIT(TCOMP) |
 			      MACB_BIT(TXUBR))) {
-			queue_writel(queue, IDR, MACB_BIT(TCOMP));
+			queue_writel(queue, IDR, MACB_BIT(TCOMP) |
+						 MACB_BIT(TXUBR));
 			macb_queue_isr_clear(bp, queue, MACB_BIT(TCOMP) |
 							MACB_BIT(TXUBR));
 			if (status & MACB_BIT(TXUBR)) {

-- 
2.54.0

