From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:46 +0000
Subject: [PATCH RFC nf-next 6/9] netfilter: nfqueue: account saved skb
 bytes per queue
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-6-b9cc30819997@asgari.net>
References: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
In-Reply-To: <20261115-b4-nfqueue-memory-accounting-v1-0-b9cc30819997@asgari.net>
To: netfilter-devel@vger.kernel.org, linux-mm@kvack.org
Cc: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, Shuah Khan <shuah@kernel.org>, 
 Tejun Heo <tj@kernel.org>, Vladimir Davydov <vdavydov.dev@gmail.com>, 
 Chris Down <chris@chrisdown.name>, 
 Zhang Jiao <zhangjiao2@cmss.chinamobile.com>, Song Hu <husong@kylinos.cn>, 
 cgroups@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Alireza Asgari <alireza@asgari.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=8527;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=5VLqD9hrhT1MpNUocVL10oVpUb4KAqRndB+1hfVAv+c=;
 b=LhT3DhnLw1RGO11l0Nui1rJW18n0Ql3De38AdIwBgIQsb+M6+rLSlaBQ5uHvKK9PmMp8gO5JA
 uAK5NmbIcgLA/SoI70QJbwmrFEYfDJutbpjnQ0pVJIc8qTsu1wVbv/+
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The packet-count limit does not bound how much skb memory a queue can
retain: packets with different truesize values consume the same one
entry. Add a local byte allowance alongside the existing packet limit.

Derive the allowance from queue_maxlen times an aligned skb shell plus
a nominal 2048-byte complete head. This is a proposed policy, not a
promise that every packet fitting a nominal payload size is admitted.
Page-backed receive heads can exceed the allowance of a small queue.

Record admission-time skb truesize only after insertion succeeds. Keep
that saved cost while verdict handlers detach entries, and subtract it
before reinjection, including early consume paths. Undo it if the
userspace notification fails. Later payload replacement does not change
the saved cost. Segmented packets account each inserted segment.

Use subtraction-based admission checks that remain safe after a live
limit reduction. Retain existing entries when shrinking and refuse new
ones until both limits permit admission. Byte refusal follows the
existing drop or FAIL_OPEN policy.

This implements the local accounting part of Florian Westphal's
suggestion; shared owner accounting follows in the next patch.

Link: https://lists.openwall.net/netdev/2026/11/06/366
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 include/net/netfilter/nf_queue.h |  1 +
 net/netfilter/nfnetlink_queue.c  | 59 +++++++++++++++++++++++++++++++++++-----
 2 files changed, 53 insertions(+), 7 deletions(-)

diff --git a/include/net/netfilter/nf_queue.h b/include/net/netfilter/nf_queue.h
index 4a8cefd8398d..5644a1ad32d5 100644
--- a/include/net/netfilter/nf_queue.h
+++ b/include/net/netfilter/nf_queue.h
@@ -16,6 +16,7 @@ struct nf_queue_entry {
 	struct sk_buff		*skb;
 	struct net_device	*skb_dev;
 	unsigned int		id;
+	unsigned int truesize; /* saved NFQUEUE charge, zero if uncharged */
 	unsigned int		hook_index;	/* index in hook_entries->hook[] */
 #if IS_ENABLED(CONFIG_BRIDGE_NETFILTER)
 	struct net_device	*bridge_dev;
diff --git a/net/netfilter/nfnetlink_queue.c b/net/netfilter/nfnetlink_queue.c
index 862d2a762106..d1e6e02e144b 100644
--- a/net/netfilter/nfnetlink_queue.c
+++ b/net/netfilter/nfnetlink_queue.c
@@ -92,6 +92,8 @@ struct nfqnl_instance {
 	unsigned int	queue_total;
 	unsigned int	id_sequence;		/* 'sequence' of pkt ids */
 	struct list_head queue_list;		/* packets in queue */
+	u64 mem_limit;
+	u64 mem_used;
 };
 
 typedef int (*nfqnl_cmpfn)(struct nf_queue_entry *, unsigned long);
@@ -138,6 +140,28 @@ instance_lookup(struct nfnl_queue_net *q, u_int16_t queue_num)
 	return NULL;
 }
 
