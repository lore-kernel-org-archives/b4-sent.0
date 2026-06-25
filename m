From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 25 Jun 2026 04:51:20 -0500
Subject: [PATCH 2/2] net/sched: sch_multiq: Replace direct dequeue call
 with peek and qdisc_dequeue_peeked
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-b4-disp-31bcb279-v1-2-85c40b83c529@proton.me>
References: <20260625-b4-disp-31bcb279-v1-0-85c40b83c529@proton.me>
In-Reply-To: <20260625-b4-disp-31bcb279-v1-0-85c40b83c529@proton.me>
To: Vinicius Costa Gomes <vinicius.gomes@intel.com>, 
 Paolo Abeni <pabeni@redhat.com>, Jamal Hadi Salim <jhs@mojatatu.com>, 
 Jiri Pirko <jiri@resnulli.us>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>
Cc: Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 Jarek Poplawski <jarkao2@gmail.com>, 
 Vladimir Oltean <vladimir.oltean@nxp.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782381078; l=1511;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=w7wRNrInJ6R59lQnmw33WI/qx8pFQzfYwnA3wVu2g3I=;
 b=oHcZfonzbWyvjEJ/9reY7m8sV1mXVgFCQwYOBjtHIu0+V+ehrqN115C5tJeykZedL1y9JlU0I
 T7Dr2ZwHnJ+AlQmpGjtYP5sN9xSpDZJzoG31ugsp/2FgeeBv26O6+rl
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

multiq_dequeue() takes a packet from a band's child with a direct
->dequeue() call after multiq_peek() peeked it. When the child is
non-work-conserving the peek stashes the skb in the child's gso_skb, so
the direct dequeue returns a different skb and orphans the stash,
desyncing the child's qlen/backlog. With a qfq child reached through a
peeking parent (e.g. tbf) this re-enters the child on an emptied list and
dereferences NULL, panicking the kernel from softirq on ordinary egress.

Take the packet through qdisc_dequeue_peeked(), as sch_prio already does
and as sch_red and sch_sfb were just fixed to do. The helper is a no-op
when the child has no stash, so a work-conserving child is unaffected.

Fixes: 77be155cba4e ("pkt_sched: Add peek emulation for non-work-conserving qdiscs.")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 net/sched/sch_multiq.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/sched/sch_multiq.c b/net/sched/sch_multiq.c
index 4e465d11e3d7..a467dd122369 100644
--- a/net/sched/sch_multiq.c
+++ b/net/sched/sch_multiq.c
@@ -103,7 +103,7 @@ static struct sk_buff *multiq_dequeue(struct Qdisc *sch)
 		if (!netif_xmit_stopped(
 		    netdev_get_tx_queue(qdisc_dev(sch), q->curband))) {
 			qdisc = q->queues[q->curband];
-			skb = qdisc->dequeue(qdisc);
+			skb = qdisc_dequeue_peeked(qdisc);
 			if (skb) {
 				qdisc_bstats_update(sch, skb);
 				qdisc_qlen_dec(sch);

-- 
2.43.0

