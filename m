From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sun, 01 Nov 2026 15:27:28 +0000
Subject: [PATCH 6.6.y] netfilter: nf_conntrack_expect: add and use
 nf_ct_expect_related_pair()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261101-nfexp-pair-6-6-y-v1-1-049943e85067@gmail.com>
X-B4-Tracking: v=1; b=H4sIAF9a52oC/x2MQQqAIBAAvxJ7bkPNDPpKdNhqrb2YKEQR/T2JO
 c1h5oHMSTjDUD2Q+JQsRyii6wqWncLGKGtxMMo4rZXG4PmKGEkSusKNvVEzUdtZOxOULCb2cv3
 LEVzjmhum9/0AWvckNWkAAAA=
To: stable@vger.kernel.org
Cc: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, netfilter-devel@vger.kernel.org, 
 Sasha Levin <sashal@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jaeyeong Lee <iostreampy@proton.me>, 
 Joas Antonio dos Santos <joasantonio108@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793546847; l=8686;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=DjhRAkQSNrM96ywt6HuSfqLCSsMNwaYVKFId13iqzyo=;
 b=120TeDZWDWkTiHVeengpma9tElgv6gHbZ22aKx60F1E6/cwxJd84AsTyY2VaXkNp2g3Ftye6g
 QaBxUPY8rqMCaa9SlH0dNBegBIBsFk/jTUms7xQTfgz4FxbCsYBa5D3
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pablo Neira Ayuso <pablo@netfilter.org>

commit 4aa63842fc92de1bce59d4709a0d32e718890bb2 upstream.

Add a new function to insert a pair of expectations, this is required by
the SIP and H323 NAT helpers. The spinlock is held to check if there is
a slot for both expectations, in such case, insert them.

This removes the need for nf_ct_unexpect_related() inside the loop to
find a pair of consecutive ports, otherwise inserting expectations whose
dead flag is already set on can happen.

Bump master_help->expecting for the expectation class after checking if
the expectation fits in the master expectation list, which is needed for
this new _pair() function variant to run the eviction routine including
the preallocated slot for the first expectation in the pair.

[ Joas: nf_ct_expect_insert() and __nf_ct_expect_check() do not take
  a master_help argument in this tree, so keep their existing
  signatures; nf_ct_expect_related_report() gets master_help from
  nfct_help(expect->master) for the moved expecting[] increment. ]

