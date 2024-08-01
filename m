From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 01 Aug 2024 01:13:28 +0100
Subject: [PATCH net v3] net/tcp: Disable TCP-AO static key after RCU grace
 period
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240801-tcp-ao-static-branch-rcu-v3-1-3ca33048c22d@gmail.com>
X-B4-Tracking: v=1; b=H4sIACfTqmYC/4WOyw6CMBBFf4V07Zg+JKAr/8O4mLYDNJFH2ko0h
 H+3NC5Y6fLezDl3FhbIOwrsUizM0+yCG4cU1KFgpsOhJXA2ZSa5PPFKlhDNBDhCiBidAe1xMB1
 484S6JEuVViiwZAmfPDXuldU3NlBk91RqDPSFNmuPIZLfrjsX4ujf+Y9ZZOb/5CxAAJfCcn7WR
 Lq5tj26x9GMfV6b5U6k+A+RTCKlrJG6Qoum3ovWdf0AgM+DECcBAAA=
To: Eric Dumazet <edumazet@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, stable@kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722471215; l=5851;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=AMceMNy2bOf+JNzk9oevjAJDEUtxUX1MK9dm/anY1u4=;
 b=kqtCgkt2IquNX24sZjJGmqKySAXUg00QDnkAANxFWa2mXV8QWD4f9DrJTqN9+sB2gtgqtA6iX
 UMztOE7H2LND8Qbov+k+H0vtXsv5Cp8HBQ2NVQcK525gyKfxSH9vz1r
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lifetime of TCP-AO static_key is the same as the last
tcp_ao_info. On the socket destruction tcp_ao_info ceases to be
with RCU grace period, while tcp-ao static branch is currently deferred
destructed. The static key definition is
: DEFINE_STATIC_KEY_DEFERRED_FALSE(tcp_ao_needed, HZ);

which means that if RCU grace period is delayed by more than a second
and tcp_ao_needed is in the process of disablement, other CPUs may
yet see tcp_ao_info which atent dead, but soon-to-be.
And that breaks the assumption of static_key_fast_inc_not_disabled().

See the comment near the definition:
> * The caller must make sure that the static key can't get disabled while
> * in this function. It doesn't patch jump labels, only adds a user to
> * an already enabled static key.

