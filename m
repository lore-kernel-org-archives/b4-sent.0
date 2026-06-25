From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Thu, 25 Jun 2026 17:54:31 +0100
Subject: [PATCH net v3 3/3] tcp: Decrement tcp_md5_needed static branch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-tcp-md5-connect-v3-3-30827ed58b6d@gmail.com>
References: <20260625-tcp-md5-connect-v3-0-30827ed58b6d@gmail.com>
In-Reply-To: <20260625-tcp-md5-connect-v3-0-30827ed58b6d@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>
Cc: Michael Bommarito <michael.bommarito@gmail.com>, 
 Qihang <q.h.hack.winter@gmail.com>, security@kernel.org, 
 Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782406484; l=1051;
 i=0x7f454c46@gmail.com; s=20260625; h=from:subject:message-id;
 bh=ZyjR9+81UGvfCbsPhJrBEkJxICoRArwiqpiWthbpNyw=;
 b=YiI52YYGx1uLcf1MhzOs03Oa7I+0PyNzVJ2iSFdYEd0Zxoi5RNnks+rWitZeL2eEM291fXwjE
 kZxiI2WLmzRBVS2v5ZyzeWqgijkIgmMJmhFS7Bj+UhrdEIQ9hkOND/5
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=clHVGbfKfZMeCUp+xCL/096jI68XK5EZLytgy6lSyrc=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20260625 with auth_id=841
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In case of early freeing an unwanted TCP-MD5 key on TCP-AO connect(),
md5sig_info is freed right away (and set to NULL). Later, at
the moment of socket destruction, the static branch counter
is not getting decremented.

Add a missing decrement for TCP-MD5 static branch.

Reported-by: Qihang <q.h.hack.winter@gmail.com>
Fixes: 0aadc73995d0 ("net/tcp: Prevent TCP-MD5 with TCP-AO being set")
Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/ipv4/tcp_output.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/ipv4/tcp_output.c b/net/ipv4/tcp_output.c
index bc03809ca3af..d7c1444b5e30 100644
--- a/net/ipv4/tcp_output.c
+++ b/net/ipv4/tcp_output.c
@@ -4334,8 +4334,8 @@ int tcp_connect(struct sock *sk)
 			tcp_clear_md5_list(sk);
 			md5sig = rcu_replace_pointer(tp->md5sig_info, NULL,
 						     lockdep_sock_is_held(sk));
-			if (md5sig)
-				kfree_rcu(md5sig, rcu);
+			kfree_rcu(md5sig, rcu);
+			static_branch_slow_dec_deferred(&tcp_md5_needed);
 		}
 	}
 #endif

-- 
2.51.2

