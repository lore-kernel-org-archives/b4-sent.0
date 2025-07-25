From: Christoph Paasch <cpaasch@openai.com>
Date: Thu, 24 Jul 2025 17:10:36 -0700
Subject: [PATCH net-next] net: Make nexthop-dumps scale linearly with the
 number of nexthops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250724-nexthop_dump-v1-1-6b43fffd5bac@openai.com>
X-B4-Tracking: v=1; b=H4sIAHvLgmgC/x2MQQqAIBAAvxJ7TqjNCvpKRJSutYdM1CII/550H
 JiZFwJ5pgBD8YKnmwOfNkNdFqD2xW4kWGcGrLCtepTC0hP30836OpwwnWpQ9rgqbSAnzpPh59+
 NYCn+NkwpfRp1G29oAAAA
X-Change-ID: 20250724-nexthop_dump-f6c32472bcdf
To: David Ahern <dsahern@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, Christoph Paasch <cpaasch@openai.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753402252; l=2979;
 i=cpaasch@openai.com; s=20250712; h=from:subject:message-id;
 bh=OGj1vCxWdoON+IaCcR0ZPs8gUo7LoLsrnae+RDRjLoU=;
 b=37Zou509rbRFVibQp3dEhNVLxItcBxrDZ0BMrpj0yL7mEE2SDxSfCANIYqkMEhxqCjhw8hm3U
 gsjlSbfyf78AzMITKoZGUy0Th6HQIKYzZrfrrZGrHC/MN0sH1Z36+XL
X-Developer-Key: i=cpaasch@openai.com; a=ed25519;
 pk=1HRHZlVUZPziMZvsAQFvP7n5+uEosTDAjXmNXykdxdg=
X-Endpoint-Received: by B4 Relay for cpaasch@openai.com/20250712 with auth_id=459
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When we have a (very) large number of nexthops, they do not fit within a
single message. rtm_dump_walk_nexthops() thus will be called repeatedly
and ctx->idx is used to avoid dumping the same nexthops again.

The approach in which we avoid dumpint the same nexthops is by basically
walking the entire nexthop rb-tree from the left-most node until we find
a node whose id is >= s_idx. That does not scale well.

Instead of this non-efficient  approach, rather go directly through the
tree to the nexthop that should be dumped (the one whose nh_id >=
s_idx). This allows us to find the relevant node in O(log(n)).

We have quite a nice improvement with this:

Before:
=======

--> ~1M nexthops:
$ time ~/libnl/src/nl-nh-list | wc -l
1050624

real	0m21.080s
user	0m0.666s
sys	0m20.384s

--> ~2M nexthops:
$ time ~/libnl/src/nl-nh-list | wc -l
2101248

real	1m51.649s
user	0m1.540s
sys	1m49.908s

After:
======

--> ~1M nexthops:
$ time ~/libnl/src/nl-nh-list | wc -l
1050624

real	0m1.157s
user	0m0.926s
sys	0m0.259s

--> ~2M nexthops:
$ time ~/libnl/src/nl-nh-list | wc -l
2101248

real	0m2.763s
user	0m2.042s
sys	0m0.776s

Signed-off-by: Christoph Paasch <cpaasch@openai.com>
---
 net/ipv4/nexthop.c | 34 +++++++++++++++++++++++++++++++++-
 1 file changed, 33 insertions(+), 1 deletion(-)

diff --git a/net/ipv4/nexthop.c b/net/ipv4/nexthop.c
index 29118c43ebf5f1e91292fe227d4afde313e564bb..226447b1c17d22eab9121bed88c0c2b9148884ac 100644
--- a/net/ipv4/nexthop.c
+++ b/net/ipv4/nexthop.c
@@ -3511,7 +3511,39 @@ static int rtm_dump_walk_nexthops(struct sk_buff *skb,
 	int err;
 
 	s_idx = ctx->idx;
-	for (node = rb_first(root); node; node = rb_next(node)) {
+
+	/*
+	 * If this is not the first invocation, ctx->idx will contain the id of
+	 * the last nexthop we processed.  Instead of starting from the very first
+	 * element of the red/black tree again and linearly skipping the
+	 * (potentially large) set of nodes with an id smaller than s_idx, walk the
+	 * tree and find the left-most node whose id is >= s_idx.  This provides an
+	 * efficient O(log n) starting point for the dump continuation.
+	 */
+	if (s_idx != 0) {
+		struct rb_node *tmp = root->rb_node;
+
+		node = NULL;
+		while (tmp) {
+			struct nexthop *nh;
+
+			nh = rb_entry(tmp, struct nexthop, rb_node);
+			if (nh->id < s_idx) {
+				tmp = tmp->rb_right;
+			} else {
+				/* Track current candidate and keep looking on
+				 * the left side to find the left-most
+				 * (smallest id) that is still >= s_idx.
+				 */
+				node = tmp;
+				tmp = tmp->rb_left;
+			}
+		}
+	} else {
+		node = rb_first(root);
+	}
+
+	for (; node; node = rb_next(node)) {
 		struct nexthop *nh;
 
 		nh = rb_entry(node, struct nexthop, rb_node);

---
base-commit: 8b5a19b4ff6a2096225d88cf24cfeef03edc1bed
change-id: 20250724-nexthop_dump-f6c32472bcdf

Best regards,
-- 
Christoph Paasch <cpaasch@openai.com>

