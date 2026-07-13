From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Jul 2026 13:07:42 +0200
Subject: [PATCH RFC net-next v3 1/3] net: enforce net sysctl registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-jag-net_const_qualify-v3-1-7289fe9eaea6@kernel.org>
References: <20260713-jag-net_const_qualify-v3-0-7289fe9eaea6@kernel.org>
In-Reply-To: <20260713-jag-net_const_qualify-v3-0-7289fe9eaea6@kernel.org>
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
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netfilter-devel@vger.kernel.org, coreteam@netfilter.org, 
 linux-sctp@vger.kernel.org, linux-rdma@vger.kernel.org, 
 linux-s390@vger.kernel.org, virtualization@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3574;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=gFPfNAZb5Emut5tl59jtS1GCSawh67g0IOaptPFibj4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpUxwZskgenDOU98txc57mfzp9zCAPadshX1
 w9t16Ag3hXFGYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqVMcGAAoJELqXzVK3
 lkFPFuML/RuQe3IepvdaZwOqXPTFSxjiaQ9bHG5EjMlqTZJymTxUXke4CX6cffYqR8LOCXv/zqI
 Xz6yMTCeEaKdC/KbKlarrXHYnX0dUo/F3SqzxbWAoouVQN77rnoI7iQbY+TDK0GEy2zZONsm95u
 Vf+EfOQeGZuxwgpbCYUR8IBhhpqcVfuF0vI8vaxi7bhmmK30aRoBtLG+WYyHIgf/N7CXmGwRFxC
 yDHVArNMtiBNObUr0CVTFLxn8/BXuAIVrsNttsPGQm6aDvm3AQd87+wUS2otzOefZp82bJUl73e
 IzkI9JlAq/XN9dgNUEPdpolmegObR57+ikTaZzNrILLpVchdIIKBR4cZfPkGGVcjwBnrXrvM9Zy
 kksDs+AIzzP/SDuNq8GseNIMT37Jo/NFsSdfK+eblk8DVjuKx+gEwV7GHjkzZkGe6PEWWgIhT8f
 uCYW4EEdIC4+bpgG8ygVgbaTDyA1+W81V10LuKN5vBvLR6iuqzESCQGH1rg5ryeHGO+tKQvK3f8
 Ig=
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
 include/net/net_namespace.h |  4 ++--
 net/sysctl_net.c            | 24 ++++++++++++------------
 2 files changed, 14 insertions(+), 14 deletions(-)

diff --git a/include/net/net_namespace.h b/include/net/net_namespace.h
index 80de5e98a66d6c9273aa7c5b9d489b22cef8559a..dca0ec809483bec604f4ca3d99dfea32834af8fa 100644
--- a/include/net/net_namespace.h
+++ b/include/net/net_namespace.h
@@ -522,12 +522,12 @@ struct ctl_table;
 #ifdef CONFIG_SYSCTL
 int net_sysctl_init(void);
 struct ctl_table_header *register_net_sysctl_sz(struct net *net, const char *path,
-					     struct ctl_table *table, size_t table_size);
+					     const struct ctl_table *table, size_t table_size);
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
index 19e8048241bacb18de853d3b904d0f97fd2fe78a..4714887113d90a191c300c9c49a6317d5609efeb 100644
--- a/net/sysctl_net.c
+++ b/net/sysctl_net.c
@@ -114,16 +114,16 @@ __init int net_sysctl_init(void)
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
+				  const struct ctl_table *table, size_t table_size)
 {
-	struct ctl_table *ent;
+	const struct ctl_table *ent;
 
 	pr_debug("Registering net sysctl (net %p): %s\n", net, path);
 	ent = table;
@@ -149,24 +149,24 @@ static void ensure_safe_net_sysctl(struct net *net, const char *path,
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

