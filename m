From: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
Date: Fri, 16 Oct 2026 09:08:06 -0400
Subject: [PATCH net] ice: fix Tx hang dump using stale tx_buf[0].skb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-ice-tx-hang-dump-v1-1-3df0f5979a51@hydroquebec.com>
X-B4-Tracking: v=1; b=H4sIALUh0moC/yWMQQrCMBREr1Jm7YemhiBeRVzYZFq/YCxJWgqld
 zfV5ZvhvQ2ZSZlxbTYkLpr1EyuYUwP/fMSRoqEyurZzpjVO1FPKKscnYX5PQut6y2Av5+BQtSl
 x0PWXvCGy4P4f89y/6MsRw75/AVz2cXJ5AAAA
X-Change-ID: 20261016-ice-tx-hang-dump-e46b4ed483d6
To: Tony Nguyen <anthony.l.nguyen@intel.com>, 
 Przemek Kitszel <przemyslaw.kitszel@intel.com>, 
 intel-wired-lan@lists.osuosl.org
Cc: Aleksandr Loktionov <aleksandr.loktionov@intel.com>, 
 Michal Kubiak <michal.kubiak@intel.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 Vincent Choiniere <choiniere.vincent@hydroquebec.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792156085; l=3665;
 i=choiniere.vincent@hydroquebec.com; s=20261016; h=from:subject:message-id;
 bh=kt4dx1VrvDe36KXprpuSVG48M5IH9Jew3kkpwsyl//I=;
 b=rpz6gaUYmlu/qQeArQzXjGbdt7hmwbh5F2PXicMHbyd04KAmR7m0AivdHwD8NF8xUWPxaCq66
 vusrlXo13J0B8Xt4KnPmLoDzQSufiqzXYtu2F+evb6a33g6/z8dzX7W
X-Developer-Key: i=choiniere.vincent@hydroquebec.com; a=ed25519;
 pk=MctQE067DucsZOaNqb+sjY7aQ+urhztuURanagEW3+8=
X-Endpoint-Received: by B4 Relay for choiniere.vincent@hydroquebec.com/20261016 with auth_id=1210
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ice_tx_hang_reporter_dump() always reads tx_ring->tx_buf[0].skb,
regardless of next_to_clean. The Tx cleanup path frees the skb and
marks the buffer empty without clearing the skb pointer, so slot 0 can
hold a stale pointer. A NULL check alone does not cover this, and
devlink_fmsg_dump_skb() can fault on the freed skb.

Read tx_buf[next_to_clean] instead, use its skb only if the buffer type
is ICE_TX_BUF_SKB, and skip the skb dump otherwise.

Observed on an E810 PF passed through to a KVM guest (Ubuntu 7.0.0-14,
PREEMPT_RT, local scheduler patch): a delayed queue IRQ led to a Tx
timeout and a page fault in devlink_fmsg_dump_skb():

 BUG: unable to handle page fault for address: 0000000004cd0c11
 Workqueue: ice ice_service_task [ice]
 RIP: devlink_fmsg_dump_skb+0x2d8/0x5d0
 Call Trace:
  ice_tx_hang_reporter_dump+0x1ce/0x210 [ice]
  devlink_health_do_dump+0xcc/0x190
  devlink_health_report+0x1d7/0x260
  ice_report_tx_hang+0x7d/0xa0 [ice]

With this change and auto_dump enabled, starving a queue IRQ thread
reproduced the Tx timeout; the dump contained the test packet, no Oops
occurred and the PF recovered.

Fixes: 2a82874a3b7b ("ice: add Tx hang devlink health reporter")
Link: https://lore.kernel.org/all/20260327072332.130320-1-aleksandr.loktionov@intel.com/
Cc: stable@vger.kernel.org
Signed-off-by: Vincent Choiniere <choiniere.vincent@hydroquebec.com>
---
This complements the NULL check in [1]. With only that check, a non-NULL
but stale tx_buf[0].skb is still dereferenced by devlink_fmsg_dump_skb().
I have only reproduced the crash on an Ubuntu 7.0.0-14 kernel with
PREEMPT_RT and a local scheduler patch, and the skb lifetime against
concurrent Tx cleanup still needs review. Feedback welcome.

In my case next_to_clean was 0xfc while the reporter read slot 0.
Upstream v7.0, v7.2 and current net main (191aa4154) all read
tx_buf[0].skb unconditionally. Before this change, recovery stayed
stuck until reboot.

[1] https://lore.kernel.org/all/20260327072332.130320-1-aleksandr.loktionov@intel.com/
---
 drivers/net/ethernet/intel/ice/devlink/health.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/drivers/net/ethernet/intel/ice/devlink/health.c b/drivers/net/ethernet/intel/ice/devlink/health.c
index 8e9a8a817..059859c36 100644
--- a/drivers/net/ethernet/intel/ice/devlink/health.c
+++ b/drivers/net/ethernet/intel/ice/devlink/health.c
@@ -390,12 +390,15 @@ static int ice_tx_hang_reporter_dump(struct devlink_health_reporter *reporter,
 				     struct netlink_ext_ack *extack)
 {
 	struct ice_tx_hang_event *event = priv_ctx;
-	struct sk_buff *skb;
+	struct sk_buff *skb = NULL;
+	struct ice_tx_buf *tx_buf;
 
 	if (!event)
 		return 0;
 
-	skb = event->tx_ring->tx_buf->skb;
+	tx_buf = &event->tx_ring->tx_buf[event->next_to_clean];
+	if (tx_buf->type == ICE_TX_BUF_SKB)
+		skb = tx_buf->skb;
 	devlink_fmsg_obj_nest_start(fmsg);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, head);
 	ICE_DEVLINK_FMSG_PUT_FIELD(fmsg, event, intr);
@@ -409,7 +412,8 @@ static int ice_tx_hang_reporter_dump(struct devlink_health_reporter *reporter,
 	ice_fmsg_put_ptr(fmsg, "skb-ptr", skb);
 	devlink_fmsg_binary_pair_put(fmsg, "desc", event->tx_ring->desc,
 				     event->tx_ring->count * sizeof(struct ice_tx_desc));
-	devlink_fmsg_dump_skb(fmsg, skb);
+	if (skb)
+		devlink_fmsg_dump_skb(fmsg, skb);
 	devlink_fmsg_obj_nest_end(fmsg);
 
 	return 0;

---
base-commit: 191aa41548b2d2b6af534a6d5cf84a552435c74c
change-id: 20261016-ice-tx-hang-dump-e46b4ed483d6

Best regards,
--  
Vincent Choiniere <choiniere.vincent@hydroquebec.com>

