From: =?utf-8?q?Jo=C3=A3o_Silva?= <jgc3silva@gmail.com>
Date: Thu, 05 Nov 2026 11:34:41 +0000
Subject: [PATCH nf-next v2] netfilter: flowtable: do not clear the offload
 bit twice
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261105-flowtable-offload-bit-v2-1-0e38b5d818f9@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQqDMBBFryKz7pRMxNJ21XuIi2gmOqBJSYK1i
 Hdv8ALd/cfnv79D4iic4FntEHmVJMEX0JcKhsn4kVFsYdBK34hUjW4On2z6mTG4ko3FXjI6anp
 nydZ3tlC278hOttPbgnfoecvQlWKSlEP8nn8rnfUf9UpIqJVrHo0elDL0Ghcj83UIC3THcfwAM
 E4JiMMAAAA=
X-Change-ID: 20261103-flowtable-offload-bit-f15bfd1d38ed
To: Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Sven Auhagen <sven.auhagen@voleatech.de>, 
 Oz Shlomo <ozsh@nvidia.com>
Cc: netfilter-devel@vger.kernel.org, coreteam@netfilter.org, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Jo=C3=A3o_Silva?= <jgc3silva@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2370; i=jgc3silva@gmail.com;
 h=from:subject:message-id; bh=pEeE/GOhABOG0gOkY8kg/Fa2OJZnNxzdRF0CXVgKbts=;
 b=owEBbQKS/ZANAwAKAfy6ZkDxTpFsAcsmYgBq7GnSsF7Oc/qXwmo77JFHxyKBRPHsGsH174XCB
 f2VCSD8p/6JAjMEAAEKAB0WIQROyCimFhnPgEUkNBX8umZA8U6RbAUCauxp0gAKCRD8umZA8U6R
 bI1MD/9a3V58iCD2EZFvmAZ0I8a9ZY98MNDh0FzDTxu14SVg5Bi4pduRDFy2gY8iB+he+JiobME
 hSMANSCsOkoYFJfd9Wpi/pDSfkFpX3fgBIZ3kBHrTq7QfzsfoqoxTjg41A1TbU6VwYwpqJwcWTX
 T6DaBsvxHNWJVVr36eBotFCFZDfHwSVZR0/fcuqzuNcmqMvf7Xu7B4Ksymn3e0qQeqMPwMfOXns
 rPjAlKFWfT2NNULYq2YILMXT0FBH2vHSEDil7wc1WRWXMq7n7vF5ie7Mb7lgFSjOonn2D7jMCxf
 wqSaSEJKMzVEB9WucEtEucdu1XV2p8QM+paGAggoyvifam1VE9H2VAr3mQrAC0r50vvXY3T7sol
 ee+z4yIblBCQ6D4SmuIdtm+NzVSHbFtSBaU5pi4U17Gg5wlfnUjBAp3H/pu4tVSFsdH1jwk8zoa
 Ip9BIigLFn4vdA1znCdOrT6uF9FrjgXL5fVikrUudAVeuO5drXP50DyktnuRqTVu6eounzZZIx7
 EXztkW1UgWKEU4PM022SoFF0ehRMJc40t8P1HPFSnU2JNIlK6w6coVpK16LR6N7cUq1h+ArhVof
 YzK4Ku/QydDO+zk2If3Ke0QS4h/gjahIvzSzD3Xy+UjB8v0AP7xjxgSgvbBbgH5KQbYtIeE8Gbz
 ZUpf/uXoFxlNjCw==
X-Developer-Key: i=jgc3silva@gmail.com; a=openpgp;
 fpr=4EC828A61619CF8045243415FCBA6640F14E916C
X-Endpoint-Received: by B4 Relay for jgc3silva@gmail.com/default with auth_id=1392
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An expired hardware flow remains in the flowtable until its asynchronous
hardware deletion completes. Teardown clears IPS_OFFLOAD_BIT, so a packet
can create a replacement flow referencing the same conntrack entry while
the old flow is still waiting for deletion.

The next GC pass calls flow_offload_teardown() on the expired old flow
again, clearing the replacement's offload bit. More packets can then
create additional flows for the same conntrack entry. A pending hardware
work item can also delay deletion and expose the same repeated teardown.

Commit d2d31ea8cd80 ("netfilter: conntrack: fix erronous removal of
offload bit") closed this window for software flows by unlinking them in
the same GC pass and made the conntrack state fixup one-shot, but
hardware flows stay linked until NF_FLOW_HW_DEAD is set.

Make clearing IPS_OFFLOAD_BIT part of the existing one-time teardown
transition, alongside the conntrack state fixup. Subsequent teardown calls
must not alter the offload state now owned by a replacement flow.

Fixes: e5eaac2beb54 ("netfilter: flowtable: fix TCP flow teardown")
Signed-off-by: João Silva <jgc3silva@gmail.com>
---
Changes in v2:
- Retarget nf-next instead of nf: the only known affected user is an
  out-of-tree hardware offload driver (RTL930x, OpenWrt).
- No code changes.
- Link to v1: https://lore.kernel.org/r/20261103-flowtable-offload-bit-v1-1-20f5952c00a1@gmail.com
---
 net/netfilter/nf_flow_table_core.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/netfilter/nf_flow_table_core.c b/net/netfilter/nf_flow_table_core.c
index 0d72dc8ae47a..709b55b74cc7 100644
--- a/net/netfilter/nf_flow_table_core.c
+++ b/net/netfilter/nf_flow_table_core.c
@@ -398,9 +398,11 @@ static void flow_offload_del(struct nf_flowtable *flow_table,
 
 void flow_offload_teardown(struct flow_offload *flow)
 {
+	if (test_and_set_bit(NF_FLOW_TEARDOWN, &flow->flags))
+		return;
+
 	clear_bit(IPS_OFFLOAD_BIT, &flow->ct->status);
-	if (!test_and_set_bit(NF_FLOW_TEARDOWN, &flow->flags))
-		flow_offload_fixup_ct(flow);
+	flow_offload_fixup_ct(flow);
 }
 EXPORT_SYMBOL_GPL(flow_offload_teardown);
 

---
base-commit: 734bef548a96e8774d6eef5dfa2026c6edc4e80b
change-id: 20261103-flowtable-offload-bit-f15bfd1d38ed

Best regards,
-- 
João Silva <jgc3silva@gmail.com>

