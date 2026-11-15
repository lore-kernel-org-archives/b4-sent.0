From: Alireza Asgari <alireza@asgari.net>
Date: Sun, 15 Nov 2026 22:34:47 +0000
Subject: [PATCH RFC nf-next 7/9] netfilter: nfqueue: reserve capacity
 against the bound owner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261115-b4-nfqueue-memory-accounting-v1-7-b9cc30819997@asgari.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794782082; l=12745;
 i=alireza@asgari.net; s=alireza-kernel; h=from:subject:message-id;
 bh=2RMtp6Bo7PwbFVa/IduU+cdsBTZbySOUxORVFjimTHw=;
 b=Zo1EQcnHYoQyuJZjflJmekByHV00hvlWIoJWZS7R8/Phb4tO0CHqt6lCbdJjHE44PnHZwZGsj
 z2yVl5+yj2RA/s32bJUTSeE0cYF85zhCsqTj8+G1rjjr1qVeV+6kAM3
X-Developer-Key: i=alireza@asgari.net; a=ed25519;
 pk=wuQ0/M69FqoVnrCMUJ13EQCwrCwVjCrtz75k15vW8tw=
X-Endpoint-Received: by B4 Relay for alireza@asgari.net/alireza-kernel with auth_id=1055
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A local queue allowance does not by itself bound aggregate reservations
across queues. Outside the initial network namespace, capture the binding
task's objcg and charge activated capacity against that owner and its
ancestors. Effective aggregate protection requires an applicable finite
memory limit; root or otherwise unaccounted owners remain uncharged.

Reserve capacity on first activation, after any inactive sizing. Publish
copy mode, size, and flags together only after required growth succeeds.
Keep activation sticky so switching to COPY_NONE cannot release backing
for retained entries or an admission already in progress. Configure a new
instance privately before publishing it to packet readers.

Retain page-rounded backing for the greater of configured capacity and
saved bytes still in use. Serialize configuration and refunds with a
mutex. Packet releases schedule coalesced refund work; the worker rechecks
the target before refunding. Teardown waits for the RCU readers that can
hold detached entries, stops refund scheduling, cancels outstanding work,
flushes retained entries, and destroys the reservation.

The charges are ordinary memcg usage, additional to actual allocations.
Empty activated capacity therefore consumes budget and can affect
memory.high and protection accounting. The budget policy, nominal byte
allowance, and reservation API are proposed for maintainer discussion.

Link: https://lists.openwall.net/netdev/2026/11/06/366
Signed-off-by: Alireza Asgari <alireza@asgari.net>
---
 net/netfilter/nfnetlink_queue.c | 213 +++++++++++++++++++++++++++-------------
 1 file changed, 144 insertions(+), 69 deletions(-)

diff --git a/net/netfilter/nfnetlink_queue.c b/net/netfilter/nfnetlink_queue.c
index d1e6e02e144b..b37fb6f21482 100644
--- a/net/netfilter/nfnetlink_queue.c
+++ b/net/netfilter/nfnetlink_queue.c
@@ -32,6 +32,8 @@
 #include <linux/icmpv6.h>
 #include <linux/ip.h>
 #include <linux/list.h>
+#include <linux/memcontrol.h>
+#include <linux/mutex.h>
 #include <linux/sctp.h>
 #include <linux/cgroup-defs.h>
 #include <linux/rhashtable.h>
@@ -73,6 +75,10 @@ struct nfqnl_instance {
 	struct hlist_node hlist;		/* global list of queues */
 	struct rhashtable nfqnl_packet_map;
 	struct rcu_work	rwork;
+	struct work_struct mem_work;
+	struct mutex mem_mutex; /* serializes capacity changes and refunds */
+	struct mem_cgroup_reservation memcg;
+	bool mem_activated; /* maintain backing after the first activation */
 
 	u32 peer_portid;
 	unsigned int queue_maxlen;
@@ -94,6 +100,8 @@ struct nfqnl_instance {
 	struct list_head queue_list;		/* packets in queue */
 	u64 mem_limit;
 	u64 mem_used;
+	u64 mem_reserved; /* pages, published under lock */
+	bool mem_stopping;
 };
 
 typedef int (*nfqnl_cmpfn)(struct nf_queue_entry *, unsigned long);
@@ -146,6 +154,11 @@ static u64 nfqnl_mem_limit(unsigned int maxlen)
 	return (u64)maxlen * (SKB_DATA_ALIGN(sizeof(struct sk_buff)) + 2048);
 }
 
