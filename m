MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-nf-ctproto2-v1-2-b5383cef8da2@certik.com>
References: <20261127-nf-ctproto2-v1-0-b5383cef8da2@certik.com>
In-Reply-To: <20261127-nf-ctproto2-v1-0-b5383cef8da2@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 18:12:11 +0000
Subject: [PATCH nf 2/2] netfilter: conntrack: reject timeout protocol
 mismatch
To: netfilter-devel@vger.kernel.org
Cc: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 coreteam@netfilter.org, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813751; l=1700;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Eg6xkj+hY1owkOvEJ4GABU50fLTvmFKF8elU28QXiLA=;
 b=oQJEjG8SDM1uaAltfSS+4Av6J+vYRwdh8fP+1R0NWtMt83wZiynX6hdaYU8esYS0JtxHzbwPh
 sjPFjR4/HUQB5ywmvoPiXxV7QYsnSFqcmp01yLeNqVMtWjhPtE3bltD
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A conntrack template can carry a timeout policy selected from rule
metadata instead of the packet protocol. nft_compat does not enforce its
compatibility protocol when evaluating packets, so an ICMP or UDP policy
can be copied to a TCP conntrack.

Timeout data is laid out for one protocol tracker, so an ICMP policy on
a TCP conntrack makes nf_conntrack_tcp_packet() read past the end of the
timeout object. Copy a template timeout only when its protocol matches
the new conntrack.

Fixes: 24de58f46516 ("netfilter: xt_CT: allow to attach timeout policy + glue code")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 net/netfilter/nf_conntrack_core.c | 10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)

diff --git a/net/netfilter/nf_conntrack_core.c b/net/netfilter/nf_conntrack_core.c
index 931b76aacd..eaae27bf09 100644
--- a/net/netfilter/nf_conntrack_core.c
+++ b/net/netfilter/nf_conntrack_core.c
@@ -1782,9 +1782,13 @@ init_conntrack(struct net *net, struct nf_conn *tmpl,
 
 	timeout_ext = tmpl ? nf_ct_timeout_find(tmpl) : NULL;
 
-	if (timeout_ext)
-		nf_ct_timeout_ext_add(ct, rcu_dereference(timeout_ext->timeout),
-				      GFP_ATOMIC);
+	if (timeout_ext) {
+		struct nf_ct_timeout *timeout;
+
+		timeout = rcu_dereference(timeout_ext->timeout);
+		if (timeout && timeout->l4proto->l4proto == nf_ct_protonum(ct))
+			nf_ct_timeout_ext_add(ct, timeout, GFP_ATOMIC);
+	}
 
 	nf_ct_acct_ext_add(ct, GFP_ATOMIC);
 	nf_ct_tstamp_ext_add(ct, GFP_ATOMIC);
-- 
2.43.0

