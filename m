From: =?utf-8?q?Dani=C3=ABl_Trujillo?= <datrujillo@nvidia.com>
Date: Thu, 08 Oct 2026 22:10:49 +0000
Subject: [PATCH net] ipv4: fib_trie: prevent speculative out-of-bounds
 child access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261008-fib-trie-nospec-v1-1-fa18726d485e@nvidia.com>
X-B4-Tracking: v=1; b=H4sIAOgUyGoC/yWMwQqDMBAFf0XeuQsxoIb+SvFQ17XdHqJkowjiv
 ze2xxmYOWCSVAz36kCSTU3nWKC+VeD3M76EdCwM73xbOxdo0oFySSjOtghTw13rfOAgHaNUS5J
 J99/xgSgZ/V/aOnyE8/XCeX4BztmtWHgAAAA=
X-Change-ID: 20261008-fib-trie-nospec-5c76028c8e7c
To: David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, 
 Alexander Duyck <alexander.h.duyck@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, 
 =?utf-8?q?Dani=C3=ABl_Trujillo?= <datrujillo@nvidia.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791497449; l=1811;
 i=datrujillo@nvidia.com; s=20261008; h=from:subject:message-id;
 bh=xnFr+ktZBjHYJMb2dgrr672XmryMDvsweL3LbYJlrKI=;
 b=QAIQxu04rBsFZ4Fxj+43aqwMG1AkLo/JzAr74GzYjH648cOjifagKJGv9Z2KIMVti4++R5V3l
 /eM9rxWRIKUBvPsm4W0RllZ8H1X8B5SEr9fTvgVPZmfC0wq1gOJB7EE
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
child array is then treated as a node pointer. The next loop iteration
dereferences that transient pointer through get_cindex(), causing a
page-table walk whose cache footprint can leak (parts of) the pointer.

Sanitize the index with array_index_nospec() before accessing the child
array.

Fixes: 9f9e636d4f89 ("fib_trie: Optimize fib_table_lookup to avoid wasting time on loops/variables")
Cc: stable@vger.kernel.org
Signed-off-by: Daniël Trujillo <datrujillo@nvidia.com>
---
 net/ipv4/fib_trie.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/ipv4/fib_trie.c b/net/ipv4/fib_trie.c
index 248514dce0cd..bd8a368c5502 100644
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
@@ -1474,6 +1475,7 @@ int fib_table_lookup(struct fib_table *tb, const struct flowi4 *flp,
 			cindex = index;
 		}
 
+		index = array_index_nospec(index, 1ul << n->bits);
 		n = get_child_rcu(n, index);
 		if (unlikely(!n))
 			goto backtrace;

---
base-commit: 37f12441f557468a56c1e27790413aa78c82afa2
change-id: 20261008-fib-trie-nospec-5c76028c8e7c

Best regards,
--  
Daniël Trujillo <datrujillo@nvidia.com>