+static u64 nfqnl_mem_limit(unsigned int maxlen)
+{
+	/* Match the skb shell alignment included in skb->truesize. */
+	return (u64)maxlen * (SKB_DATA_ALIGN(sizeof(struct sk_buff)) + 2048);
+}
+
+static bool nfqnl_mem_full(const struct nfqnl_instance *queue,
+			   unsigned int truesize)
+{
+	return queue->mem_used > queue->mem_limit ||
+	       truesize > queue->mem_limit - queue->mem_used;
+}
+
+/* All release paths use the saved admission cost, including notification undo. */
+static void nfqnl_mem_uncharge(struct nfqnl_instance *queue,
+			       struct nf_queue_entry *entry)
+{
+	lockdep_assert_held(&queue->lock);
+	queue->mem_used -= entry->truesize;
+	entry->truesize = 0;
+}
+
 static struct nfqnl_instance *
 instance_create(struct nfnl_queue_net *q, u_int16_t queue_num, u32 portid)
 {
@@ -152,6 +176,7 @@ instance_create(struct nfnl_queue_net *q, u_int16_t queue_num, u32 portid)
 	inst->queue_num = queue_num;
 	inst->peer_portid = portid;
 	inst->queue_maxlen = NFQNL_QMAX_DEFAULT;
+	inst->mem_limit = nfqnl_mem_limit(NFQNL_QMAX_DEFAULT);
 	inst->copy_range = NFQNL_MAX_COPY_RANGE;
 	inst->copy_mode = NFQNL_COPY_NONE;
 	spin_lock_init(&inst->lock);
@@ -199,6 +224,7 @@ static void instance_destroy_work(struct work_struct *work)
 	rcu_read_lock();
 	nfqnl_flush(inst, NULL, 0);
 	rcu_read_unlock();
+	WARN_ON_ONCE(inst->mem_used);
 
 	rhashtable_destroy(&inst->nfqnl_packet_map);
 
@@ -235,6 +261,8 @@ __enqueue_entry(struct nfqnl_instance *queue, struct nf_queue_entry *entry)
 
 	list_add_tail(&entry->list, &queue->queue_list);
 	queue->queue_total++;
+	entry->truesize = entry->skb->truesize;
+	queue->mem_used += entry->truesize;
 
 	return 0;
 }
@@ -493,7 +521,7 @@ static bool nf_bridge_ports_valid(const struct nf_queue_entry *entry)
 	return true;
 }
 
-static void nfqnl_reinject(struct nf_queue_entry *entry, unsigned int verdict)
+static void __nfqnl_reinject(struct nf_queue_entry *entry, unsigned int verdict)
 {
 	const struct nf_ct_hook *ct_hook;
 
@@ -544,6 +572,15 @@ static void nfqnl_reinject(struct nf_queue_entry *entry, unsigned int verdict)
 	nf_reinject(entry, verdict);
 }
 
