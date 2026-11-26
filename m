From: Dickson Wu <dickson.wu@certik.com>
Date: Thu, 26 Nov 2026 06:02:02 +0000
Subject: [PATCH 5.10.y v2] net: mvpp2: refill RX buffers before XDP or skb
 use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-mvpp2-5e8e-v2-1-ef63da5e986d@certik.com>
X-B4-Tracking: v=1; b=H4sIAFrLB2sC/0WNwQrCMBBEf6Xs2a3NQkPxV8RDsl1tRJOQtEUp/
 XcTPXicx8ybDbIkJxlOzQZJVpdd8CXQoQGejL8JurFkoI60UqTxucZI2MsgyMykOlY0aIIyiEm
 u7vWVnaFvVde+4fLjebF34bmaatOaLGiT8TxVlMWPcwgPrPz4f4B9/wD3axuUoQAAAA==
X-Change-ID: 20261126-mvpp2-5e8e-ccc210c12862
To: stable@vger.kernel.org
Cc: Til Kaiser <mail@tk154.de>, Paolo Abeni <pabeni@redhat.com>, 
 netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795672922; l=5401;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=q1z21D2oSS0MfDyUGQDXPgR2WSKojsBUli2aZzmavWg=;
 b=ckKJ57S7gEMu1Dffs0drulLjxMFEi8Q/PU2Aygl4ggrCFt0nfB7/2/Fn4imB9vLTyD1LcqD3l
 t367b1/OtX+AAdisCo6aGsM+FpmhsQdrpyv9+Co2B2A/IpICgbYnf7m
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Til Kaiser <mail@tk154.de>

commit 5e8e2a9624df72fca7c736b2966b2cbf6c9c3ff6 upstream.

The RX error path returns the current descriptor buffer to the hardware
BM pool. That is only valid while the driver still owns the buffer.

mvpp2_rx_refill() can fail after the current buffer has been handed to
XDP or attached to an skb. In those cases mvpp2_run_xdp() may have
recycled, redirected, or queued the page for XDP_TX, and an skb free also
retires the data buffer. Returning such a buffer to BM lets hardware DMA
into memory that is no longer owned by the RX ring.

Refill the BM pool before handing the current buffer to XDP or to the
skb. If the allocation fails there, drop the packet and return the
still-owned current buffer to BM, preserving the pool depth. Once the
refill succeeds, later local drops retire/free the current buffer instead
of returning it to BM.

Fixes: 07dd0a7aae7f ("mvpp2: add basic XDP support")
Fixes: d6526926de73 ("net: mvpp2: fix memory leak in mvpp2_rx")
Signed-off-by: Til Kaiser <mail@tk154.de>
Link: https://patch.msgid.link/20260607134943.21996-4-mail@tk154.de
Signed-off-by: Paolo Abeni <pabeni@redhat.com>
[ adapted to 5.10: page_pool_release_page() in place of skb_mark_for_recycle() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
 .../net/ethernet/marvell/mvpp2/mvpp2_main.c   | 43 +++++++++++--------
 1 file changed, 24 insertions(+), 19 deletions(-)

Changes in v2
v2: resent through a whitespace-safe path; v1 <CAFaZ9eob6Kg4WDo_m203vhom-XtsNN1kFUKgyUs3DcCTev5msQ@mail.gmail.com> was damaged by my mail client and does not apply.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

5.15.y and newer already have this. 5.10 has no skb_mark_for_recycle();
mvpp2_rx() there hands the page over with page_pool_release_page()
instead, so that call moves up to right after build_skb() succeeds,
where the 5.15.y backport has skb_mark_for_recycle(). Everything else
matches 5.15.y.

It goes with f3c6aa078927 ("net: mvpp2: limit XDP frame size to the RX
buffer") that I sent for 5.10.y earlier. The two don't depend on each
other.

Tested on v5.10.275:
- x86_64 allmodconfig (CONFIG_MVPP2=m) W=1 build of mvpp2_main.o, base
  vs patched, no new warnings
- x86_64 defconfig with CONFIG_MVPP2=y builds and boots under QEMU/KVM
- I don't have mvpp2 hardware, so the RX refill path itself is untested
  here.

diff --git a/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c b/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
index 3e60d40b3f6f..5915a8cdeddd 100644
--- a/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
+++ b/drivers/net/ethernet/marvell/mvpp2/mvpp2_main.c
@@ -3613,6 +3613,12 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 		else
 			frag_size = bm_pool->frag_size;
 
+		err = mvpp2_rx_refill(port, bm_pool, pp, pool);
+		if (err) {
+			netdev_err(port->dev, "failed to refill BM pools\n");
+			goto err_drop_frame;
+		}
+
 		if (xdp_prog) {
 			xdp.data_hard_start = data;
 			xdp.data = data + MVPP2_MH_SIZE + MVPP2_SKB_HEADROOM;
@@ -3630,12 +3636,6 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 
 			if (ret) {
 				xdp_ret |= ret;
-				err = mvpp2_rx_refill(port, bm_pool, pp, pool);
-				if (err) {
-					netdev_err(port->dev, "failed to refill BM pools\n");
-					goto err_drop_frame;
-				}
-
 				ps.rx_packets++;
 				ps.rx_bytes += rx_bytes;
 				continue;
@@ -3645,8 +3645,21 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 		skb = build_skb(data, frag_size);
 		if (!skb) {
 			netdev_warn(port->dev, "skb build failed\n");
-			goto err_drop_frame;
+			if (pp) {
+				page_pool_put_page(pp, virt_to_head_page(data),
+						   rx_bytes + MVPP2_MH_SIZE,
+						   true);
+			} else {
+				dma_unmap_single_attrs(dev->dev.parent, dma_addr,
+						       bm_pool->buf_size,
+						       DMA_FROM_DEVICE,
+						       DMA_ATTR_SKIP_CPU_SYNC);
+				mvpp2_frag_free(bm_pool, pp, data);
+			}
+			goto err_drop_frame_retired;
 		}
+		if (pp)
+			page_pool_release_page(pp, virt_to_page(data));
 
 		/* If we have RX hardware timestamping enabled, grab the
 		 * timestamp from the queue and convert.
@@ -3657,16 +3670,7 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 					 skb_hwtstamps(skb));
 		}
 
-		err = mvpp2_rx_refill(port, bm_pool, pp, pool);
-		if (err) {
-			netdev_err(port->dev, "failed to refill BM pools\n");
-			dev_kfree_skb_any(skb);
-			goto err_drop_frame;
-		}
-
-		if (pp)
-			page_pool_release_page(pp, virt_to_page(data));
-		else
+		if (!pp)
 			dma_unmap_single_attrs(dev->dev.parent, dma_addr,
 					       bm_pool->buf_size, DMA_FROM_DEVICE,
 					       DMA_ATTR_SKIP_CPU_SYNC);
@@ -3683,13 +3687,14 @@ static int mvpp2_rx(struct mvpp2_port *port, struct napi_struct *napi,
 		continue;
 
 err_drop_frame:
-		dev->stats.rx_errors++;
-		mvpp2_rx_error(port, rx_desc);
 		/* Return the buffer to the pool */
 		if (rx_status & MVPP2_RXD_BUF_HDR)
 			mvpp2_buff_hdr_pool_put(port, rx_desc, pool, rx_status);
 		else
 			mvpp2_bm_pool_put(port, pool, dma_addr, phys_addr);
+err_drop_frame_retired:
+		dev->stats.rx_errors++;
+		mvpp2_rx_error(port, rx_desc);
 	}
 
 	rcu_read_unlock();