+static u64 nfqnl_mem_pages(u64 bytes)
+{
+	return (bytes >> PAGE_SHIFT) + !!(bytes & (PAGE_SIZE - 1));
+}
+
 static bool nfqnl_mem_full(const struct nfqnl_instance *queue,
 			   unsigned int truesize)
 {
@@ -153,6 +166,83 @@ static bool nfqnl_mem_full(const struct nfqnl_instance *queue,
 	       truesize > queue->mem_limit - queue->mem_used;
 }
 
+/* The mutex excludes limit changes; packet admission cannot raise this target. */
+static void nfqnl_mem_refund(struct nfqnl_instance *queue)
+{
+	u64 pages;
+
+	lockdep_assert_held(&queue->mem_mutex);
+	spin_lock_bh(&queue->lock);
+	pages = nfqnl_mem_pages(max(queue->mem_limit, queue->mem_used));
+	spin_unlock_bh(&queue->lock);
+
+	if (pages >= queue->memcg.pages)
+		return;
+
+	/* Shrinking cannot fail. Keep the packet-path copy conservative meanwhile. */
+	mem_cgroup_reservation_resize(&queue->memcg, pages);
+	spin_lock_bh(&queue->lock);
+	queue->mem_reserved = pages;
+	/* A final drain may have happened while the refund was in progress. */
+	if (!queue->mem_stopping &&
+	    pages > nfqnl_mem_pages(max(queue->mem_limit, queue->mem_used)))
+		queue_work(nfq_cleanup_wq, &queue->mem_work);
+	spin_unlock_bh(&queue->lock);
+}
+
+static void nfqnl_mem_work(struct work_struct *work)
+{
+	struct nfqnl_instance *queue =
+		container_of(work, struct nfqnl_instance, mem_work);
+
+	mutex_lock(&queue->mem_mutex);
+	nfqnl_mem_refund(queue);
+	mutex_unlock(&queue->mem_mutex);
+}
+
+static int nfqnl_set_config(struct nfqnl_instance *queue, unsigned int maxlen,
+			    const struct nfqnl_msg_config_params *params,
+			    u32 flags, u32 mask)
+{
+	u64 limit = nfqnl_mem_limit(maxlen);
+	u64 pages = nfqnl_mem_pages(limit);
+	unsigned int range = 0;
+	bool activated;
+	int err = 0;
+
+	if (params && params->copy_mode == NFQNL_COPY_PACKET) {
+		range = ntohl(params->copy_range);
+		if (!range || range > NFQNL_MAX_COPY_RANGE)
+			range = NFQNL_MAX_COPY_RANGE;
+	}
+
+	mutex_lock(&queue->mem_mutex);
+	activated = queue->mem_activated ||
+		    (params && params->copy_mode != NFQNL_COPY_NONE);
+	if (activated && pages > queue->memcg.pages && queue->memcg.objcg) {
+		err = mem_cgroup_reservation_resize(&queue->memcg, pages);
+		if (err)
+			goto out;
+	}
+	/* Publish activation only after the complete configuration is backed. */
+	spin_lock_bh(&queue->lock);
+	queue->queue_maxlen = maxlen;
+	queue->mem_limit = limit;
+	queue->mem_reserved = queue->memcg.objcg ? queue->memcg.pages : 0;
+	queue->mem_activated = activated;
+	if (params) {
+		queue->copy_range = range;
+		queue->copy_mode = params->copy_mode;
+	}
+	queue->flags = (queue->flags & ~mask) | (flags & mask);
+	spin_unlock_bh(&queue->lock);
+	if (activated && queue->memcg.objcg)
+		nfqnl_mem_refund(queue);
+out:
+	mutex_unlock(&queue->mem_mutex);
+	return err;
+}
+
 /* All release paths use the saved admission cost, including notification undo. */
 static void nfqnl_mem_uncharge(struct nfqnl_instance *queue,
 			       struct nf_queue_entry *entry)
@@ -160,10 +250,17 @@ static void nfqnl_mem_uncharge(struct nfqnl_instance *queue,
 	lockdep_assert_held(&queue->lock);
 	queue->mem_used -= entry->truesize;
 	entry->truesize = 0;
+	if (!queue->mem_stopping &&
+	    queue->mem_reserved >
+		    nfqnl_mem_pages(max(queue->mem_limit, queue->mem_used)))
+		queue_work(nfq_cleanup_wq, &queue->mem_work);
 }
 
 static struct nfqnl_instance *
-instance_create(struct nfnl_queue_net *q, u_int16_t queue_num, u32 portid)
+instance_create(struct net *net, struct nfnl_queue_net *q, u16 queue_num,
+		u32 portid, unsigned int maxlen,
+		const struct nfqnl_msg_config_params *params, u32 flags,
+		u32 mask)
 {
 	struct nfqnl_instance *inst;
 	unsigned int h;
@@ -175,16 +272,27 @@ instance_create(struct nfnl_queue_net *q, u_int16_t queue_num, u32 portid)
 
 	inst->queue_num = queue_num;
 	inst->peer_portid = portid;
-	inst->queue_maxlen = NFQNL_QMAX_DEFAULT;
-	inst->mem_limit = nfqnl_mem_limit(NFQNL_QMAX_DEFAULT);
+	inst->queue_maxlen = maxlen;
+	inst->mem_limit = nfqnl_mem_limit(maxlen);
 	inst->copy_range = NFQNL_MAX_COPY_RANGE;
 	inst->copy_mode = NFQNL_COPY_NONE;
 	spin_lock_init(&inst->lock);
+	mutex_init(&inst->mem_mutex);
+	INIT_WORK(&inst->mem_work, nfqnl_mem_work);
 	INIT_LIST_HEAD(&inst->queue_list);
 
-	err = rhashtable_init(&inst->nfqnl_packet_map, &nfqnl_rhashtable_params);
+	if (!net_eq(net, &init_net))
+		mem_cgroup_reservation_init(&inst->memcg);
+
+	err = rhashtable_init(&inst->nfqnl_packet_map,
+			      &nfqnl_rhashtable_params);
 	if (err < 0)
-		goto out_free;
+		goto out_reservation;
+
+	/* Keep packet readers from seeing a partially configured new queue. */
+	err = nfqnl_set_config(inst, maxlen, params, flags, mask);
+	if (err)
+		goto out_map;
 
 	spin_lock(&q->instances_lock);
 	if (instance_lookup(q, queue_num)) {
@@ -206,8 +314,11 @@ instance_create(struct nfnl_queue_net *q, u_int16_t queue_num, u32 portid)
 
 out_unlock:
 	spin_unlock(&q->instances_lock);
+out_map:
+	/* Unpublished instances have no entries or pending refund work. */
 	rhashtable_destroy(&inst->nfqnl_packet_map);
-out_free:
+out_reservation:
+	mem_cgroup_reservation_destroy(&inst->memcg);
 	kfree(inst);
 	return ERR_PTR(err);
 }
@@ -219,12 +330,18 @@ static void instance_destroy_work(struct work_struct *work)
 {
 	struct nfqnl_instance *inst;
 
-	inst = container_of(to_rcu_work(work), struct nfqnl_instance,
-			    rwork);
+	inst = container_of(to_rcu_work(work), struct nfqnl_instance, rwork);
+	/* The grace period has drained verdict readers, including detached batches. */
+	spin_lock_bh(&inst->lock);
+	inst->mem_stopping = true;
+	spin_unlock_bh(&inst->lock);
+	cancel_work_sync(&inst->mem_work);
+
 	rcu_read_lock();
 	nfqnl_flush(inst, NULL, 0);
 	rcu_read_unlock();
 	WARN_ON_ONCE(inst->mem_used);
+	mem_cgroup_reservation_destroy(&inst->memcg);
 
 	rhashtable_destroy(&inst->nfqnl_packet_map);
 
@@ -1526,37 +1643,6 @@ nfqnl_mangle(void *data, unsigned int data_len, struct nf_queue_entry *e, int di
 	return 0;
 }
 
-static int
-nfqnl_set_mode(struct nfqnl_instance *queue,
-	       unsigned char mode, unsigned int range)
-{
-	int status = 0;
-
-	spin_lock_bh(&queue->lock);
-	switch (mode) {
-	case NFQNL_COPY_NONE:
-	case NFQNL_COPY_META:
-		queue->copy_mode = mode;
-		queue->copy_range = 0;
-		break;
-
-	case NFQNL_COPY_PACKET:
-		queue->copy_mode = mode;
-		if (range == 0 || range > NFQNL_MAX_COPY_RANGE)
-			queue->copy_range = NFQNL_MAX_COPY_RANGE;
-		else
-			queue->copy_range = range;
-		break;
-
-	default:
-		status = -EINVAL;
-
-	}
-	spin_unlock_bh(&queue->lock);
-
-	return status;
-}
-
 static int
 dev_cmp(struct nf_queue_entry *entry, unsigned long ifindex)
 {
@@ -1975,12 +2061,14 @@ static const struct nf_queue_handler nfqh = {
 };
 
 static int nfqnl_recv_config(struct sk_buff *skb, const struct nfnl_info *info,
-			     const struct nlattr * const nfqa[])
+			     const struct nlattr *const nfqa[])
 {
 	struct nfnl_queue_net *q = nfnl_queue_pernet(info->net);
 	u_int16_t queue_num = ntohs(info->nfmsg->res_id);
 	struct nfqnl_msg_config_cmd *cmd = NULL;
 	struct nfqnl_instance *queue;
+	const struct nfqnl_msg_config_params *params = NULL;
+	unsigned int maxlen = NFQNL_QMAX_DEFAULT;
 	__u32 flags = 0, mask = 0;
 
 	WARN_ON_ONCE(!lockdep_nfnl_is_held(NFNL_SUBSYS_QUEUE));
@@ -2029,6 +2117,15 @@ static int nfqnl_recv_config(struct sk_buff *skb, const struct nfnl_info *info,
 		}
 	}
 
+	/* Validate before reserving capacity or publishing a newly bound queue. */
+	if (nfqa[NFQA_CFG_PARAMS]) {
+		params = nla_data(nfqa[NFQA_CFG_PARAMS]);
+		if (params->copy_mode > NFQNL_COPY_PACKET)
+			return -EINVAL;
+	}
+	if (nfqa[NFQA_CFG_QUEUE_MAXLEN])
+		maxlen = ntohl(nla_get_be32(nfqa[NFQA_CFG_QUEUE_MAXLEN]));
+
 	/* Lookup queue under RCU. After peer_portid check (or for new queue
 	 * in BIND case), the queue is owned by the socket sending this message.
 	 * nfqnl_rcv_nl_event() will block on the nfnl subsys mutex that is
@@ -2048,10 +2145,10 @@ static int nfqnl_recv_config(struct sk_buff *skb, const struct nfnl_info *info,
 		case NFQNL_CFG_CMD_BIND:
 			if (queue)
 				return -EBUSY;
-			queue = instance_create(q, queue_num, NETLINK_CB(skb).portid);
-			if (IS_ERR(queue))
-				return PTR_ERR(queue);
-			break;
+			queue = instance_create(info->net, q, queue_num,
+						NETLINK_CB(skb).portid, maxlen,
+						params, flags, mask);
+			return PTR_ERR_OR_ZERO(queue);
 		case NFQNL_CFG_CMD_UNBIND:
 			if (!queue)
 				return -ENODEV;
@@ -2068,31 +2165,9 @@ static int nfqnl_recv_config(struct sk_buff *skb, const struct nfnl_info *info,
 	if (!queue)
 		return -ENODEV;
 
-	if (nfqa[NFQA_CFG_PARAMS]) {
-		struct nfqnl_msg_config_params *params =
-			nla_data(nfqa[NFQA_CFG_PARAMS]);
-
-		nfqnl_set_mode(queue, params->copy_mode,
-				ntohl(params->copy_range));
-	}
-
-	if (nfqa[NFQA_CFG_QUEUE_MAXLEN]) {
-		__be32 *queue_maxlen = nla_data(nfqa[NFQA_CFG_QUEUE_MAXLEN]);
-
-		spin_lock_bh(&queue->lock);
-		queue->queue_maxlen = ntohl(*queue_maxlen);
-		queue->mem_limit = nfqnl_mem_limit(queue->queue_maxlen);
-		spin_unlock_bh(&queue->lock);
-	}
-
-	if (nfqa[NFQA_CFG_FLAGS]) {
-		spin_lock_bh(&queue->lock);
-		queue->flags &= ~mask;
-		queue->flags |= flags & mask;
-		spin_unlock_bh(&queue->lock);
-	}
-
-	return 0;
+	if (!nfqa[NFQA_CFG_QUEUE_MAXLEN])
+		maxlen = queue->queue_maxlen;
+	return nfqnl_set_config(queue, maxlen, params, flags, mask);
 }
 
 static const struct nfnl_callback nfqnl_cb[NFQNL_MSG_MAX] = {

-- 
2.34.1

