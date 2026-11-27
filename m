MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-nf-ctproto2-v1-1-b5383cef8da2@certik.com>
References: <20261127-nf-ctproto2-v1-0-b5383cef8da2@certik.com>
In-Reply-To: <20261127-nf-ctproto2-v1-0-b5383cef8da2@certik.com>
From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 18:12:10 +0000
Subject: [PATCH nf 1/2] netfilter: conntrack: reject helper protocol
 mismatch
To: netfilter-devel@vger.kernel.org
Cc: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 coreteam@netfilter.org, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813751; l=1481;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=jRXlWORZ8gC8E+WMyYiUvJoGLip9YtA97KaUH8Z36bk=;
 b=rTMnMZIwMrw8UdUNxCunwpOskTUV0k7xYap6amsggOARMYpTZmG8/pGhiVdgNY8mINFThLr6o
 opmwhs1D20wAvsJPhxBaCCYa1PQsKUSozSe7QjtCSbSK7f6VHn1KjBY
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conntrack templates can carry helpers selected from rule metadata instead
of the packet protocol. nft_compat does not enforce its compatibility
protocol when evaluating packets, so xt_CT can attach a UDP helper to a
TCP conntrack. act_ct can likewise attach a helper configured for another
protocol.

Helpers parse transport headers according to helper->l4proto. With the
H.323 RAS helper attached to TCP traffic, NAT mangling in
mangle_contents() crashes. Refuse to copy a template helper unless it
matches the new conntrack protocol. This covers all template users in
the common assignment path.

Fixes: 84f3bb9ae9db ("netfilter: xtables: add CT target")
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

 net/netfilter/nf_conntrack_helper.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/net/netfilter/nf_conntrack_helper.c b/net/netfilter/nf_conntrack_helper.c
index c30ae3f203..91bd11f01f 100644
--- a/net/netfilter/nf_conntrack_helper.c
+++ b/net/netfilter/nf_conntrack_helper.c
@@ -209,6 +209,8 @@ int __nf_ct_try_assign_helper(struct nf_conn *ct, struct nf_conn *tmpl,
 	help = nfct_help(tmpl);
 	if (help)
 		helper = rcu_dereference(help->helper);
+	if (helper && helper->l4proto != nf_ct_protonum(ct))
+		helper = NULL;
 
 	help = nfct_help(ct);
 
-- 
2.43.0

