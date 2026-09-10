From: Gunter Woytowitz <gunter@vcinity.io>
Date: Thu, 10 Sep 2026 11:17:47 -0400
Subject: [PATCH net] net: mana: never hand a non-page_pool buffer to XDP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-mana-xdp-pagepool-v1-1-dab140d91fed@vcinity.io>
X-B4-Tracking: v=1; b=H4sIABrKomoC/yWMwQrCMBAFf6W8swtJkEr8FfGwbbZ1RZOQVCmU/
 rtRjzMws6FKUak4dxuKvLVqig3socN44zgLaWgMZ1xvvDX05Mi0hkyZZ8kpPSj0lk9Hb9zgJ7Q
 uF5l0/T0viLLg+pf1NdxlXL437PsH5/mPFHoAAAA=
X-Change-ID: 20260910-mana-xdp-pagepool-d61a74902b9f
To: "K. Y. Srinivasan" <kys@microsoft.com>, 
 Haiyang Zhang <haiyangz@microsoft.com>, Wei Liu <wei.liu@kernel.org>, 
 Dexuan Cui <decui@microsoft.com>, Long Li <longli@microsoft.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Jesper Dangaard Brouer <hawk@kernel.org>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Stanislav Fomichev <sdf@fomichev.me>
Cc: "open list:Hyper-V/Azure CORE AND DRIVERS" <linux-hyperv@vger.kernel.org>, 
 "open list:NETWORKING DRIVERS" <netdev@vger.kernel.org>, 
 open list <linux-kernel@vger.kernel.org>, 
 "open list:XDP eXpress Data Path:Keyword:?:b|_xdp?:b|_" <bpf@vger.kernel.org>, 
 Gunter Woytowitz <gunter@vcinity.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789053514; l=3692;
 i=gunter@vcinity.io; s=20260910; h=from:subject:message-id;
 bh=t35EUXvqFJ2uE2i3MYOOcxmhW+Pix8QOFDeXbTpTRo0=;
 b=NKaAMktkjRymX7yeIUQMcFSX4xXFQO1p857Cw9i+09qUKmkP9XE+M6xbd3BtmFug/Js4+KWft
 qyu9RTS81xNCSgon0yLahJiPGi8+Qlqu6LQsm8RGoRCLk9sBeRnGX4m
X-Developer-Key: i=gunter@vcinity.io; a=ed25519;
 pk=6nOwIllYdhcDoigio1cuWODQHYf4rmE6FCJmKXcGH7w=
X-Endpoint-Received: by B4 Relay for gunter@vcinity.io/20260910 with auth_id=1021
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mana_create_rxq() registers MEM_TYPE_PAGE_POOL for the rxq
unconditionally, so every buffer XDP can see must be owned by that
page_pool: on XDP_REDIRECT the frame is freed through __xdp_return()
-> page_pool_put_full_page().

mana_xdp_set() assigns apc->bpf_prog before calling
mana_pre_alloc_rxbufs(), which allocates with dev_alloc_pages(), and
mana_fill_rx_oob() prefers those buffers whenever mpc->rxbufs_pre is
set, leaving from_pool false. So for a port that is up when a program
is attached, the entire re-created ring is filled with pages the
page_pool does not own.

The page_pool then sees pp_ref_count == 0 when such a frame is
returned, so the atomic_long_sub_return() in page_pool_unref_netmem()
goes negative and trips its WARN_ON(ret < 0), once per redirected
frame. Observed on a 5.14-based distro kernel, where that warning sits
at helpers.h:269:

  WARNING: CPU: 3 PID: 0 at include/net/page_pool/helpers.h:269
                                            __xdp_return+0x2b3/0x2c0
  mana_process_rx_cqe -> mana_run_xdp -> mana_rx_skb -> xsk_map_redirect
                                            -> __xdp_return

On a VM booted with console=ttyS0 the resulting stack traces peg the
console thread and the machine becomes unusable.

Fill from the page_pool when a program is attached, using
mana_xdp_get() -- the predicate mana_get_rxbuf_cfg() already uses to
choose the XDP buffer geometry. With no program attached nothing
changes, so the pre-allocation still does its job of keeping
mana_attach() from failing on allocation.

Leaving the pre-allocated buffers unconsumed is safe:
mana_pre_dealloc_rxbufs() dma-unmaps and put_page()s the remainder,
and every caller (mana_xdp_set(), mana_change_mtu(), and both ethtool
ring and channel paths) already runs it after mana_attach().

The rxq->xdp_save_va reuse in mana_get_rxfrag() also leaves from_pool
false, but that cache is fed only by the drop path's non-pool branch,
which this change makes unreachable while a program is attached, so
it needs no fix.

Found and fixed on a 5.14-based distro kernel running AF_XDP over
MANA in copy mode: 24M+ redirected frames with no warnings, where the
unpatched driver warned on essentially every redirected frame. All of
the code involved is unchanged in mainline.

Fixes: b1d13f7a3b53 ("net: mana: Add page pool for RX buffers")
Signed-off-by: Gunter Woytowitz <gunter@vcinity.io>
---
 drivers/net/ethernet/microsoft/mana/mana_en.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/microsoft/mana/mana_en.c b/drivers/net/ethernet/microsoft/mana/mana_en.c
index 7a1ac853e..a2cb66753 100644
--- a/drivers/net/ethernet/microsoft/mana/mana_en.c
+++ b/drivers/net/ethernet/microsoft/mana/mana_en.c
@@ -2925,7 +2925,14 @@ static int mana_fill_rx_oob(struct mana_recv_buf_oob *rx_oob, u32 mem_key,
 	dma_addr_t da;
 	void *va;
 
-	if (mpc->rxbufs_pre)
+	/* The pre-allocated buffers come from dev_alloc_pages(), not from the
+	 * rxq's page_pool. With a program attached any buffer can reach
+	 * __xdp_return(), which returns it to the pool the rxq registered, so
+	 * fill from the pool instead. The unused pre-allocated buffers are
+	 * released by the mana_pre_dealloc_rxbufs() every caller already runs
+	 * after mana_attach().
+	 */
+	if (mpc->rxbufs_pre && !mana_xdp_get(mpc))
 		va = mana_get_rxbuf_pre(rxq, &da);
 	else
 		va = mana_get_rxfrag(rxq, dev, &da, &from_pool, &pp_page,

---
base-commit: 50d05c7c76c96b90462f24debacca971d2e86713
change-id: 20260910-mana-xdp-pagepool-d61a74902b9f

Best regards,
--  
Gunter Woytowitz <gunter@vcinity.io>

