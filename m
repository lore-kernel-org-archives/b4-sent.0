From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 10 Aug 2026 15:01:04 +0200
Subject: [PATCH v4 3/3] net: Const qualify network templated ctl_tables
 Arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260810-jag-net_const_qualify-v4-3-77e888237c69@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=13709;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=mfG7Azw81hPEVdqzwgIOg8Z+aGmBTWEtxIP+wtpAXiY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGp5y53Tj1wbx1niL50rI9zUuw4Po8QHCSOxm
 dq7OT3P7cqBVokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqecudAAoJELqXzVK3
 lkFPKpUL/3FC3496puI/yFKlPtUQ5Ei426Wr1E2Y0oJGWl7bLOF8SQAA1FBeo1bd+3GxxC1aer/
 zbfxAkDxpPLyhiDSA49Kv5d7PYXeeOXnD1kj/mQ3TrNb2w8o+0ATO5gbmGKe3Ddzh8UafOAHk0D
 IWOszlNtDoK3ybUNy39cs20v+IvgPsZP0IPPNKwvWD2vB3y6QUyPom6g8VAb9q46BGSHIgHIpLJ
 reKb6mfImtGrcgU5yHO1hwbAG9bM096lato6BGKIzdg181veV3Gu42qERsSzuAltXOsJzhbrBmh
 cf8rWvC1FNOyJqTEVxXovilBDtym1QZ2dzgyR9JOKNJXYcBlj2C9Vi1jFf6KO6mk8X8JvYoZvPc
 3AeTyXCPkVYhp4XG/wzIRJGfmj7N+prPlkYnHxQ3k/gDkY+FJqf7oKAO/FpiJ0YUxxDD5E1MgPg
 sUTJ38N4xUPRQXuSeXhLifoH4VFS1asaPbeW5t8uABEGZjD5PE6DVBSYxyEQ1GBiEqi29KAxy86
 8c=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add duplication helpers in the cases where the ctl_table array elements
are modified after duplication. Helpers return a ctl_table as const
pointer allowing the const qualification of the static global ctl_table
array.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 net/core/sysctl_net_core.c        | 38 +++++++++++++++++----------
 net/ipv4/sysctl_net_ipv4.c        | 54 +++++++++++++++++++++++----------------
 net/ipv4/xfrm4_policy.c           | 22 ++++++++++++----
 net/ipv6/xfrm6_policy.c           | 22 ++++++++++++----
 net/netfilter/nf_hooks_lwtunnel.c |  4 +--
 net/smc/smc_sysctl.c              | 26 ++++++++++++++-----
 net/unix/sysctl_net_unix.c        | 21 +++++++++++----
 net/vmw_vsock/af_vsock.c          | 25 +++++++++++++-----
 8 files changed, 146 insertions(+), 66 deletions(-)

diff --git a/net/core/sysctl_net_core.c b/net/core/sysctl_net_core.c
index b508618bfc12393ba926ebf5a2dd4ea73ef03ee8..eb35da3556f4aa00cecd4582ab94e339d2518506 100644
--- a/net/core/sysctl_net_core.c
+++ b/net/core/sysctl_net_core.c
@@ -678,7 +678,7 @@ static struct ctl_table net_core_table[] = {
 	},
 };
 
