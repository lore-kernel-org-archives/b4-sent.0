From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 02 Dec 2024 15:40:51 +0530
Subject: [PATCH net-next RESEND v2] net/smc: Remove unused function
 parameter in __smc_diag_dump
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241202-fix-oops-__smc_diag_dump-v2-1-119736963ba9@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAKqHTWcC/4WNMQ+CMBSE/wrpbElbQK2Tg6wOOhpDCn3AGyikr
 QRD+O9WJl00t7zLu/tuJg4sgiOHaCYWRnTYm2DEJiJVq0wDFHXwRDCRcs4krXGifT84WhSuqwq
 Nqin0oxso26oyAakTWack1AcLIbuib8SApwYm/35c8mt+PpF7OFt0vrfPdX3ka/L/0MhpUJVlK
 oEsVTo9IqLXsapiNCt2FB8owX6gREDJHUtKvueSA/tGLcvyAlRntyYhAQAA
X-Change-ID: 20241109-fix-oops-__smc_diag_dump-06ab3e9d39f4
To: Wenjia Zhang <wenjia@linux.ibm.com>, Jan Karcher <jaka@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Shuah Khan <shuah@kernel.org>, Anup Sharma <anupnewsmail@gmail.com>, 
 linux-s390@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-rdma@vger.kernel.org, 
 Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733134252; l=1964;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=zCxOxxK4jUmuWneAk7mzPYC43+hjuOr5TSFC2vSGlrc=;
 b=UJ2tqCJTl+Rjxgg3UW7xGs/kWb0PbQKYRae+HCAb15pkoLFCldFgsbURksOSEj2qN4V8BQfaf
 x1Gk5jADLFOCg3tFAZ9B8zgBAYRtO83dl52EQLzyYyK9kv9RtMJ2kB+
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The last parameter in __smc_diag_dump (struct nlattr *bc) is unused.
There is only one instance of this function being called and its passed
with a NULL value in place of bc.

Reviewed-by: Simon Horman <horms@kernel.org>
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
Changes in v2:
- Added target tree and prefix
- Carried forward Reviewed-by: tag from v1
- Link to v1: https://lore.kernel.org/r/20241109-fix-oops-__smc_diag_dump-v1-1-1c55a3e54ad4@iiitd.ac.in
---
 net/smc/smc_diag.c | 6 ++----
 1 file changed, 2 insertions(+), 4 deletions(-)

diff --git a/net/smc/smc_diag.c b/net/smc/smc_diag.c
index 6fdb2d96777ad704c394709ec845f9ddef5e599a..8f7bd40f475945171a0afa5a2cce12d9aa2b1eb4 100644
--- a/net/smc/smc_diag.c
+++ b/net/smc/smc_diag.c
@@ -71,8 +71,7 @@ static int smc_diag_msg_attrs_fill(struct sock *sk, struct sk_buff *skb,
 
 static int __smc_diag_dump(struct sock *sk, struct sk_buff *skb,
 			   struct netlink_callback *cb,
-			   const struct smc_diag_req *req,
-			   struct nlattr *bc)
+			   const struct smc_diag_req *req)
 {
 	struct smc_sock *smc = smc_sk(sk);
 	struct smc_diag_fallback fallback;
@@ -199,7 +198,6 @@ static int smc_diag_dump_proto(struct proto *prot, struct sk_buff *skb,
 	struct smc_diag_dump_ctx *cb_ctx = smc_dump_context(cb);
 	struct net *net = sock_net(skb->sk);
 	int snum = cb_ctx->pos[p_type];
-	struct nlattr *bc = NULL;
 	struct hlist_head *head;
 	int rc = 0, num = 0;
 	struct sock *sk;
@@ -214,7 +212,7 @@ static int smc_diag_dump_proto(struct proto *prot, struct sk_buff *skb,
 			continue;
 		if (num < snum)
 			goto next;
-		rc = __smc_diag_dump(sk, skb, cb, nlmsg_data(cb->nlh), bc);
+		rc = __smc_diag_dump(sk, skb, cb, nlmsg_data(cb->nlh));
 		if (rc < 0)
 			goto out;
 next:

---
base-commit: 40384c840ea1944d7c5a392e8975ed088ecf0b37
change-id: 20241109-fix-oops-__smc_diag_dump-06ab3e9d39f4

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

