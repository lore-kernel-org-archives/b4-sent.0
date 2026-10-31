From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sat, 31 Oct 2026 15:54:05 +0000
Subject: [PATCH nf] netfilter: nft_set_rbtree: do not pair an expired start
 with another interval's end
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261031-b4-nft-rbtree-gc-v1-1-51d087c187a6@gmail.com>
X-B4-Tracking: v=1; b=H4sIABwP5moC/x3MPQqAMAxA4atIZgNtFUWvIg79SWuWKqmIIN7d4
 vgN7z1QSJgKzM0DQhcX3nOFbhvwm82JkEM1GGUGrTqNrsccTxR3ChEmjzpMfjTBWeMC1OwQinz
 /ywVyhPV9P2GHHG1mAAAA
To: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: netfilter-devel@vger.kernel.org, coreteam@netfilter.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793462044; l=6188;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=TXKOw0AxzyY7cMw4G7eFALzoeAvz3Y6zIv9RayVZTE4=;
 b=/rn2K5I4dav/QPkX0MaECT7axMWE8jro/pg2Q2KvcLdtZwbnQSGzDkOufsj8iPvvWTppNgxGE
 dk97FoPqZCiC6VN2jy53gJEmH+KX3tZjDswEu4TfzD/oZHO8eBxe3Yt
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Garbage collection of an expired interval start element also removes its
end element. Both the insertion path, nft_rbtree_gc_elem(), and the
commit path, nft_rbtree_gc_scan(), find that end element by its position
in the tree, and both can pick the end element of a different, live
interval:

- nft_rbtree_gc_elem() walks towards higher keys and skips end elements
  that are not active in both generations. If the end element of the
  expired interval is being deleted in the same transaction, the walk
  skips it, passes the start element of the next interval and takes that
  interval's end element instead.

- nft_rbtree_gc_scan() remembers the last end element it visited in
  rbe_end, but does not clear it when it visits a live start element. An
  expired start element without an end element (a start-only element, or
  an interval whose end element was already removed) then takes the end
  element of the live interval above it.

In both cases the live interval [S, E) loses E: the set no longer holds
the interval that userspace added, and deleting [S, E) later fails with
ENOENT.

In the insertion path, stop the walk at the first element that is active
in the current generation. Elements added by this transaction are still
skipped, as intended by commit 60c0c230c6f0 ("netfilter: nft_set_rbtree:
skip end interval element from gc"). If that element is a start element,
the expired interval has no end element. If it is an end element that
this transaction is removing, leave it to the transaction. In the commit
path, clear rbe_end when a live start element is visited.

Reproduced on current mainline under QEMU (arm64, KASAN), from an
unprivileged user in a new user and network namespace:

- insertion path: add [10,20) with a 50ms timeout and [30,40), wait,
  then in one batch delete the end element 20 and add [12,13).
  Before: a GET for 45 finds an element, the end element 40 is gone and
  deleting [30,40) fails with ENOENT. After: 45 is not found, 40 is
  present and the delete succeeds.

- commit path: add [30,40) and a start-only element 10 with a 50ms
  timeout to a set with a 100ms gc interval, wait, then add [200,201),
  whose insertion walk stops at the highest element, so only the
  commit-time scan reaches 10. Before: the end element 40 is gone and
  deleting [30,40) fails with ENOENT. After: both work.

Normal expiry, and a new interval whose end element shares the key of an
expired start element (the case handled by 60c0c230c6f0), behave the same
before and after. About 39000 random batches on interval sets with
timeouts, with and without slab/page allocation fault injection, showed
no KASAN, lockdep or WARN reports with the patch applied.

The insertion path issue was found with a small nfnetlink fuzzer. Both
paths had been pointed out earlier by the netdev AI review of commit
86b6471e690c ("netfilter: nft_set_rbtree: skip transaction elements
during GC"), see the Link below.

Fixes: f718863aca46 ("netfilter: nft_set_rbtree: fix overlap expiration walk")
Fixes: 8d8540c4f5e0 ("netfilter: nft_set_rbtree: add timeout support")
Link: https://lore.kernel.org/all/179063970372.3145.17414936987144600093@kernel.org/
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
Tool-use note: the fuzzer, the directed tests and the analysis were
prepared with help from an LLM-based assistant; I reviewed the change
and built and ran all tests myself. Test harness available on request.

This is a resend through the kernel.org web endpoint: my earlier
submission of this patch was blocked by my mail provider and never
reached the lists.
---
 net/netfilter/nft_set_rbtree.c | 23 +++++++++++++++++++----
 1 file changed, 19 insertions(+), 4 deletions(-)

diff --git a/net/netfilter/nft_set_rbtree.c b/net/netfilter/nft_set_rbtree.c
index fbe1750f1..086823067 100644
--- a/net/netfilter/nft_set_rbtree.c
+++ b/net/netfilter/nft_set_rbtree.c
@@ -215,17 +215,25 @@ nft_rbtree_gc_elem(const struct nft_set *__set, struct nft_rbtree *priv,
 	struct nft_set *set = (struct nft_set *)__set;
 	struct rb_node *prev = rb_prev(&rbe->node);
 	struct net *net = read_pnet(&set->net);
+	u8 cur_genmask = nft_genmask_cur(net);
 	struct nft_rbtree_elem *rbe_prev;
 
 	/* search for end interval coming before this element.
 	 * end intervals don't carry a timeout extension, they
 	 * are coupled with the interval start element.
+	 *
+	 * Skip elements added in this transaction. The first element
+	 * that is active in the current generation is either the end
+	 * element of this interval or the start element of another
+	 * interval, in which case this interval has no end element.
 	 */
 	while (prev) {
 		rbe_prev = rb_entry(prev, struct nft_rbtree_elem, node);
-		if (nft_rbtree_interval_end(rbe_prev) &&
-		    nft_set_elem_active(&rbe_prev->ext, NFT_GENMASK_ANY))
+		if (nft_set_elem_active(&rbe_prev->ext, cur_genmask)) {
+			if (!nft_rbtree_interval_end(rbe_prev))
+				prev = NULL;
 			break;
+		}
 
 		prev = rb_prev(prev);
 	}
@@ -233,7 +241,11 @@ nft_rbtree_gc_elem(const struct nft_set *__set, struct nft_rbtree *priv,
 	rbe_prev = NULL;
 	if (prev) {
 		rbe_prev = rb_entry(prev, struct nft_rbtree_elem, node);
-		nft_rbtree_gc_elem_move(net, set, priv, rbe_prev);
+		/* end element is being removed by this transaction */
+		if (nft_set_elem_active(&rbe_prev->ext, NFT_GENMASK_ANY))
+			nft_rbtree_gc_elem_move(net, set, priv, rbe_prev);
+		else
+			rbe_prev = NULL;
 	}
 
 	nft_rbtree_gc_elem_move(net, set, priv, rbe);
@@ -911,8 +923,11 @@ static void nft_rbtree_gc_scan(struct nft_set *set)
 			rbe_end = rbe;
 			continue;
 		}
-		if (!__nft_set_elem_expired(&rbe->ext, tstamp))
+		if (!__nft_set_elem_expired(&rbe->ext, tstamp)) {
+			/* rbe_end belongs to this live interval */
+			rbe_end = NULL;
 			continue;
+		}
 
 		/* end element needs to be removed first, it has
 		 * no timeout extension.

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261031-b4-nft-rbtree-gc-1d9c72dba2bd

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

