From: Manas <manas18244@iiitd.ac.in>
Date: Sat, 09 Nov 2024 11:58:34 +0530
Subject: [PATCH] Remove unused function parameter in __smc_diag_dump
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241109-fix-oops-__smc_diag_dump-v1-1-1c55a3e54ad4@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIABEBL2cC/x2MQQqAIBAAvxJ7bkErAvtKhFhutYdSXIog/HvSc
 WBmXhBKTAJD9UKim4XDWUDXFSy7OzdC9oWhUU2ntTK48oMhREFr5VisZ7dZfx0RVe/mloxvzdp
 ByWOi4v7rccr5A9z2hXNqAAAA
X-Change-ID: 20241109-fix-oops-__smc_diag_dump-06ab3e9d39f4
To: Wenjia Zhang <wenjia@linux.ibm.com>, Jan Karcher <jaka@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Tony Lu <tonylu@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Shuah Khan <shuah@kernel.org>, Anup Sharma <anupnewsmail@gmail.com>, 
 linux-s390@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731133722; l=2754;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=uj59/apt0R4vc2BSfem7J5/pEkXFApMSXA+V90Ln/PY=;
 b=DBoFQEraDrMRc9cmU2gZR0vrq1jy1s3x5PYP93B5LyVZszthzhOfKkZvePz8D4qjnDZDjFrRP
 M+n7bDZGW5wCCa/3dAG6xrV6Fyr2pVM96n6kO+YAoWBsc1ZI4oKxGlv
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The last parameter in __smc_diag_dump (struct nlattr *bc) is unused.
There is only one instance of this function being called and its passed
with a NULL value in place of bc.

Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
The last parameter in __smc_diag_dump (struct nlattr *bc) is unused.
There is only one instance of this function being called and its passed
with a NULL value in place of bc.

Though, the compiler (gcc) optimizes it. Looking at the object dump of
vmlinux (via `objdump -D vmlinux`), a new function clone
(__smc_diag_dump.constprop.0) is added which removes this parameter from
calling convention altogether.

ffffffff8a701770 <__smc_diag_dump.constprop.0>:
ffffffff8a701770:       41 57                   push   %r15
ffffffff8a701772:       41 56                   push   %r14
ffffffff8a701774:       41 55                   push   %r13
ffffffff8a701776:       41 54                   push   %r12

There are 5 parameters in original function, but in the cloned function
only 4.

I believe this patch also fixes this oops bug[1], which arises in the
same function __smc_diag_dump. But I couldn't verify it further. Can
someone please test this?

[1] https://syzkaller.appspot.com/bug?extid=271fed3ed6f24600c364
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
base-commit: 59b723cd2adbac2a34fc8e12c74ae26ae45bf230
change-id: 20241109-fix-oops-__smc_diag_dump-06ab3e9d39f4

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

