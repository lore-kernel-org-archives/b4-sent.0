From: YanXin Li <fadouse@pm.me>
Date: Sun, 22 Nov 2026 20:45:52 +0800
Subject: [PATCH net v2] net/sched: act_ife: return -EAGAIN after dropping
 rtnl_lock in load_metaops_and_vet()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-02-act-ife-rtnl-uaf-v2-102eba468698-v2-1-67c413c45928@pm.me>
X-B4-Tracking: v=1; b=H4sIAP/jAmsC/yWNQQ4CIQxFr2K6thE6DYNexbgoUBRj0MBoNMa7O
 6PL9/Lz3xu6tqIddqs3NH2UXq51BlqvIJ6kHhVLmhnIkLOWCAOjIZQ4YcmKbaoXvEvGB6E1pEH
 Yebf1mLzd5lHiaIyD+ezWNJfnL7SHqhMc/rLfw1njtCSWWZCuGJrUeFpU04u8cJGbyGwN58ExJ
 RnJWMeGydGg7AfygxPNKXmFz+cL4NbH7NUAAAA=
X-Change-ID: 20261122-b4-02-act-ife-rtnl-uaf-v2-102eba468698-d819f7ac7006
To: Jamal Hadi Salim <jhs@mojatatu.com>, Jiri Pirko <jiri@resnulli.us>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Simon Horman <horms@kernel.org>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795351585; l=3836;
 i=fadouse@pm.me; s=b4-relay-20261122; h=from:subject:message-id;
 bh=R6AZ0+3b44AwA7zPArm0D81n4+9WlR/R512inY1q7qw=;
 b=qsqZxqZfyp9Bt3IIxnnG4mcG2BZmBRa1SWt4lQo37rzuuRbhjD91d8zY5CWAGl8ou5LjCgfjV
 0EKLwwLidTZC/RL7clsgPR6PzyWU6WG6fyi2f0uUrytz4i0ZxVU42Qg
X-Developer-Key: i=fadouse@pm.me; a=ed25519;
 pk=b4DyzHJDRd8853IHUSKPA5wwzChj8eF4MTnZuyPz1PQ=
X-Endpoint-Received: by B4 Relay for fadouse@pm.me/b4-relay-20261122 with auth_id=1597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

load_metaops_and_vet() unlocks rtnl_lock() to invoke request_module()
when an IFE metadata provider module (such as act_meta_mark) is not
yet loaded, re-acquires rtnl_lock(), validates the metadata attribute,
and returns 0.

Returning 0 after dropping rtnl_lock() violates the serialization
contract of RTNL-locked classifiers (cls_basic, cls_flow, cls_fw,
cls_route, and cls_u32), which hold an unrefcounted filter pointer
(fold) across tcf_exts_validate() -> tcf_ife_init().  A concurrent
RTM_DELTFILTER can delete and RCU-free fold during the unlocked
request_module() window, after which basic_change() executes
list_replace_rcu(&fold->link, &fnew->link) and queues a second
deletion on the freed filter.  Generic KASAN reports:

  BUG: KASAN: slab-use-after-free in basic_change+0xf4c/0x1220
  Read of size 8 at addr ffff88800e043c58 by task test_act_ife_rt/101
  ...
  Allocated by task 101:
   basic_change+0x1e0/0x1220
  Freed by task 57:
   ...
  Oops: general protection fault, probably for non-canonical address
  KASAN: maybe wild-memory-access in range [0xdead000000000120-0xdead000000000127]

Every other TC module autoloader that drops rtnl_lock() during filter
updates (tc_action_load_ops(), tcf_em_validate(), and em_text_change())
returns -EAGAIN so tc_new_tfilter() and tcf_action_add() unwind and
replay under a fresh RTNL critical section.

Manipulating TC filters requires CAP_NET_ADMIN in the target network
namespace, which is reachable by an unprivileged local user inside a
user and network namespace when CONFIG_USER_NS=y, CONFIG_MODULES=y,
CONFIG_NET_ACT_IFE is enabled, and an IFE metadata module is not yet
loaded.

When load_metaops_and_vet() drops rtnl_lock() and loads the requested
metadata module, drop the module reference and return -EAGAIN so the
caller replays the request with fresh lookups.  With this change, the
same concurrent RTM_NEWTFILTER and RTM_DELTFILTER sequence cleanly
loads act_meta_mark, replays without touching the deleted filter, and
completes with rc=0 and no KASAN or lockdep reports.  A finite
two-thread state-space interleaving model found the old use-after-free
and no use-after-free, double-free, or deadlock in its reachable states
after the change.

The vulnerable code is present in upstream mainline v7.4-rc3.
Runtime verification and fix validation were performed in an x86-64
QEMU/KVM guest running mainline after v7.4-rc3 with Generic KASAN,
UBSAN, and lockdep.

This issue was discovered through LLM-assisted code audit and manual
code inspection of net/sched/act_ife.c.

Fixes: ef6980b6becb ("introduce IFE action")
Cc: stable@vger.kernel.org
Signed-off-by: YanXin Li <fadouse@pm.me>
---
Changes in v2:
- Resend via b4 because the archived v1 email has a corrupted diff and
  cannot be applied.
- State how the issue was discovered and clarify the finite model scope.
- Link to v1: https://lore.kernel.org/r/20261122030728.9368-1-fadouse@pm.me
---
 net/sched/act_ife.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/net/sched/act_ife.c b/net/sched/act_ife.c
index 5a527da0056..5d6ca124e00 100644
--- a/net/sched/act_ife.c
+++ b/net/sched/act_ife.c
@@ -275,6 +275,14 @@ static int load_metaops_and_vet(u32 metaid, void *val, int len, bool rtnl_held)
 		if (rtnl_held)
 			rtnl_lock();
 		ops = find_ife_oplist(metaid);
+		if (ops && rtnl_held) {
+			/* We dropped the RTNL mutex in order to perform the
+			 * module load. Tell the caller to replay the request
+			 * under a fresh RTNL critical section.
+			 */
+			module_put(ops->owner);
+			return -EAGAIN;
+		}
 #endif
 	}
 

---
base-commit: c44104f3642da720164042623e4832836aefdd8e
change-id: 20261122-b4-02-act-ife-rtnl-uaf-v2-102eba468698-d819f7ac7006

Best regards,
--  
YanXin Li <fadouse@pm.me>

