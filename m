From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 25 Jun 2026 17:54:29 +0100
Subject: [PATCH net v3 1/3] tcp: restore RCU grace period in
 tcp_ao_destroy_sock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-tcp-md5-connect-v3-1-30827ed58b6d@gmail.com>
References: <20260625-tcp-md5-connect-v3-0-30827ed58b6d@gmail.com>
In-Reply-To: <20260625-tcp-md5-connect-v3-0-30827ed58b6d@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Michael Bommarito <michael.bommarito@gmail.com>, 
 Qihang <q.h.hack.winter@gmail.com>, security@kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782406484; l=4399;
 i=0x7f454c46@gmail.com; s=20260625; h=from:subject:message-id;
 bh=91Ckr0Ol4FD0E5NPfp4X6E7HWbFDC21WwtP7RBKxvF4=;
 b=WHbPq28Rrnut4uKPTV6yxkEGxuWxolGXMv8x8yivlqKj9VtMJFSdvZK/8+MAMtw2a5MHKLrmJ
 gUZKj5o4YLbD++rHx9j8H5WawPdWd0QBdU5s8B0+a0t+2GhmBNwbzGe
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=clHVGbfKfZMeCUp+xCL/096jI68XK5EZLytgy6lSyrc=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20260625 with auth_id=841
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Bommarito <michael.bommarito@gmail.com>

Commit 51e547e8c89c ("tcp: Free TCP-AO/TCP-MD5 info/keys without RCU")
removed the call_rcu() callback from tcp_ao_destroy_sock(), arguing that
"the destruction of info/keys is delayed until the socket destructor"
and therefore "no one can discover it anymore".

That argument does not hold for the call site in tcp_connect()
(net/ipv4/tcp_output.c:4327-4332). At that point the socket is in
TCP_SYN_SENT, has already been inserted into the inet ehash by
inet_hash_connect() in tcp_v4_connect(), and is therefore very much
discoverable: any softirq running tcp_v4_rcv() on another CPU can take
the socket out of the ehash, walk into tcp_inbound_hash(), and load
tp->ao_info via implicit RCU before bh_lock_sock_nested() is taken on
the destroying CPU.

The reader path then enters __tcp_ao_do_lookup() (net/ipv4/tcp_ao.c:208)
which re-loads tp->ao_info via rcu_dereference_check(); the re-load can
still observe the (about-to-be-freed) pointer because there is no
synchronize_rcu() between rcu_assign_pointer(tp->ao_info, NULL) and
tcp_ao_info_free() in tcp_ao_destroy_sock(). The captured pointer is
then walked at line 223:

	hlist_for_each_entry_rcu(key, &ao->head, node, ...)

The writer's synchronous kfree() is free to complete between the line
218 re-fetch and the line 223 hlist iteration. The slab is reused
(or simply LIST_POISON1-stamped if not yet reused) and the iteration
walks attacker-controlled or poison memory in softirq context.

Reproducer (no debug shim, stock x86_64 v7.1-rc2 SMP+KASAN, QEMU+KVM):
an unprivileged uid=1000 process inside CLONE_NEWUSER|CLONE_NEWNET
installs TCP_MD5SIG + TCP_AO_ADD_KEY on a TCP socket, sprays forged
TCP-AO segments toward its eventual 4-tuple via raw sockets, then
calls connect(). The md5-wins reconciliation in tcp_connect() fires
tcp_ao_destroy_sock(); the softirq backlog reader on the loopback
NAPI path crashes on the freed ao->head.first walk:

  Oops: general protection fault, probably for non-canonical
    address 0xfbd59c000000002f
  KASAN: maybe wild-memory-access in range
    [0xdead000000000178-0xdead00000000017f]
  CPU: 0 UID: 1000 PID: 100 Comm: repro_userns
  RIP: 0010:__tcp_ao_do_lookup+0x107/0x1c0
  Call Trace: <IRQ>
    __tcp_ao_do_lookup+0x107/0x1c0
    tcp_ao_inbound_lookup.constprop.0+0x12a/0x200
    tcp_inbound_ao_hash+0x5ea/0x1520
    tcp_inbound_hash+0x7ce/0x1240
    tcp_v4_rcv+0x1e7a/0x3e10
    ...

Restore the RCU grace period: re-add struct rcu_head to tcp_ao_info
and replace the synchronous tcp_ao_info_free() with a call_rcu()
callback. Readers that captured tp->ao_info before rcu_assign_pointer
NULLed it now see the object remain valid until rcu_read_unlock().
With the patch applied the reproducer runs cleanly for 2000 iterations
on the same kernel build.

Fixes: 51e547e8c89c ("tcp: Free TCP-AO/TCP-MD5 info/keys without RCU")
Reviewed-by: Dmitry Safonov <dima@arista.com>
Signed-off-by: Michael Bommarito <michael.bommarito@gmail.com>
Assisted-by: Claude:claude-opus-4-7
Reviewed-by: Eric Dumazet <edumazet@google.com>
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 include/net/tcp_ao.h | 1 +
 net/ipv4/tcp_ao.c    | 5 +++--
 2 files changed, 4 insertions(+), 2 deletions(-)

diff --git a/include/net/tcp_ao.h b/include/net/tcp_ao.h
index 29fd7b735afa..9a2333e62e99 100644
--- a/include/net/tcp_ao.h
+++ b/include/net/tcp_ao.h
@@ -145,6 +145,7 @@ struct tcp_ao_info {
 	u32			snd_sne;
 	u32			rcv_sne;
 	refcount_t		refcnt;		/* Protects twsk destruction */
+	struct rcu_head		rcu;
 };
 
 #ifdef CONFIG_TCP_MD5SIG
diff --git a/net/ipv4/tcp_ao.c b/net/ipv4/tcp_ao.c
index a56bb79e15e0..e4ec60a33496 100644
--- a/net/ipv4/tcp_ao.c
+++ b/net/ipv4/tcp_ao.c
@@ -371,8 +371,9 @@ static void tcp_ao_key_free_rcu(struct rcu_head *head)
 	kfree_sensitive(key);
 }
 
-static void tcp_ao_info_free(struct tcp_ao_info *ao)
+static void tcp_ao_info_free_rcu(struct rcu_head *head)
 {
+	struct tcp_ao_info *ao = container_of(head, struct tcp_ao_info, rcu);
 	struct tcp_ao_key *key;
 	struct hlist_node *n;
 
@@ -411,7 +412,7 @@ void tcp_ao_destroy_sock(struct sock *sk, bool twsk)
 
 	if (!twsk)
 		tcp_ao_sk_omem_free(sk, ao);
-	tcp_ao_info_free(ao);
+	call_rcu(&ao->rcu, tcp_ao_info_free_rcu);
 }
 
 void tcp_ao_time_wait(struct tcp_timewait_sock *tcptw, struct tcp_sock *tp)

-- 
2.51.2

