From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 21:19:07 +0800
Subject: [PATCH] vhost: mask the in-order used-ring log cursor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-06-vhost-in-order-log-oob-v1-35efdba8fbab-v1-1-fc1253d60351@pm.me>
X-B4-Tracking: v=1; b=H4sIAMvrAmsC/yWNQQ7CIBBFr9KwdiIMIzZexbgYYLCYphiojcZ4d
 1tdvpef/96qSc3S1Kl7qypLbrlMK5hdp8LA01Ugx5UVanTGIIIn0A6WobQZ8gSlRqkwliuU4mE
 xYA+Souc+efZA9miJo9FJs1ov71VSfv5y58uf28PfJMxbY1t4bgK+8hSGTVUZ+QWb3AcioylZR
 xj5iNo40oQOrVBvsbeO13DsRX0+XwQsXgnWAAAA
X-Change-ID: 20261122-b4-06-vhost-in-order-log-oob-v1-35efdba8fbab-43734ad10f0a
To: "Michael S. Tsirkin" <mst@redhat.com>, 
 Jason Wang <jasowangio@gmail.com>, 
 =?utf-8?q?Eugenio_P=C3=A9rez?= <eperezma@redhat.com>
Cc: Linfeng Sun <linfeng.sun.dev@gmail.com>, 
 Fang Xieyan <fangxy@xiaopeng.com>, kvm@vger.kernel.org, 
 virtualization@lists.linux.dev, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795353580; l=4082;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=b9KCl8TEKKfFvwWrPZOWWYYFr6aHOdYXisG6z2qF2xQ=;
 b=rtGYSwT0f96cTkFcdpMJC+bA4UrATMjPWmfopHMa0rBlOaH2wrG5I0MbE+YBClP4375a69FHy
 oFvkhR6y+yyBBISZAXu8+XeXvpCilWOKqBUPiOyInwVPBvKzjWURmbW
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vhost_add_used_n_in_order() plays the batch of used-ring writes back a
second time for dirty logging.  Commit e244725e86be ("vhost: fix used
ring index wrap in vhost_add_used_n_in_order") masked the index in the
descriptor-publishing loop.  The dirty-logging loop introduced by
bfcde6b64769 still uses the single-subtraction form

    next = start + nheads[i];
    if (next >= vq->num)
        next -= vq->num;

If the guest refills the available ring while get_rx_bufs() collects
one mergeable-RX packet, that packet can consume more heads than
vq->num.  get_rx_bufs() permits up to UIO_MAXIOV = 1024 descriptor
chains in one call, so a single subtraction is not enough.  For
vq->num = 32, last_used_idx = 0 and nheads[0] = 64, next becomes
64 - 32 = 32, which is still equal to vq->num and out of bounds.  The
next iteration then logs

    used = vq->used->ring + 32;
    log_used(vq, 4 + 32 * 8, 8);

which starts past the end of the 260-byte ring body (4 + 32 * 8).
For a used ring placed inside page 7 at guest address 0x7ef8 (so the
entire 262-byte ring occupies [0x7ef8, 0x7ffe) and
vq_log_used_access_ok() validates only log_base[0]), log_used()
marks [0x7ffc, 0x8004) as dirty.  log_write() then sets a bit in
log_base[1] for page 8, past the single validated byte.  On a
vhost-net RX queue configured with VIRTIO_F_IN_ORDER,
VIRTIO_NET_F_MRG_RXBUF,
VHOST_F_LOG_ALL, VHOST_VRING_F_LOG, vq->num = 32, and
log_guest_addr = 0x7ef8, delivering one 8 KiB frame consuming 64
mergeable buffers followed by one 1-buffer frame in the same
count = 2 flush writes

    log_base[1] = 0x01

where log_base[0] = 0x80 is the only byte the kernel was entitled to
touch.  A guest attached to a vhost-net backend with dirty-page
logging enabled (for example during live migration) and a small RX
ring can therefore corrupt dirty-log bitmap memory that the VMM owns
outside the region registered for this ring.

Wrap the logging loop index the same way the first loop does:

    next = (start + nheads[i]) & (vq->num - 1);

vhost_vring_set_num() already enforces that vq->num is a nonzero
power of two, so this is well defined for every accepted ring size.
The coalescing invariant is preserved: if a run is not flushed,
next == start + 1.  When start == vq->num - 1, start + 1 == vq->num,
whereas the masked next is always less than vq->num.  The run is
therefore flushed before the cursor wraps.
With this change the same vhost-net configuration publishes
used->idx = 65 and confines the dirty log to log_base[0] = 0x80,
leaving log_base[1] = 0x00.  The mask keeps next in [0, vq->num) for
every accepted power-of-two ring size.  As a bounded cross-check of
the index arithmetic, a Z3 model over ring sizes {1, 2, 4, 8, 16, 32}
and buffer counts in [1, 64] finds an out-of-range result for the old
subtraction (vq->num = 16, start = 15, nheads = 17) and none for the
mask within those bounds.

Runtime verification and fix validation were performed in an x86-64
QEMU/KVM guest running mainline after v7.4-rc3, with Generic KASAN,
UBSAN, lockdep, and DEBUG_OBJECTS.

Fixes: bfcde6b64769 ("vhost: fix dirty logging for in-order used ring entries")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
 drivers/vhost/vhost.c | 4 +---
 1 file changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/vhost/vhost.c b/drivers/vhost/vhost.c
index dc973287567..80b887e1511 100644
--- a/drivers/vhost/vhost.c
+++ b/drivers/vhost/vhost.c
@@ -3206,9 +3206,7 @@ static int vhost_add_used_n_in_order(struct vhost_virtqueue *vq,
 				log_start = start;
 			log_count++;
 
-			next = start + nheads[i];
-			if (next >= vq->num)
-				next -= vq->num;
+			next = (start + nheads[i]) & (vq->num - 1);
 			if (i + 1 == count || next != start + 1) {
 				used = vq->used->ring + log_start;
 				log_used(vq,

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-06-vhost-in-order-log-oob-v1-35efdba8fbab-43734ad10f0a

Best regards,
--  
YanXin Li <fadouse@pm.me>

