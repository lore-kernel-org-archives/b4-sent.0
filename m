From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:31 +0300
Subject: [PATCH RFC net-next 3/7] netfilter: flowtable: expose route MTU
 and established TCP context
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-3-703175c6340c@gmail.com>
References: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
In-Reply-To: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Simon Horman <horms@kernel.org>, Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Russell King <linux@armlinux.org.uk>, 
 Christian Marangi <ansuelsmth@gmail.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=3324;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=mLPX1GTSxAne24R9ema/fFYxL0PzB5MRcuwULUd51Mo=;
 b=rfU8dFYcmkSUrzpN97eeL+cHaJoM5iboEZOVkw9d79W6LC4hom5cr3RET0XMqIiSwzQUGGHxF
 cdZ5VuOWBsRAVu8duOnmoDJkv4Lt3juxAipUir/lRCKJoeFM83M22VU
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Carry the direction route MTU in the classifier request. Snapshot
established TCP state under the conntrack lock, rejecting dying and
closing flows. The CS7542 backend needs these facts to install its
length and TCP exception guards; flower rewrites alone do not supply
them.

This is an RFC interface proposal. Other flower users leave the added
fields zero.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 include/net/flow_offload.h            |  5 +++++
 net/netfilter/nf_flow_table_offload.c | 25 ++++++++++++++++++++++++-
 2 files changed, 29 insertions(+), 1 deletion(-)

diff --git a/include/net/flow_offload.h b/include/net/flow_offload.h
index 70a02ee14..0f9783b5c 100644
--- a/include/net/flow_offload.h
+++ b/include/net/flow_offload.h
@@ -699,8 +699,13 @@ struct flow_cls_offload {
 	struct flow_rule *rule;
 	struct flow_stats stats;
 	u32 classid;
+	u16 nf_route_mtu;
+	bool nf_tcp_established;
 };
 
+#define NF_FLOW_CLS_HAS_ROUTE_MTU 1
+u16 nf_flow_offload_route_mtu(const struct flow_cls_offload *cls);
+
 enum offload_act_command  {
 	FLOW_ACT_REPLACE,
 	FLOW_ACT_DESTROY,
diff --git a/net/netfilter/nf_flow_table_offload.c b/net/netfilter/nf_flow_table_offload.c
index 436585922..686781363 100644
--- a/net/netfilter/nf_flow_table_offload.c
+++ b/net/netfilter/nf_flow_table_offload.c
@@ -13,6 +13,7 @@
 #include <net/netfilter/nf_conntrack.h>
 #include <net/netfilter/nf_conntrack_acct.h>
 #include <net/netfilter/nf_conntrack_core.h>
+#include <net/netfilter/nf_conntrack_l4proto.h>
 #include <net/netfilter/nf_conntrack_tuple.h>
 
 #define NF_FLOW_RULE_ACTION_MAX	24
@@ -885,6 +886,16 @@ static int nf_flow_offload_alloc(const struct flow_offload_work *offload,
 	return 0;
 }
 
+/* The flowtable records the route MTU independently for each direction. */
+u16 nf_flow_offload_route_mtu(const struct flow_cls_offload *cls)
+{
+	if (!cls || cls->command != FLOW_CLS_REPLACE || !cls->rule)
+		return 0;
+
+	return cls->nf_route_mtu;
+}
+EXPORT_SYMBOL_GPL(nf_flow_offload_route_mtu);
+
 static void nf_flow_offload_init(struct flow_cls_offload *cls_flow,
 				 __be16 proto, int priority,
 				 enum flow_cls_command cmd,
@@ -896,6 +907,7 @@ static void nf_flow_offload_init(struct flow_cls_offload *cls_flow,
 	cls_flow->common.extack = extack;
 	cls_flow->command = cmd;
 	cls_flow->cookie = (unsigned long)tuple;
+	cls_flow->nf_route_mtu = tuple->mtu;
 }
 
 static int nf_flow_offload_tuple(struct nf_flowtable *flowtable,
@@ -914,8 +926,19 @@ static int nf_flow_offload_tuple(struct nf_flowtable *flowtable,
 
 	nf_flow_offload_init(&cls_flow, proto, priority, cmd,
 			     &flow->tuplehash[dir].tuple, &extack);
-	if (cmd == FLOW_CLS_REPLACE)
+	if (cmd == FLOW_CLS_REPLACE) {
 		cls_flow.rule = flow_rule->rule;
+		if (flow->tuplehash[dir].tuple.l4proto == IPPROTO_TCP &&
+		    flow->ct) {
+			spin_lock_bh(&flow->ct->lock);
+			cls_flow.nf_tcp_established =
+				nf_conntrack_tcp_established(flow->ct) &&
+				!nf_ct_is_dying(flow->ct) &&
+				!test_bit(NF_FLOW_TEARDOWN, &flow->flags) &&
+				!test_bit(NF_FLOW_CLOSING, &flow->flags);
+			spin_unlock_bh(&flow->ct->lock);
+		}
+	}
 
 	down_read(&flowtable->flow_block_lock);
 	list_for_each_entry(block_cb, block_cb_list, list) {

-- 
2.53.0

