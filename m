From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 10 Aug 2026 15:01:02 +0200
Subject: [PATCH v4 1/3] net: enforce net sysctl registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-jag-net_const_qualify-v4-1-77e888237c69@kernel.org>
References: <20260810-jag-net_const_qualify-v4-0-77e888237c69@kernel.org>
In-Reply-To: <20260810-jag-net_const_qualify-v4-0-77e888237c69@kernel.org>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ido Schimmel <idosch@nvidia.com>, 
 Pablo Neira Ayuso <pablo@netfilter.org>, Florian Westphal <fw@strlen.de>, 
 Phil Sutter <phil@nwl.cc>, 
 Marcelo Ricardo Leitner <marcelo.leitner@gmail.com>, 
 Xin Long <lucien.xin@gmail.com>, 
 Steffen Klassert <steffen.klassert@secunet.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Kuniyuki Iwashima <kuniyu@google.com>, 
 Stefano Garzarella <sgarzare@redhat.com>
Cc: chia-yu.chang@nokia-bell-labs.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-sctp@vger.kernel.org, 
 linux-rdma@vger.kernel.org, linux-s390@vger.kernel.org, 
 virtualization@lists.linux.dev, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3588;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=fdM8YlvZqAkxic7f4H5puGcsJ5qBOUt62SzUItEjpmc=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGp5y5zIDtqCE0WpbZ/huPU0NcAcyVVhSsTlhDilbHbBijTuP
 4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqecucAAoJELqXzVK3lkFPhPEL/09O
 X0yi4CZjcZNE0SwKtiTgqPFkkc7omc52D1l40F5KtGaE3mUjQziRXnT9z40zAfEoYLEVPhGKfPc
 7ghTop4RnK3TXnzPRImsSS2hqZ6SwXjWNansCXsLr2J6rDZ7ShnSTd39nik+dslNxnGHuvC4drF
 8zh1MndHBRtbMawGyBoDajXKYH/cmLAX99/Z6ekjU9+wMyZ/DHy5D/BU87Bb1gsllcaOIkoQ3qy
 t8/NjkQNQPA9LFcUmMXpd38MU4vNpqDSEiRJP9Tj/ncGz91gTo3jhDIX0dBmLx7EsVCoci0hbsY
 cz2eWaSEzA5iE5W6BXlXewexyDSZF27D7r7CtLIAAcqAUKbZTL0v0ReE8tgHli7mw3z5NRKtPXt
 2mpQbVsVSMCYl85BqCoJhF4yfr+fqLs04SPnkQvn2o9WZcZi1rEiIY+pImf+HFb/befNMSMIBR/
 F4abhqohhKAlaRw4xDhvAXkM1nuXszGiGA9J+L4ZRKhTYJ54qaJXIYtXdzcw==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the warning and file permission change with an error when an
"unsafe" net sysctl registration is detected.

One of the barriers preventing the const qualification of the ctl_tables
in the net directory is the permission (->mode) change in
ensure_safe_net_sysctl. This prep commit removes that barrier and
ensures that the received ctl_table pointer to the net ctl_table
register function is const.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/net/net_namespace.h |  5 +++--
 net/sysctl_net.c            | 25 +++++++++++++------------
 2 files changed, 16 insertions(+), 14 deletions(-)

diff --git a/include/net/net_namespace.h b/include/net/net_namespace.h
index 501af1999fe8393d7c282a87645d1c4ceabadddc..e5ee673b9fcf846aefcc309d4cca1a8fc870aae2 100644
--- a/include/net/net_namespace.h
+++ b/include/net/net_namespace.h
@@ -525,12 +525,13 @@ struct ctl_table;
 #ifdef CONFIG_SYSCTL
 int net_sysctl_init(void);
 struct ctl_table_header *register_net_sysctl_sz(struct net *net, const char *path,
-					     struct ctl_table *table, size_t table_size);
+						const struct ctl_table *table,
+						size_t table_size);
 void unregister_net_sysctl_table(struct ctl_table_header *header);
 #else
 static inline int net_sysctl_init(void) { return 0; }
 static inline struct ctl_table_header *register_net_sysctl_sz(struct net *net,
-	const char *path, struct ctl_table *table, size_t table_size)
+	const char *path, const struct ctl_table *table, size_t table_size)
 {
 	return NULL;
 }
diff --git a/net/sysctl_net.c b/net/sysctl_net.c
index 19e8048241bacb18de853d3b904d0f97fd2fe78a..07f8434d4258c615c231ca7e29274de44b012665 100644
--- a/net/sysctl_net.c
+++ b/net/sysctl_net.c
@@ -114,16 +114,17 @@ __init int net_sysctl_init(void)
 	goto out;
 }
 
-/* Verify that sysctls for non-init netns are safe by either:
+/* Return error when sysctls for non-init netns are unsafe by verifying:
  * 1) being read-only, or
  * 2) having a data pointer which points outside of the global kernel/module
  *    data segment, and rather into the heap where a per-net object was
  *    allocated.
  */
-static void ensure_safe_net_sysctl(struct net *net, const char *path,
-				   struct ctl_table *table, size_t table_size)
+static int ensure_safe_net_sysctl(struct net *net, const char *path,
+				  const struct ctl_table *table,
+				  size_t table_size)
 {
-	struct ctl_table *ent;
+	const struct ctl_table *ent;
 
 	pr_debug("Registering net sysctl (net %p): %s\n", net, path);
 	ent = table;
@@ -149,24 +150,24 @@ static void ensure_safe_net_sysctl(struct net *net, const char *path,
 		else
 			continue;
 
-		/* If it is writable and points to kernel/module global
-		 * data, then it's probably a netns leak.
-		 */
+		/* Warn on netns leak. */
 		WARN(1, "sysctl %s/%s: data points to %s global data: %ps\n",
-		     path, ent->procname, where, ent->data);
+			path, ent->procname, where, ent->data);
 
-		/* Make it "safe" by dropping writable perms */
-		ent->mode &= ~0222;
+		return -EACCES;
 	}
+
+	return 0;
 }
 
 struct ctl_table_header *register_net_sysctl_sz(struct net *net,
 						const char *path,
-						struct ctl_table *table,
+						const struct ctl_table *table,
 						size_t table_size)
 {
 	if (!net_eq(net, &init_net))
-		ensure_safe_net_sysctl(net, path, table, table_size);
+		if (ensure_safe_net_sysctl(net, path, table, table_size))
+			return NULL;
 
 	return __register_sysctl_table(&net->sysctls, path, table, table_size);
 }

-- 
2.50.1

