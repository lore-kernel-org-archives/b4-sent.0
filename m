From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 05 Aug 2026 21:29:37 +0800
Subject: [PATCH net 2/2] ovpn: don't re-hash a removed peer on float
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-ovpn-fixes-v1-2-763f8c237fb9@outlook.com>
References: <20260805-ovpn-fixes-v1-0-763f8c237fb9@outlook.com>
In-Reply-To: <20260805-ovpn-fixes-v1-0-763f8c237fb9@outlook.com>
To: Antonio Quartulli <antonio@openvpn.net>, 
 Sabrina Dubroca <sd@queasysnail.net>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3264;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=TNob32RUD1q+jLQJNBoNmFv017reaFPJPazB8n2U7SU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrGKrq47RCv6zixunbJ1qGlVSt9/va9jCY3kPQiRCn
 rJ1bev4s6KjlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJtLox/CbbYfdB+fambaO
 /9vCY9Lvfuz3YF+h8KN/V8T2w3031Do2MDJsvfWkd89Pm+z0ud0PJ+/czBKv8eHR0/mX2P9m7Kz
 rvT2THwBJNFBQ
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ovpn_peer_endpoints_update() releases peer->lock before sending the
float notification, then re-acquires ovpn->lock and peer->lock to move
the peer to its new bucket in the by_transp_addr table. The only
re-check in that second critical section is for a NULL bind, which
cannot detect removal: bind is cleared by ovpn_peer_release() only
after the refcount drops to zero, and the RX path holds a reference
across the whole float.

Both paths take ovpn->lock, but that only serialises them - it does
not order them:

  CPU0 (RX softirq)              CPU1
  ovpn_peer_endpoints_update()
    spin_unlock_bh(&peer->lock)
    ovpn_nl_peer_float_notify()
                                 ovpn_nl_peer_del_doit()
                                   ovpn_peer_remove()  <- unlinks peer
                                   unlock_ovpn()       <- drops last ref
    spin_lock_bh(&ovpn->lock)
    hlist_nulls_add_head_rcu()   <- removed peer re-linked

ovpn_peer_release_rcu() then frees the peer without unlinking it again,
leaving a dangling node in by_transp_addr that every later datagram
walks in ovpn_peer_get_by_transp_addr():

  BUG: KASAN: slab-use-after-free in ovpn_peer_endpoints_update+0xa5a/0x1010
  Write of size 8 at addr ffff888008576858 by task trigger/78

  Call Trace:
   ovpn_peer_endpoints_update+0xa5a/0x1010
   ovpn_decrypt_post+0x212/0x1040
   ovpn_recv+0x2b6/0x540
   ovpn_udp_encap_recv+0x21c/0x420
   udp_queue_rcv_one_skb+0x1060/0x11a0
   process_backlog+0x451/0x600

  Freed by task 0:
   kfree+0x11a/0x390
   rcu_core+0x7aa/0x1570

  Last potentially related work creation:
   call_rcu+0x82/0x720
   ovpn_peer_release_kref+0x5c/0xd0
   ovpn_nl_peer_del_doit+0x355/0x550

Fix it by extending the existing early return to also bail out when the
peer is no longer hashed by ID. hash_entry_id is unhashed with
hlist_del_init_rcu() by ovpn_peer_remove() under ovpn->lock, which the
float path holds across both the check and the rehash, so a peer that
passes the test cannot be removed before it is re-linked.

Fixes: f0281c1d3732 ("ovpn: add support for updating local or remote UDP endpoint")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/net/ovpn/peer.c | 7 ++++++-
 1 file changed, 6 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ovpn/peer.c b/drivers/net/ovpn/peer.c
index a21d02ac715e..03886c46ec85 100644
--- a/drivers/net/ovpn/peer.c
+++ b/drivers/net/ovpn/peer.c
@@ -302,7 +302,12 @@ void ovpn_peer_endpoints_update(struct ovpn_peer *peer, struct sk_buff *skb)
 		spin_lock_bh(&peer->lock);
 		bind = rcu_dereference_protected(peer->bind,
 						 lockdep_is_held(&peer->lock));
-		if (unlikely(!bind)) {
+		/* peer->lock was released above, therefore the peer may have
+		 * been removed in the meantime: ovpn_peer_remove() unhashes
+		 * hash_entry_id under ovpn->lock. Re-linking a removed peer
+		 * would leave it reachable after it has been freed.
+		 */
+		if (unlikely(!bind || hlist_unhashed(&peer->hash_entry_id))) {
 			spin_unlock_bh(&peer->lock);
 			spin_unlock_bh(&peer->ovpn->lock);
 			return;

-- 
2.51.2