-static struct ctl_table netns_core_table[] = {
+static const struct ctl_table netns_core_table[] = {
 #if IS_ENABLED(CONFIG_RPS)
 	{
 		.procname	= "rps_default_mask",
@@ -787,26 +787,38 @@ static int __init fb_tunnels_only_for_init_net_sysctl_setup(char *str)
 }
 __setup("fb_tunnels=", fb_tunnels_only_for_init_net_sysctl_setup);
 
-static __net_init int sysctl_core_net_init(struct net *net)
+static const struct ctl_table *netns_core_table_dup(struct net *net)
 {
 	size_t table_size = ARRAY_SIZE(netns_core_table);
 	struct ctl_table *tbl;
+	int i;
+
+	tbl = kmemdup(netns_core_table, sizeof(netns_core_table), GFP_KERNEL);
+	if (!tbl)
+		return NULL;
+
+	for (i = 0; i < table_size; ++i) {
+		if (tbl[i].data == &sysctl_wmem_max)
+			break;
+
+		tbl[i].data += (char *)net - (char *)&init_net;
+	}
+	for (; i < table_size; ++i)
+		tbl[i].mode &= ~0222;
+
+	return tbl;
+}
+
+static __net_init int sysctl_core_net_init(struct net *net)
+{
+	size_t table_size = ARRAY_SIZE(netns_core_table);
+	const struct ctl_table *tbl;
 
 	tbl = netns_core_table;
 	if (!net_eq(net, &init_net)) {
-		int i;
-		tbl = kmemdup(tbl, sizeof(netns_core_table), GFP_KERNEL);
+		tbl = netns_core_table_dup(net);
 		if (tbl == NULL)
 			goto err_dup;
-
-		for (i = 0; i < table_size; ++i) {
-			if (tbl[i].data == &sysctl_wmem_max)
-				break;
-
-			tbl[i].data += (char *)net - (char *)&init_net;
-		}
-		for (; i < table_size; ++i)
-			tbl[i].mode &= ~0222;
 	}
 
 	net->core.sysctl_hdr = register_net_sysctl_sz(net, "net/core", tbl, table_size);
diff --git a/net/ipv4/sysctl_net_ipv4.c b/net/ipv4/sysctl_net_ipv4.c
index ca1180dba1dea9ce72028ba49b7f953da343336b..2f0363bca2a88d68276670cfce6fb04398f82bc5 100644
--- a/net/ipv4/sysctl_net_ipv4.c
+++ b/net/ipv4/sysctl_net_ipv4.c
@@ -624,7 +624,7 @@ static struct ctl_table ipv4_table[] = {
 	},
 };
 
-static struct ctl_table ipv4_net_table[] = {
+static const struct ctl_table ipv4_net_table[] = {
 	{
 		.procname	= "tcp_max_tw_buckets",
 		.data		= &init_net.ipv4.tcp_death_row.sysctl_max_tw_buckets,
@@ -1654,35 +1654,45 @@ static struct ctl_table ipv4_net_table[] = {
 	},
 };
 
-static __net_init int ipv4_sysctl_init_net(struct net *net)
+static const struct ctl_table *ipv4_net_table_dup(struct net *net)
 {
 	size_t table_size = ARRAY_SIZE(ipv4_net_table);
 	struct ctl_table *table;
+	int i;
+
+	table = kmemdup(ipv4_net_table, sizeof(ipv4_net_table), GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	for (i = 0; i < table_size; i++) {
+		if (table[i].data) {
+			/* Update the variables to point into
+			 * the current struct net
+			 */
+			table[i].data += (void *)net - (void *)&init_net;
+		} else {
+			/* Entries without data pointer are global;
+			 * Make them read-only in non-init_net ns
+			 */
+			table[i].mode &= ~0222;
+		}
+		if (table[i].extra2 >= (void *)&init_net.ipv4 &&
+		    table[i].extra2 < (void *)(&init_net.ipv4 + 1))
+			table[i].extra2 += (void *)net - (void *)&init_net;
+	}
+	return table;
+}
+
+static __net_init int ipv4_sysctl_init_net(struct net *net)
+{
+	size_t table_size = ARRAY_SIZE(ipv4_net_table);
+	const struct ctl_table *table;
 
 	table = ipv4_net_table;
 	if (!net_eq(net, &init_net)) {
-		int i;
-
-		table = kmemdup(table, sizeof(ipv4_net_table), GFP_KERNEL);
+		table = ipv4_net_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		for (i = 0; i < table_size; i++) {
-			if (table[i].data) {
-				/* Update the variables to point into
-				 * the current struct net
-				 */
-				table[i].data += (void *)net - (void *)&init_net;
-			} else {
-				/* Entries without data pointer are global;
-				 * Make them read-only in non-init_net ns
-				 */
-				table[i].mode &= ~0222;
-			}
-			if (table[i].extra2 >= (void *)&init_net.ipv4 &&
-			    table[i].extra2 < (void *)(&init_net.ipv4 + 1))
-				table[i].extra2 += (void *)net - (void *)&init_net;
-		}
 	}
 
 	net->ipv4.ipv4_hdr = register_net_sysctl_sz(net, "net/ipv4", table,
diff --git a/net/ipv4/xfrm4_policy.c b/net/ipv4/xfrm4_policy.c
index 58faf1ddd2b151e4569bb6351029718dac37521b..ab7a01029d490416d36482f7a3189f83d6670f42 100644
--- a/net/ipv4/xfrm4_policy.c
+++ b/net/ipv4/xfrm4_policy.c
@@ -141,7 +141,7 @@ static const struct xfrm_policy_afinfo xfrm4_policy_afinfo = {
 };
 
 #ifdef CONFIG_SYSCTL
-static struct ctl_table xfrm4_policy_table[] = {
+static const struct ctl_table xfrm4_policy_table[] = {
 	{
 		.procname       = "xfrm4_gc_thresh",
 		.data           = &init_net.xfrm.xfrm4_dst_ops.gc_thresh,
@@ -151,18 +151,30 @@ static struct ctl_table xfrm4_policy_table[] = {
 	},
 };
 
-static __net_init int xfrm4_net_sysctl_init(struct net *net)
+static const struct ctl_table *xfrm4_policy_table_dup(struct net *net)
 {
 	struct ctl_table *table;
+
+	table = kmemdup(xfrm4_policy_table, sizeof(xfrm4_policy_table),
+			GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	table[0].data = &net->xfrm.xfrm4_dst_ops.gc_thresh;
+
+	return table;
+}
+
+static __net_init int xfrm4_net_sysctl_init(struct net *net)
+{
+	const struct ctl_table *table;
 	struct ctl_table_header *hdr;
 
 	table = xfrm4_policy_table;
 	if (!net_eq(net, &init_net)) {
-		table = kmemdup(table, sizeof(xfrm4_policy_table), GFP_KERNEL);
+		table = xfrm4_policy_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		table[0].data = &net->xfrm.xfrm4_dst_ops.gc_thresh;
 	}
 
 	hdr = register_net_sysctl_sz(net, "net/ipv4", table,
diff --git a/net/ipv6/xfrm6_policy.c b/net/ipv6/xfrm6_policy.c
index 3b749475f6ed6573eec7337b502d9188ee199bee..5ec063cb4aa4378e70fff002dd03abf2029b247f 100644
--- a/net/ipv6/xfrm6_policy.c
+++ b/net/ipv6/xfrm6_policy.c
@@ -187,7 +187,7 @@ static void xfrm6_policy_fini(void)
 }
 
 #ifdef CONFIG_SYSCTL
-static struct ctl_table xfrm6_policy_table[] = {
+static const struct ctl_table xfrm6_policy_table[] = {
 	{
 		.procname       = "xfrm6_gc_thresh",
 		.data		= &init_net.xfrm.xfrm6_dst_ops.gc_thresh,
@@ -197,18 +197,30 @@ static struct ctl_table xfrm6_policy_table[] = {
 	},
 };
 
-static int __net_init xfrm6_net_sysctl_init(struct net *net)
+static const struct ctl_table *xfrm6_policy_table_dup(struct net *net)
 {
 	struct ctl_table *table;
+
+	table = kmemdup(xfrm6_policy_table, sizeof(xfrm6_policy_table),
+			GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	table[0].data = &net->xfrm.xfrm6_dst_ops.gc_thresh;
+
+	return table;
+}
+
+static int __net_init xfrm6_net_sysctl_init(struct net *net)
+{
+	const struct ctl_table *table;
 	struct ctl_table_header *hdr;
 
 	table = xfrm6_policy_table;
 	if (!net_eq(net, &init_net)) {
-		table = kmemdup(table, sizeof(xfrm6_policy_table), GFP_KERNEL);
+		table = xfrm6_policy_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		table[0].data = &net->xfrm.xfrm6_dst_ops.gc_thresh;
 	}
 
 	hdr = register_net_sysctl_sz(net, "net/ipv6", table,
diff --git a/net/netfilter/nf_hooks_lwtunnel.c b/net/netfilter/nf_hooks_lwtunnel.c
index 2d890dd04ff89041e6aec3741f24cdd7bc47d1fe..4e1eef1ba0f1559ca35f024723af551c6c9e7d35 100644
--- a/net/netfilter/nf_hooks_lwtunnel.c
+++ b/net/netfilter/nf_hooks_lwtunnel.c
@@ -54,7 +54,7 @@ int nf_hooks_lwtunnel_sysctl_handler(const struct ctl_table *table, int write,
 }
 EXPORT_SYMBOL_GPL(nf_hooks_lwtunnel_sysctl_handler);
 
-static struct ctl_table nf_lwtunnel_sysctl_table[] = {
+static const struct ctl_table nf_lwtunnel_sysctl_table[] = {
 	{
 		.procname	= "nf_hooks_lwtunnel",
 		.data		= NULL,
@@ -66,8 +66,8 @@ static struct ctl_table nf_lwtunnel_sysctl_table[] = {
 
 static int __net_init nf_lwtunnel_net_init(struct net *net)
 {
+	const struct ctl_table *table;
 	struct ctl_table_header *hdr;
-	struct ctl_table *table;
 
 	table = nf_lwtunnel_sysctl_table;
 	if (!net_eq(net, &init_net)) {
diff --git a/net/smc/smc_sysctl.c b/net/smc/smc_sysctl.c
index b1efed5462435b1a6f2f59584a4cf47f5f6e1981..09dad48337f6164f5765fa793412bdebf47e61ca 100644
--- a/net/smc/smc_sysctl.c
+++ b/net/smc/smc_sysctl.c
@@ -97,7 +97,7 @@ static int proc_smc_hs_ctrl(const struct ctl_table *ctl, int write,
 }
 #endif /* CONFIG_SMC_HS_CTRL_BPF */
 
-static struct ctl_table smc_table[] = {
+static const struct ctl_table smc_table[] = {
 	{
 		.procname       = "autocorking_size",
 		.data           = &init_net.smc.sysctl_autocorking_size,
@@ -195,14 +195,29 @@ static struct ctl_table smc_table[] = {
 #endif /* CONFIG_SMC_HS_CTRL_BPF */
 };
 
-int __net_init smc_sysctl_net_init(struct net *net)
+static const struct ctl_table *smc_table_dup(struct net *net)
 {
 	size_t table_size = ARRAY_SIZE(smc_table);
 	struct ctl_table *table;
+	int i;
+
+	table = kmemdup(smc_table, sizeof(smc_table), GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	for (i = 0; i < table_size; i++)
+		table[i].data += (void *)net - (void *)&init_net;
+
+	return table;
+}
+
+int __net_init smc_sysctl_net_init(struct net *net)
+{
+	size_t table_size = ARRAY_SIZE(smc_table);
+	const struct ctl_table *table;
 
 	table = smc_table;
 	if (!net_eq(net, &init_net)) {
-		int i;
 #if IS_ENABLED(CONFIG_SMC_HS_CTRL_BPF)
 		struct smc_hs_ctrl *ctrl;
 
@@ -214,12 +229,9 @@ int __net_init smc_sysctl_net_init(struct net *net)
 		rcu_read_unlock();
 #endif /* CONFIG_SMC_HS_CTRL_BPF */
 
-		table = kmemdup(table, sizeof(smc_table), GFP_KERNEL);
+		table = smc_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		for (i = 0; i < table_size; i++)
-			table[i].data += (void *)net - (void *)&init_net;
 	}
 
 	net->smc.smc_hdr = register_net_sysctl_sz(net, "net/smc", table,
diff --git a/net/unix/sysctl_net_unix.c b/net/unix/sysctl_net_unix.c
index e02ed6e3955c06b60cf4afb02656df8956f075ba..47660d5726bbd7d812762f4feffa9a0a42499d7d 100644
--- a/net/unix/sysctl_net_unix.c
+++ b/net/unix/sysctl_net_unix.c
@@ -13,7 +13,7 @@
 
 #include "af_unix.h"
 
-static struct ctl_table unix_table[] = {
+static const struct ctl_table unix_table[] = {
 	{
 		.procname	= "max_dgram_qlen",
 		.data		= &init_net.unx.sysctl_max_dgram_qlen,
@@ -23,18 +23,29 @@ static struct ctl_table unix_table[] = {
 	},
 };
 
-int __net_init unix_sysctl_register(struct net *net)
+static const struct ctl_table *unix_table_dup(struct net *net)
 {
 	struct ctl_table *table;
 
+	table = kmemdup(unix_table, sizeof(unix_table), GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	table[0].data = &net->unx.sysctl_max_dgram_qlen;
+
+	return table;
+}
+
+int __net_init unix_sysctl_register(struct net *net)
+{
+	const struct ctl_table *table;
+
 	if (net_eq(net, &init_net)) {
 		table = unix_table;
 	} else {
-		table = kmemdup(unix_table, sizeof(unix_table), GFP_KERNEL);
+		table = unix_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		table[0].data = &net->unx.sysctl_max_dgram_qlen;
 	}
 
 	net->unx.ctl = register_net_sysctl_sz(net, "net/unix", table,
diff --git a/net/vmw_vsock/af_vsock.c b/net/vmw_vsock/af_vsock.c
index 622dbd0467994428f1a590f559b78d8c17f6ba60..caebef73ea58d2b6043ca3fe3b6872f92fbe9fa6 100644
--- a/net/vmw_vsock/af_vsock.c
+++ b/net/vmw_vsock/af_vsock.c
@@ -2899,7 +2899,7 @@ static int vsock_net_child_mode_string(const struct ctl_table *table, int write,
 	return 0;
 }
 
-static struct ctl_table vsock_table[] = {
+static const struct ctl_table vsock_table[] = {
 	{
 		.procname	= "ns_mode",
 		.data		= &init_net.vsock.mode,
@@ -2925,20 +2925,31 @@ static struct ctl_table vsock_table[] = {
 	},
 };
 
-static int __net_init vsock_sysctl_register(struct net *net)
+static const struct ctl_table *vsock_table_dup(struct net *net)
 {
 	struct ctl_table *table;
 
+	table = kmemdup(vsock_table, sizeof(vsock_table), GFP_KERNEL);
+	if (!table)
+		return NULL;
+
+	table[0].data = &net->vsock.mode;
+	table[1].data = &net->vsock.child_ns_mode;
+	table[2].data = &net->vsock.g2h_fallback;
+
+	return table;
+}
+
+static int __net_init vsock_sysctl_register(struct net *net)
+{
+	const struct ctl_table *table;
+
 	if (net_eq(net, &init_net)) {
 		table = vsock_table;
 	} else {
-		table = kmemdup(vsock_table, sizeof(vsock_table), GFP_KERNEL);
+		table = vsock_table_dup(net);
 		if (!table)
 			goto err_alloc;
-
-		table[0].data = &net->vsock.mode;
-		table[1].data = &net->vsock.child_ns_mode;
-		table[2].data = &net->vsock.g2h_fallback;
 	}
 
 	net->vsock.sysctl_hdr = register_net_sysctl_sz(net, "net/vsock", table,

-- 
2.50.1

