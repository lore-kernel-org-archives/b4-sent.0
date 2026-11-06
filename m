From: =?utf-8?q?Dani=C3=ABl_Trujillo?= <datrujillo@nvidia.com>
Date: Fri, 06 Nov 2026 05:02:23 +0000
Subject: [PATCH net v3] ipv4: fib_trie: prevent speculative out-of-bounds
 child access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261106-fib-trie-nospec-v3-1-53da6550dcf8@nvidia.com>
X-B4-Tracking: v=1; b=H4sIAF5f7WoC/3XNTQ7CIBAF4KsY1mKA/qEr72FcFJjaMREaQKJpe
 ncpbjTG5Zu8981MAniEQA6bmXhIGNDZHKrthuixtxegaHImgomWMybpgIrGPKHWhQk0bXTXMiG
 1hE6TvJo8DPgo4olYiOT8Poa7uoKOq7XWRgzR+Wf5m3gp/32ROOV06LnsRGtq2cDRJjTY77S7F
 T6JD4CzX0BkoGIV36vaKGnYF7AsywtOGBkaBwEAAA==
X-Change-ID: 20261008-fib-trie-nospec-5c76028c8e7c
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?Dani=C3=ABl_Trujillo?= <datrujillo@nvidia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793941344; l=5447;
 i=datrujillo@nvidia.com; s=20261008; h=from:subject:message-id;
 bh=5c7YINK8sjo1SrfVNltMm2KMO1jVWrBXalQL2Wr8bkA=;
 b=Z6qQ/lszbof05Q5gSAbauvuwAu6MsKLFgkjXGFMRArOgu5BrHZ1In+z4rdMR/2GTgXIdoOUOH
 49V2s6kwhXeByzS36DUIbQ4XixZDpouTIYi3o9h8Eu0zV2+hF4X1TeL
X-Developer-Key: i=datrujillo@nvidia.com; a=ed25519;
 pk=AP24zUwENFy2geglpKJAA8oaT41tkteCL9hTWGd88rs=
X-Endpoint-Received: by B4 Relay for datrujillo@nvidia.com/20261008 with auth_id=1128
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fib_table_lookup() checks the child index against the bounds before
passing it to get_child_rcu().

The index is derived from the lookup key, which in turn is derived from
flp->daddr. A userspace process can therefore influence the index by
triggering lookups for chosen destination IPv4 addresses.

If this bounds check is mispredicted as in-bounds, an out-of-bounds index
can be transiently passed to get_child_rcu(). The value loaded beyond the
child array is then treated as a node pointer. A later transient
dereference of that pointer can cause a data-dependent cache footprint.

This was found during Spectre-v1 research. Leakage was demonstrated with
instrumentation that delays branch resolution with a CLFLUSH before the
mispredicted branch and makes the leaked location deterministic for
reproducible measurement. In that setup, a userspace-controlled IPv4
lookup key was able to trigger a transient out-of-bounds child access.
The transient use of the loaded value as a pointer caused a
data-dependent cache footprint that was recoverable from userspace using
Prime+Probe. A real-world attacker would likely need to delay branch
resolution, which was not demonstrated end-to-end without the added
CLFLUSH.

Sanitize the index with array_index_nospec() before accessing the child
array. This removed the observed leakage in the described setup.

Apply the hardening before setting cindex in fib_table_lookup(), because
cindex can later be used by the backtrace path to load another child
pointer. fib_find_node() has the same pattern, with the checked index
derived from a user-provided key in fib_table_insert() and
fib_table_delete(). leaf_walk_rcu() has a similar checked cindex before
get_child_rcu(), and the traversed state can be influenced by userspace
actions. fib_find_node() runs under RTNL and leaf_walk_rcu() is not on
the packet lookup hot path, so harden those analogous accesses in the
same way. Also harden fib_trie_get_next(), where a mispredicted loop
condition could transiently read one child past the array.

I see a slowdown of roughly 10% in a microbenchmark where we call
fib_table_lookup() with 64 routes directly from inside the kernel. I
observed no slowdown in a loopback UDP sendto() microbenchmark.

