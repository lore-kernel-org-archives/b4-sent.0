From: Dickson Wu <dickson.wu@certik.com>
Subject: [PATCH nf 0/2] netfilter: reject mismatched conntrack template
 protocols
Date: Fri, 27 Nov 2026 21:09:11 +0000
Message-Id: <20261127-nf-ctproto2-v1-0-b5383cef8da2@certik.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHfxCWsC/yWMQQrCMBBFr1Jm7UAa0KpXEReZZGIjMimZVITSu
 5vo8j3+fxsol8QK12GDwu+kKUuD8TCAn508GFNoDNbY0zjaCSWir0vJNVs0R3OmcKHINEF7LIV
 j+vxqN5AI97/TlZ7sa8/0FTllpOLEz10pS6g5v7B72PcvpZGukZMAAAA=
X-Change-ID: 20261127-nf-ctproto2-0508bd9bfeb7
To: netfilter-devel@vger.kernel.org
Cc: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 coreteam@netfilter.org, netdev@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795813751; l=1932;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=i71b4CrHv+7F8+HFRek3oHZywpCTEPpzNL6nhGvS7bs=;
 b=0QGhu63aw7WiHz1z/nQvM94YRULFZEao8KtCxvIQ9FTkEq7AA/mWJNe+8wwsv58CdZU/qPobT
 S+DwaR0rcYdBBF0aUyQ9PWDplR7BNi3bbh/m2b+H7bFe3Rrwl2bIzFC
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xt_CT under nft_compat can attach a helper or timeout policy selected from
NFTA_RULE_COMPAT_PROTO to packets of another protocol. The helper mismatch
also affects act_ct through the common template assignment path.

Reject mismatched helpers and timeout policies when a conntrack copies its
template state.

Tested under UML with KASAN, with the trigger running as uid 1000 in new
user and network namespaces (namespace-local CAP_NET_ADMIN only):

- nft_compat xt_CT with the H.323 RAS helper on TCP: stock panics in
  mangle_contents(); patched completes; reverted panics again.
- act_ct with the RAS helper on TCP: stock panics in ras_help() from the
  receive softirq; patched completes; reverted panics again.
- xt_CT with an ICMP timeout policy on TCP: stock gives a KASAN
  slab-out-of-bounds read in nf_conntrack_tcp_packet(); patched keeps the
  default TCP timeout; reverted reads out of bounds again.
- Matching-protocol controls still work: UDP H.323, TCP FTP, and ICMP
  and UDP timeout policies.

W=1 builds are clean. The rule-load checks in xt_CT and nft_ct already
require an exact protocol match, so valid configurations are unaffected.
The gap is nft_compat not enforcing its compat protocol per packet, and
act_ct.

A reproducer is available if it helps.

This was found and the fix prepared with AI coding tools (OpenAI Codex
agents, with review by Claude). I went over the analysis and the patch
before signing off.

---
Dickson Wu (2):
      netfilter: conntrack: reject helper protocol mismatch
      netfilter: conntrack: reject timeout protocol mismatch

 net/netfilter/nf_conntrack_core.c   | 10 +++++++---
 net/netfilter/nf_conntrack_helper.c |  2 ++
 2 files changed, 9 insertions(+), 3 deletions(-)
---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261127-nf-ctproto2-0508bd9bfeb7

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