Fixes: b8b09dc2bf35 ("netfilter: nf_conntrack_expect: use conntrack GC to reap expectations")
Reported-by: Jaeyeong Lee <iostreampy@proton.me>
Link: https://patch.msgid.link/178377968720.33756.12204817361601593230@proton.me/
Signed-off-by: Pablo Neira Ayuso <pablo@netfilter.org>
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
b8b09dc2bf35 ("netfilter: nf_conntrack_expect: use conntrack GC to reap
expectations") is in 6.6.160+, 6.12.114+ and 6.1.191, but its follow-up
4aa63842fc92 is not, and it is not in the stable queue either.  Sasha
noted the missing dependency on 2026-09-20.

Without it, nf_ct_unexpect_related() only sets NF_CT_EXPECT_DEAD and
leaves the expectation linked, while the SIP and H.323 NAT port loops
still call nf_ct_unexpect_related(rtp_exp) on -EBUSY and re-insert the
same, still-linked rtp_exp.  That corrupts the master expectation list
and the expect hash.  It is reachable from an unprivileged user and
network namespace (sip helper + NAT, plus one ctnetlink expectation
occupying the RTCP port).

Tested on v6.6.161 arm64 with KASAN and DEBUG_LIST, as uid 1000 in a
new user+net namespace.  Without this patch:

  KASAN: maybe wild-memory-access in range [0xdead000000000120-0xdead000000000127]
  pc : nf_ct_unlink_expect_report+0xfc/0x418
   nf_ct_unlink_expect_report
   flush_expectations
   process_invite_request
   process_sip_msg
   sip_help_udp
   nf_confirm
  Kernel panic - not syncing: Oops: Fatal exception in interrupt

With it, the same reproducer runs clean.  The same backport applies to
6.12.y and 6.1.y (sent separately); I can share the reproducer
privately if useful.

Tool-use note: the analysis, backport and testing were done with help
from an LLM-based assistant; I reviewed the change and ran the tests
myself.
---
 include/net/netfilter/nf_conntrack_expect.h |  3 +++
 net/ipv4/netfilter/nf_nat_h323.c            | 22 ++++++------------
 net/netfilter/nf_conntrack_expect.c         | 35 ++++++++++++++++++++++++++++-
 net/netfilter/nf_nat_sip.c                  | 20 +++++------------
 4 files changed, 50 insertions(+), 30 deletions(-)

diff --git a/include/net/netfilter/nf_conntrack_expect.h b/include/net/netfilter/nf_conntrack_expect.h
index be4a120d549e..8efc1ed0925a 100644
--- a/include/net/netfilter/nf_conntrack_expect.h
+++ b/include/net/netfilter/nf_conntrack_expect.h
@@ -160,6 +160,9 @@ static inline int nf_ct_expect_related(struct nf_conntrack_expect *expect,
 	return nf_ct_expect_related_report(expect, 0, 0, flags);
 }
 
+int nf_ct_expect_related_pair(struct nf_conntrack_expect *expect[],
+			      unsigned int flag);
+
 struct nf_conn_help;
 void nf_ct_expectation_gc(struct nf_conn_help *master_help);
 
diff --git a/net/ipv4/netfilter/nf_nat_h323.c b/net/ipv4/netfilter/nf_nat_h323.c
index 10e1b0837731..d55994fccf5d 100644
--- a/net/ipv4/netfilter/nf_nat_h323.c
+++ b/net/ipv4/netfilter/nf_nat_h323.c
@@ -179,6 +179,7 @@ static int nat_rtp_rtcp(struct sk_buff *skb, struct nf_conn *ct,
 			struct nf_conntrack_expect *rtp_exp,
 			struct nf_conntrack_expect *rtcp_exp)
 {
+	struct nf_conntrack_expect *rtp_pair[2] = { rtp_exp, rtcp_exp };
 	struct nf_ct_h323_master *info = nfct_help_data(ct);
 	int dir = CTINFO2DIR(ctinfo);
 	int i;
@@ -221,22 +222,13 @@ static int nat_rtp_rtcp(struct sk_buff *skb, struct nf_conn *ct,
 		int ret;
 
 		rtp_exp->tuple.dst.u.udp.port = htons(nated_port);
-		ret = nf_ct_expect_related(rtp_exp, 0);
+		rtcp_exp->tuple.dst.u.udp.port = htons(nated_port + 1);
+		ret = nf_ct_expect_related_pair(rtp_pair, 0);
 		if (ret == 0) {
-			rtcp_exp->tuple.dst.u.udp.port =
-			    htons(nated_port + 1);
-			ret = nf_ct_expect_related(rtcp_exp, 0);
-			if (ret == 0)
-				break;
-			else if (ret == -EBUSY) {
-				nf_ct_unexpect_related(rtp_exp);
-				continue;
-			} else if (ret < 0) {
-				nf_ct_unexpect_related(rtp_exp);
-				nated_port = 0;
-				break;
-			}
-		} else if (ret != -EBUSY) {
+			break;
+		} else if (ret == -EBUSY) {
+			continue;
+		} else if (ret < 0) {
 			nated_port = 0;
 			break;
 		}
diff --git a/net/netfilter/nf_conntrack_expect.c b/net/netfilter/nf_conntrack_expect.c
index f908e64eb814..e153103e04ff 100644
--- a/net/netfilter/nf_conntrack_expect.c
+++ b/net/netfilter/nf_conntrack_expect.c
@@ -425,7 +425,6 @@ static void nf_ct_expect_insert(struct nf_conntrack_expect *exp)
 		exp->timeout += helper->expect_policy[exp->class].timeout * HZ;
 
 	hlist_add_head_rcu(&exp->lnode, &master_help->expectations);
-	master_help->expecting[exp->class]++;
 
 	hlist_add_head_rcu(&exp->hnode, &nf_ct_expect_hash[h]);
 	cnet = nf_ct_pernet(net);
@@ -525,6 +524,7 @@ int nf_ct_expect_related_report(struct nf_conntrack_expect *expect,
 	if (ret < 0)
 		goto out;
 
+	nfct_help(expect->master)->expecting[expect->class]++;
 	nf_ct_expect_insert(expect);
 
 	nf_ct_expect_event_report(IPEXP_NEW, expect, portid, report);
@@ -537,6 +537,39 @@ int nf_ct_expect_related_report(struct nf_conntrack_expect *expect,
 }
 EXPORT_SYMBOL_GPL(nf_ct_expect_related_report);
 
+int nf_ct_expect_related_pair(struct nf_conntrack_expect *expect[],
+			      unsigned int flags)
+{
+	struct nf_conn_help *master_help;
+	int i, ret;
+
+	spin_lock_bh(&nf_conntrack_expect_lock);
+	master_help = nfct_help(expect[0]->master);
+	if (!master_help || master_help != nfct_help(expect[1]->master)) {
+		ret = -EINVAL;
+		goto out;
+	}
+
+	for (i = 0; i < 2; i++) {
+		ret = __nf_ct_expect_check(expect[i], flags);
+		if (ret < 0) {
+			if (i == 1)
+				master_help->expecting[expect[0]->class]--;
+			goto out;
+		}
+		master_help->expecting[expect[i]->class]++;
+	}
+
+	for (i = 0; i < 2; i++) {
+		nf_ct_expect_insert(expect[i]);
+		nf_ct_expect_event_report(IPEXP_NEW, expect[i], 0, 0);
+	}
+out:
+	spin_unlock_bh(&nf_conntrack_expect_lock);
+	return ret;
+}
+EXPORT_SYMBOL_GPL(nf_ct_expect_related_pair);
+
 void nf_ct_expect_iterate_destroy(bool (*iter)(struct nf_conntrack_expect *e, void *data),
 				  void *data)
 {
diff --git a/net/netfilter/nf_nat_sip.c b/net/netfilter/nf_nat_sip.c
index 6b00c81084fe..115d955bfaef 100644
--- a/net/netfilter/nf_nat_sip.c
+++ b/net/netfilter/nf_nat_sip.c
@@ -585,6 +585,7 @@ static unsigned int nf_nat_sdp_media(struct sk_buff *skb, unsigned int protoff,
 				     unsigned int medialen,
 				     union nf_inet_addr *rtp_addr)
 {
+	struct nf_conntrack_expect *rtp_pair[2] = { rtp_exp, rtcp_exp };
 	enum ip_conntrack_info ctinfo;
 	struct nf_conn *ct = nf_ct_get(skb, &ctinfo);
 	enum ip_conntrack_dir dir = CTINFO2DIR(ctinfo);
@@ -615,24 +616,15 @@ static unsigned int nf_nat_sdp_media(struct sk_buff *skb, unsigned int protoff,
 		int ret;
 
 		rtp_exp->tuple.dst.u.udp.port = htons(port);
-		ret = nf_ct_expect_related(rtp_exp,
-					   NF_CT_EXP_F_SKIP_MASTER);
-		if (ret == -EBUSY)
-			continue;
-		else if (ret < 0) {
-			port = 0;
-			break;
-		}
 		rtcp_exp->tuple.dst.u.udp.port = htons(port + 1);
-		ret = nf_ct_expect_related(rtcp_exp,
-					   NF_CT_EXP_F_SKIP_MASTER);
+
+		ret = nf_ct_expect_related_pair(rtp_pair,
+						NF_CT_EXP_F_SKIP_MASTER);
 		if (ret == 0)
 			break;
-		else if (ret == -EBUSY) {
-			nf_ct_unexpect_related(rtp_exp);
+		else if (ret == -EBUSY)
 			continue;
-		} else if (ret < 0) {
-			nf_ct_unexpect_related(rtp_exp);
+		else if (ret < 0) {
 			port = 0;
 			break;
 		}

---
base-commit: b5a1dc3ad4822c6edfb53429e9a3759c9b0ac2be
change-id: 20261101-nfexp-pair-6-6-y-720baa3544ba

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

