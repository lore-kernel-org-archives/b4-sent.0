From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Tue, 20 Oct 2026 21:28:37 +0300
Subject: [PATCH] wifi: mt76: dma: run threaded NAPI kthreads with
 SCHED_FIFO low priority
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-b4-mt76-napi-fifo-v1-1-ac8a24e2062a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqEMAxA0atI1gZqqQpeRVzYmsxEsEqrIhTvP
 h1dvsX/CSIFoQhdkSDQKVFWn1GVBbjv6D+EMmWDVrqplFZoDS5726AfN0EWXnFyNbFhp401kLs
 tEMv1PPvhdTzsTG7/j+C+f+QaXPF1AAAA
X-Change-ID: 20261020-b4-mt76-napi-fifo-dc5ef4fc24b4
To: nbd@nbd.name, lorenzo@kernel.org, ryder.lee@mediatek.com
Cc: shayne.chen@mediatek.com, sean.wang@mediatek.com, 
 matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 linux-wireless@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792520916; l=2932;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=gTH2kexAA/EJvNPz+GCLDxl2HKRZ9qNQnHFrv8bnx/A=;
 b=1t7HqYA5U6ggeRCUvO/xOQ1LgjTa3bTc8sYP5vdhFE+66gXRT/Kqf1T8KfB6+5t+Sn/iNaxZ3
 Hsw/op0cOlyAiCj2QCJUfMRemJtwrbQZj08yB4jhEnSdKO3pB16/try
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mt76 enables threaded NAPI for the dma rx queues, but the napi kthreads
stay SCHED_OTHER, unlike the usb and sdio rx/status workers and the tx
worker, which already use sched_set_fifo_low().

On MT7621 (MIPS 1004Kc, 2 cores / 4 threads, PREEMPT_NONE, HZ=100) with
MT7612E (mt76x2e) as a 5 GHz client receiving ~200 Mbit/s while
userspace keeps the CPUs busy, the napi kthread is regularly delayed by
10-30 ms or more and the 256-entry rx ring fills up completely
(instrumented: ~500 full-ring events in 5 minutes). Occasionally the
chip's rx DMA does not resume after such an event: WPDMA_GLO_CFG reports
rx and tx DMA busy, RXQ_STA shows the PBF rx queue at RX_MAX_PCNT, the
host ring has free buffers, beacons are lost, then tx DMA stops (dma_idx
stuck with frames queued), the tx hang watchdog fires, followed by
"MCU message ... timed out" and a second restart. A series of these
sometimes hangs the whole system.

With the napi kthreads at SCHED_FIFO 1 the ring overflowed once in 5
minutes, no watchdog resets occurred in repeated 5 minute runs and rx
throughput in the same setup went from ~210 to ~280 Mbit/s. A larger rx
ring (1024 entries) did not help: it still overflowed and resets were
more frequent.

Set the napi kthread priority right after netif_napi_add(), as done for
the other workers.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
Tested on Securifi Almond 3 (MT7621, MT7612E + MT7602E) with OpenWrt
25.12.6 (kernel 6.12.112, mt76 2026-03-19 39c960c3 plus this change):
iperf3 bidirectional, 4 streams, 5 GHz client link at -66 dBm, with a
userspace proxy and a display daemon running. Without the change 2-3
watchdog resets in most 5 minute runs and several full-system hangs;
with it 0 resets over 6 runs.

A similar reset chain under full CPU load on MT7620A + MT7612E is
reported in https://github.com/openwrt/openwrt/issues/8984
---
 drivers/net/wireless/mediatek/mt76/dma.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/net/wireless/mediatek/mt76/dma.c b/drivers/net/wireless/mediatek/mt76/dma.c
index a67880a92..8e66fad7b 100644
--- a/drivers/net/wireless/mediatek/mt76/dma.c
+++ b/drivers/net/wireless/mediatek/mt76/dma.c
@@ -1128,6 +1128,11 @@ mt76_dma_rx_queue_init(struct mt76_dev *dev, enum mt76_rxq_id qid,
 		       int (*poll)(struct napi_struct *napi, int budget))
 {
 	netif_napi_add(dev->napi_dev, &dev->napi[qid], poll);
+	/* Same as the usb/sdio rx workers: under CPU load a SCHED_OTHER napi
+	 * thread can be starved long enough for the rx ring to overflow.
+	 */
+	if (dev->napi[qid].thread)
+		sched_set_fifo_low(dev->napi[qid].thread);
 	mt76_dma_rx_fill_buf(dev, &dev->q_rx[qid], false);
 	napi_enable(&dev->napi[qid]);
 }

---
base-commit: 6474fa070f2b8013b4b87350b775b8c3be6e8aac
change-id: 20261020-b4-mt76-napi-fifo-dc5ef4fc24b4

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