+static void nfqnl_reinject(struct nfqnl_instance *queue,
+			   struct nf_queue_entry *entry, unsigned int verdict)
+{
+	spin_lock_bh(&queue->lock);
+	nfqnl_mem_uncharge(queue, entry);
+	spin_unlock_bh(&queue->lock);
+	__nfqnl_reinject(entry, verdict);
+}
+
 static void
 nfqnl_flush(struct nfqnl_instance *queue, nfqnl_cmpfn cmpfn, unsigned long data)
 {
@@ -553,7 +590,8 @@ nfqnl_flush(struct nfqnl_instance *queue, nfqnl_cmpfn cmpfn, unsigned long data)
 	list_for_each_entry_safe(entry, next, &queue->queue_list, list) {
 		if (!cmpfn || cmpfn(entry, data)) {
 			__dequeue_entry(queue, entry);
-			nfqnl_reinject(entry, NF_DROP);
+			nfqnl_mem_uncharge(queue, entry);
+			__nfqnl_reinject(entry, NF_DROP);
 		}
 	}
 	spin_unlock_bh(&queue->lock);
@@ -1004,6 +1042,7 @@ __nfqnl_enqueue_packet(struct net *net, struct nfqnl_instance *queue,
 	__be32 *packet_id_ptr;
 	int failopen = 0;
 
+	entry->truesize = 0;
 	nskb = nfqnl_build_packet_message(net, queue, entry, &packet_id_ptr);
 	if (nskb == NULL) {
 		err = -ENOMEM;
@@ -1011,7 +1050,8 @@ __nfqnl_enqueue_packet(struct net *net, struct nfqnl_instance *queue,
 	}
 	spin_lock_bh(&queue->lock);
 
-	if (queue->queue_total >= queue->queue_maxlen)
+	if (queue->queue_total >= queue->queue_maxlen ||
+	    nfqnl_mem_full(queue, entry->skb->truesize))
 		goto err_out_queue_drop;
 
 	entry->id = ++queue->id_sequence;
@@ -1027,6 +1067,7 @@ __nfqnl_enqueue_packet(struct net *net, struct nfqnl_instance *queue,
 	if (err < 0) {
 		/* Unicast failed - remove entry we just inserted */
 		__dequeue_entry(queue, entry);
+		nfqnl_mem_uncharge(queue, entry);
 
 		if (queue->flags & NFQA_CFG_F_FAIL_OPEN) {
 			failopen = 1;
@@ -1050,6 +1091,9 @@ __nfqnl_enqueue_packet(struct net *net, struct nfqnl_instance *queue,
 		if (queue->queue_total >= queue->queue_maxlen)
 			net_warn_ratelimited("nf_queue: full at %d entries, dropping packets(s)\n",
 					     queue->queue_total);
+		else if (nfqnl_mem_full(queue, entry->skb->truesize))
+			net_warn_ratelimited(
+				"nf_queue: byte limit reached, dropping packet\n");
 		else
 			net_warn_ratelimited("nf_queue: hash insert failed: %d\n", err);
 	}
@@ -1057,7 +1101,7 @@ __nfqnl_enqueue_packet(struct net *net, struct nfqnl_instance *queue,
 err_out_unlock:
 	spin_unlock_bh(&queue->lock);
 	if (failopen)
-		nfqnl_reinject(entry, NF_ACCEPT);
+		nfqnl_reinject(queue, entry, NF_ACCEPT);
 err_out:
 	return err;
 }
@@ -1773,7 +1817,7 @@ static int nfqnl_recv_verdict_batch(struct sk_buff *skb,
 		if (nfqa[NFQA_PRIORITY])
 			entry->skb->priority = ntohl(nla_get_be32(nfqa[NFQA_PRIORITY]));
 
-		nfqnl_reinject(entry, verdict);
+		nfqnl_reinject(queue, entry, verdict);
 	}
 	return 0;
 }
@@ -1885,7 +1929,7 @@ static int nfqnl_recv_verdict(struct sk_buff *skb, const struct nfnl_info *info,
 	if (entry->state.pf == PF_BRIDGE) {
 		err = nfqa_parse_bridge(entry, nfqa);
 		if (err < 0) {
-			nfqnl_reinject(entry, NF_DROP);
+			nfqnl_reinject(queue, entry, NF_DROP);
 			return err;
 		}
 	}
@@ -1907,7 +1951,7 @@ static int nfqnl_recv_verdict(struct sk_buff *skb, const struct nfnl_info *info,
 	if (nfqa[NFQA_PRIORITY])
 		entry->skb->priority = ntohl(nla_get_be32(nfqa[NFQA_PRIORITY]));
 
-	nfqnl_reinject(entry, verdict);
+	nfqnl_reinject(queue, entry, verdict);
 	return 0;
 }
 
@@ -2037,6 +2081,7 @@ static int nfqnl_recv_config(struct sk_buff *skb, const struct nfnl_info *info,
 
 		spin_lock_bh(&queue->lock);
 		queue->queue_maxlen = ntohl(*queue_maxlen);
+		queue->mem_limit = nfqnl_mem_limit(queue->queue_maxlen);
 		spin_unlock_bh(&queue->lock);
 	}
 

-- 
2.34.1

