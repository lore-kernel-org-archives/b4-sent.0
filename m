From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 25 Jun 2026 19:21:40 +0100
Subject: [PATCH net v3 2/3] tcp: defer md5sig_info kfree past RCU grace
 period in tcp_connect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-tcp-md5-connect-v3-2-1fd313d6c1e0@gmail.com>
References: <20260625-tcp-md5-connect-v3-0-1fd313d6c1e0@gmail.com>
In-Reply-To: <20260625-tcp-md5-connect-v3-0-1fd313d6c1e0@gmail.com>
To: David Ahern <dsahern@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Salam Noureddine <noureddine@arista.com>
Cc: Michael Bommarito <michael.bommarito@gmail.com>, 
 Qihang <q.h.hack.winter@gmail.com>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>, 
 stable@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782411722; l=4975;
 i=0x7f454c46@gmail.com; s=20260625; h=from:subject:message-id;
 bh=rwR9oxxgK8rnbEgI9ngZgk8acfHkfL6iVNB5+wJyuyY=;
 b=onZnxH/ETX6Yb5pxGub2sJoTx8MbenBso3/bP/RHVJMsnKEwPETubBovBFQIE3ZOWHOIjSjYB
 eO4+N4OsoXHAzLVqWPRG2LFcpdTtVN20qqdgBFn+ZOlofI7dcAJiiZF
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=clHVGbfKfZMeCUp+xCL/096jI68XK5EZLytgy6lSyrc=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20260625 with auth_id=841
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Bommarito <michael.bommarito@gmail.com>

The md5+ao reconciliation in tcp_connect() (net/ipv4/tcp_output.c)
has two symmetric branches:

	if (needs_md5) {
		tcp_ao_destroy_sock(sk, false);
	} else if (needs_ao) {
		tcp_clear_md5_list(sk);
		kfree(rcu_replace_pointer(tp->md5sig_info, NULL, ...));
	}

Both branches free a per-socket auth-info object while the socket is
in TCP_SYN_SENT and is already on the inet ehash (inserted by
inet_hash_connect() in tcp_v4_connect()). Both branches are reachable
by softirq RX-path readers that load the corresponding info pointer
via implicit RCU before bh_lock_sock_nested() is taken.

The needs_md5 branch is fixed in the prior patch by re-introducing
the call_rcu() free in tcp_ao_destroy_sock(): the equivalent per-key
loop runs inside tcp_ao_info_free_rcu(), the RCU callback, so by the
time it frees each tcp_ao_key all softirq readers that captured the
container have already completed rcu_read_unlock().

The needs_ao branch is not symmetric in the same way. The container
free can be deferred via kfree_rcu(md5sig, rcu) -- struct
tcp_md5sig_info already has the required rcu member
(include/net/tcp.h:1999-2002), and the rest of the tree already does
this in the tcp_md5sig_info_add() rollback paths
(net/ipv4/tcp_ipv4.c:1410, 1436). But the per-key teardown is done
by tcp_clear_md5_list() in process context BEFORE the container's
RCU grace period: it walks &md5sig->head and frees each
tcp_md5sig_key with bare hlist_del + kfree. A concurrent softirq
reader in __tcp_md5_do_lookup() / __tcp_md5_do_lookup_exact()
(tcp_ipv4.c:1253, 1298) walks the same list via
hlist_for_each_entry_rcu() and races with that bare kfree on the
keys themselves -- a per-key slab use-after-free of the same class
as the TCP-AO bug, on the same race window.

Fix this in two halves:

  1. Convert the bare kfree() in tcp_connect() to kfree_rcu() so the
     md5sig_info container joins the rest of the md5sig lifecycle.
     The local-variable lift is mechanical and required because
     kfree_rcu() is a macro that expects an lvalue.

  2. Make tcp_clear_md5_list() RCU-safe by replacing hlist_del +
     kfree(key) with hlist_del_rcu + kfree_rcu(key, rcu). struct
     tcp_md5sig_key already carries the rcu member
     (include/net/tcp.h:1995) and tcp_md5_do_del()
     (net/ipv4/tcp_ipv4.c:1456) already uses kfree_rcu, so this
     restores the lifecycle invariant the rest of the file follows
     rather than introducing a one-off.

The other caller of tcp_clear_md5_list() is tcp_md5_destruct_sock()
(net/ipv4/tcp.c:412), which runs from the sock destructor when the
socket is already unhashed and unreachable; the extra grace period
there is unnecessary but harmless. Making the helper unconditionally
RCU-safe is the cleaner contract.

The needs_ao branch is not reachable by the userns reproducer used
to demonstrate the AO-side splat (the repro installs both keys but
ends up in the needs_md5 branch because the connect peer matches
the MD5 key, not the AO key); however the symmetric race exists
and a maintainer touching this code should not have to think about
which branch escapes RCU and which one does not.

Fixes: 51e547e8c89c ("tcp: Free TCP-AO/TCP-MD5 info/keys without RCU")
Cc: stable@vger.kernel.org # v6.18+
Suggested-by: Eric Dumazet <edumazet@google.com>
Signed-off-by: Michael Bommarito <michael.bommarito@gmail.com>
Assisted-by: Claude:claude-opus-4-7
Reviewed-by: Dmitry Safonov <dima@arista.com>
Reviewed-by: Eric Dumazet <edumazet@google.com>
[also credits to Qihang, who found that this races with tcp-diag]
Reported-by: Qihang <q.h.hack.winter@gmail.com>
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/ipv4/tcp_ipv4.c   | 4 ++--
 net/ipv4/tcp_output.c | 8 ++++++--
 2 files changed, 8 insertions(+), 4 deletions(-)

diff --git a/net/ipv4/tcp_ipv4.c b/net/ipv4/tcp_ipv4.c
index ec09f97cc9e6..209ef7522508 100644
--- a/net/ipv4/tcp_ipv4.c
+++ b/net/ipv4/tcp_ipv4.c
@@ -1467,9 +1467,9 @@ void tcp_clear_md5_list(struct sock *sk)
 	md5sig = rcu_dereference_protected(tp->md5sig_info, 1);
 
 	hlist_for_each_entry_safe(key, n, &md5sig->head, node) {
-		hlist_del(&key->node);
+		hlist_del_rcu(&key->node);
 		atomic_sub(sizeof(*key), &sk->sk_omem_alloc);
-		kfree(key);
+		kfree_rcu(key, rcu);
 	}
 }
 
diff --git a/net/ipv4/tcp_output.c b/net/ipv4/tcp_output.c
index 00ec4b5900f2..bc03809ca3af 100644
--- a/net/ipv4/tcp_output.c
+++ b/net/ipv4/tcp_output.c
@@ -4329,9 +4329,13 @@ int tcp_connect(struct sock *sk)
 		if (needs_md5) {
 			tcp_ao_destroy_sock(sk, false);
 		} else if (needs_ao) {
+			struct tcp_md5sig_info *md5sig;
+
 			tcp_clear_md5_list(sk);
-			kfree(rcu_replace_pointer(tp->md5sig_info, NULL,
-						  lockdep_sock_is_held(sk)));
+			md5sig = rcu_replace_pointer(tp->md5sig_info, NULL,
+						     lockdep_sock_is_held(sk));
+			if (md5sig)
+				kfree_rcu(md5sig, rcu);
 		}
 	}
 #endif

-- 
2.51.2