Fixes: 9f9e636d4f89 ("fib_trie: Optimize fib_table_lookup to avoid wasting time on loops/variables")
Cc: stable@vger.kernel.org
Reviewed-by: Eric Dumazet <edumazet@kernel.org>
Signed-off-by: Daniël Trujillo <datrujillo@nvidia.com>
---
Changes in v3:
- Harden fib_trie_get_next() against a speculative one-past-the-end child
  access, as suggested by Sashiko.
- Explain the procfs iterator case in the changelog.
- Add direct lookup and UDP send-path benchmark results to the changelog.
- Link to v2: https://patch.msgid.link/20261010-fib-trie-nospec-v2-1-30319b4db8d0@nvidia.com

Changes in v2:
- Move array_index_nospec() before cindex is set in
  fib_table_lookup() so the backtrace path cannot use an out-of-bounds index
  (Eric Dumazet).
- Apply the same hardening to fib_find_node() and leaf_walk_rcu()
  (Eric Dumazet).
- Add discovery/testing details of the gadget to the changelog.
- Link to v1: https://patch.msgid.link/20261008-fib-trie-nospec-v1-1-fa18726d485e@nvidia.com
---
 net/ipv4/fib_trie.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/net/ipv4/fib_trie.c b/net/ipv4/fib_trie.c
index be1e40780ad7..394df1de1281 100644
--- a/net/ipv4/fib_trie.c
+++ b/net/ipv4/fib_trie.c
@@ -61,6 +61,7 @@
 #include <linux/export.h>
 #include <linux/vmalloc.h>
 #include <linux/notifier.h>
+#include <linux/nospec.h>
 #include <net/net_namespace.h>
 #include <net/inet_dscp.h>
 #include <net/ip.h>
@@ -961,6 +962,8 @@ static struct key_vector *fib_find_node(struct trie *t,
 			break;
 		}
 
+		index = array_index_nospec(index, 1ul << n->bits);
+
 		/* keep searching until we find a perfect match leaf or NULL */
 	} while (IS_TNODE(n));
 
@@ -1467,6 +1470,8 @@ int fib_table_lookup(struct fib_table *tb, const struct flowi4 *flp,
 		if (IS_LEAF(n))
 			goto found;
 
+		index = array_index_nospec(index, 1ul << n->bits);
+
 		/* only record pn and cindex if we are going to be chopping
 		 * bits later.  Otherwise we are just wasting cycles.
 		 */
@@ -1770,6 +1775,8 @@ static struct key_vector *leaf_walk_rcu(struct key_vector **tn, t_key key)
 		if (cindex >> pn->bits)
 			break;
 
+		cindex = array_index_nospec(cindex, 1ul << pn->bits);
+
 		/* descend into the next child */
 		n = get_child_rcu(pn, cindex++);
 		if (!n)
@@ -1791,6 +1798,8 @@ static struct key_vector *leaf_walk_rcu(struct key_vector **tn, t_key key)
 			continue;
 		}
 
+		cindex = array_index_nospec(cindex, 1ul << pn->bits);
+
 		/* grab the next available node */
 		n = get_child_rcu(pn, cindex++);
 		if (!n)
@@ -2437,7 +2446,10 @@ static struct key_vector *fib_trie_get_next(struct fib_trie_iter *iter)
 
 	while (!IS_TRIE(pn)) {
 		while (cindex < child_length(pn)) {
-			struct key_vector *n = get_child_rcu(pn, cindex++);
+			struct key_vector *n;
+
+			cindex = array_index_nospec(cindex, child_length(pn));
+			n = get_child_rcu(pn, cindex++);
 
 			if (!n)
 				continue;

---
base-commit: f66469d9905b39d2c260a15d7d6db450f4db67c1
change-id: 20261008-fib-trie-nospec-5c76028c8e7c

Best regards,
--  
Daniël Trujillo <datrujillo@nvidia.com>

