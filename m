From: =?utf-8?q?Jo=C3=A3o_Silva?= <jgc3silva@gmail.com>
Date: Tue, 03 Nov 2026 09:52:56 +0000
Subject: [PATCH nf] netfilter: flowtable: do not clear the offload bit
 twice
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261103-flowtable-offload-bit-v1-1-20f5952c00a1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MQQqDMBAAvyJ77kJWUYpfKT0k7q5dkEQSaQuSv
 xu8zRxmTiiSTQrM3QlZvlYsxSb06GD5+LgKGjeH3vUTkRtQt/Q7fNgEkzb2jMEOVBqDMvHwFIb
 W7lnU/vf3BVHhXesFPBZVSmsAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2100; i=jgc3silva@gmail.com;
 h=from:subject:message-id; bh=Dqh+hiNjtTLDhc1tQ1I4cJIXp18+vbRya6xJ6r5BvN4=;
 b=owEBbQKS/ZANAwAKAfy6ZkDxTpFsAcsmYgBq6a8B/LyRbqX7acF1fsF5gvc8q49GwOjhfgNpz
 fi9/9p/9NmJAjMEAAEKAB0WIQROyCimFhnPgEUkNBX8umZA8U6RbAUCaumvAQAKCRD8umZA8U6R
 bDQjEADIUBI6EVVK5bTcxUq4pZ4jJqoTbvOqdomL/NYoYddHaBmpG+kdqfsyoGnhYDrpGVfgble
 ifEIjjOzp3LfrpgOJR4ItmuUuku6LAVExR1kAHIkJMM4+4brdDI7Qdoij9RdUOUoJaeaU4qIhDe
 U4bx4aUtt3J+vI0yLqpTJUkR5lIbKLYZQMS0V9r08kUFkrb2W3Y1vLpTjcXc8M4XGv2Rzc/s9J2
 0ZX30hPIKk3NJK0JZc+5G9LUNfJjoDJYftkkx9s1PjUN/HO1gfDvOgDf/8Rmc3WJfY+YUaxJTbB
 erJ2IbEiWtHRbl5vjFA4hVa/KHcvQcijOM0GsaPOJhI6TTso0X6FOpwjCUFhmVZNkCKYqCgUoRw
 QUjgkb+OhdeTQeS2vPxGJxCSXSTszJ6UBFwG6cjSlbSpCHczYldr4ByclcV6H/5/0K/EBDAJtXV
 RKDkb7PGmgC33igdk4BeQxSNdLghRL41MlhsadJ/Lo8uOKHS77lqIWQOwcZlkTKvqOcOwxg8k4U
 5U6x2JziJVH/4MMpDOtZaxiFj7IX7TNg3/X7gSUmvAk4KBA3H5AXd1RzfVaZ9sSfrpc+cSZznzW
 yQYvqTB3Q0pHUn+/JyBq80uBFqaCqUEuJppyL4THxLx8N6krbQnpDtpHotWw3Gk2H5STK+t+5JB
 vpIjiuTmuiawWwg==
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