Originally it was introduced in commit eb8c507296f6 ("jump_label:
Prevent key->enabled int overflow"), which is needed for the atomic
contexts, one of which would be the creation of a full socket from a
request socket. In that atomic context, it's known by the presence
of the key (md5/ao) that the static branch is already enabled.
So, the ref counter for that static branch is just incremented
instead of holding the proper mutex.
static_key_fast_inc_not_disabled() is just a helper for such usage
case. But it must not be used if the static branch could get disabled
in parallel as it's not protected by jump_label_mutex and as a result,
races with jump_label_update() implementation details.

Happened on netdev test-bot[1], so not a theoretical issue:

[] jump_label: Fatal kernel bug, unexpected op at tcp_inbound_hash+0x1a7/0x870 [ffffffffa8c4e9b7] (eb 50 0f 1f 44 != 66 90 0f 1f 00)) size:2 type:1
[] ------------[ cut here ]------------
[] kernel BUG at arch/x86/kernel/jump_label.c:73!
[] Oops: invalid opcode: 0000 [#1] PREEMPT SMP KASAN NOPTI
[] CPU: 3 PID: 243 Comm: kworker/3:3 Not tainted 6.10.0-virtme #1
[] Hardware name: QEMU Standard PC (i440FX + PIIX, 1996), BIOS rel-1.16.3-0-ga6ed6b701f0a-prebuilt.qemu.org 04/01/2014
[] Workqueue: events jump_label_update_timeout
[] RIP: 0010:__jump_label_patch+0x2f6/0x350
...
[] Call Trace:
[]  <TASK>
[]  arch_jump_label_transform_queue+0x6c/0x110
[]  __jump_label_update+0xef/0x350
[]  __static_key_slow_dec_cpuslocked.part.0+0x3c/0x60
[]  jump_label_update_timeout+0x2c/0x40
[]  process_one_work+0xe3b/0x1670
[]  worker_thread+0x587/0xce0
[]  kthread+0x28a/0x350
[]  ret_from_fork+0x31/0x70
[]  ret_from_fork_asm+0x1a/0x30
[]  </TASK>
[] Modules linked in: veth
[] ---[ end trace 0000000000000000 ]---
[] RIP: 0010:__jump_label_patch+0x2f6/0x350

[1]: https://netdev-3.bots.linux.dev/vmksft-tcp-ao-dbg/results/696681/5-connect-deny-ipv6/stderr

Cc: stable@kernel.org
Fixes: 67fa83f7c86a ("net/tcp: Add static_key for TCP-AO")
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Changes in v3:
- Use hlist_for_each_entry() instead of hlist_for_each_entry_safe() in
  tcp_ao_sk_omem_free() (Jakub's suggestion)
- While at it, use hlist_del() instead of hlist_del_rcu() in
  tcp_ao_info_free_rcu()
- Link to v2: https://lore.kernel.org/r/20240730-tcp-ao-static-branch-rcu-v2-1-33dc2b7adac8@gmail.com

Changes in v2:
- Use rcu_assign_pointer() in tcp_ao_destroy_sock()
- Combined both ao_info and keys destruction in one RCU callback,
  tcp_ao_info_free_rcu() (suggested-by Jakub)
- Hopefully improved a bit the commit message
- Link to v1: https://lore.kernel.org/r/20240725-tcp-ao-static-branch-rcu-v1-1-021d009beebf@gmail.com
---
 net/ipv4/tcp_ao.c | 43 ++++++++++++++++++++++++++++++-------------
 1 file changed, 30 insertions(+), 13 deletions(-)

diff --git a/net/ipv4/tcp_ao.c b/net/ipv4/tcp_ao.c
index 85531437890c..db6516092daf 100644
--- a/net/ipv4/tcp_ao.c
+++ b/net/ipv4/tcp_ao.c
@@ -267,32 +267,49 @@ static void tcp_ao_key_free_rcu(struct rcu_head *head)
 	kfree_sensitive(key);
 }
 
-void tcp_ao_destroy_sock(struct sock *sk, bool twsk)
+static void tcp_ao_info_free_rcu(struct rcu_head *head)
 {
-	struct tcp_ao_info *ao;
+	struct tcp_ao_info *ao = container_of(head, struct tcp_ao_info, rcu);
 	struct tcp_ao_key *key;
 	struct hlist_node *n;
 
+	hlist_for_each_entry_safe(key, n, &ao->head, node) {
+		hlist_del(&key->node);
+		tcp_sigpool_release(key->tcp_sigpool_id);
+		kfree_sensitive(key);
+	}
+	kfree(ao);
+	static_branch_slow_dec_deferred(&tcp_ao_needed);
+}
+
+static void tcp_ao_sk_omem_free(struct sock *sk, struct tcp_ao_info *ao)
+{
+	size_t total_ao_sk_mem = 0;
+	struct tcp_ao_key *key;
+
+	hlist_for_each_entry(key,  &ao->head, node)
+		total_ao_sk_mem += tcp_ao_sizeof_key(key);
+	atomic_sub(total_ao_sk_mem, &sk->sk_omem_alloc);
+}
+
+void tcp_ao_destroy_sock(struct sock *sk, bool twsk)
+{
+	struct tcp_ao_info *ao;
+
 	if (twsk) {
 		ao = rcu_dereference_protected(tcp_twsk(sk)->ao_info, 1);
-		tcp_twsk(sk)->ao_info = NULL;
+		rcu_assign_pointer(tcp_twsk(sk)->ao_info, NULL);
 	} else {
 		ao = rcu_dereference_protected(tcp_sk(sk)->ao_info, 1);
-		tcp_sk(sk)->ao_info = NULL;
+		rcu_assign_pointer(tcp_sk(sk)->ao_info, NULL);
 	}
 
 	if (!ao || !refcount_dec_and_test(&ao->refcnt))
 		return;
 
-	hlist_for_each_entry_safe(key, n, &ao->head, node) {
-		hlist_del_rcu(&key->node);
-		if (!twsk)
-			atomic_sub(tcp_ao_sizeof_key(key), &sk->sk_omem_alloc);
-		call_rcu(&key->rcu, tcp_ao_key_free_rcu);
-	}
-
-	kfree_rcu(ao, rcu);
-	static_branch_slow_dec_deferred(&tcp_ao_needed);
+	if (!twsk)
+		tcp_ao_sk_omem_free(sk, ao);
+	call_rcu(&ao->rcu, tcp_ao_info_free_rcu);
 }
 
 void tcp_ao_time_wait(struct tcp_timewait_sock *tcptw, struct tcp_sock *tp)

---
base-commit: 21b136cc63d2a9ddd60d4699552b69c214b32964
change-id: 20240725-tcp-ao-static-branch-rcu-85ede7b3a1a5

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

