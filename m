From: Simon Baatz <gmbnomis@gmail.com>
Date: Wed, 08 Apr 2026 23:50:07 +0200
Subject: [PATCH net-next 6/7] tcp: use tcp_set_window_clamp() for
 SO_RCVLOWAT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-6-76a6f212e153@gmail.com>
References: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
In-Reply-To: <20260408-tcp_rcv_exact_clamp_and_wnd-v1-0-76a6f212e153@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, David Ahern <dsahern@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775685040; l=840;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=YX2cO/5mpSzXQomZxTf4zIIjeQiySv9/NccTLoZ6hE8=;
 b=uSmFS+H0UrO5bmZ2d6kTWUrR2F8Q2onjHcSAGM7MOr6umiI6WvCeOqE2IJI50FZMizn6xiGkZ
 E2/EnAMitWpCzHEVQcKmizcdmqtu+KYw6DBcEy5uYFSSNGs3IsH4T6T
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Setting the SO_RCVLOWAT socket option may raise the receive window
clamp. Currently this is done by assigning to window_clamp directly.

Use the tcp_set_window_clamp() helper instead, so that raising the
clamp is subject to the same constraints and rcv_ssthresh adjustments
as TCP_WINDOW_CLAMP.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/net/ipv4/tcp.c b/net/ipv4/tcp.c
index bd03c99f793ae..567027bc86b3f 100644
--- a/net/ipv4/tcp.c
+++ b/net/ipv4/tcp.c
@@ -1853,7 +1853,7 @@ int tcp_set_rcvlowat(struct sock *sk, int val)
 		WRITE_ONCE(sk->sk_rcvbuf, space);
 
 		if (tp->window_clamp && tp->window_clamp < val)
-			WRITE_ONCE(tp->window_clamp, val);
+			tcp_set_window_clamp(sk, val);
 	}
 	return 0;
 }

-- 
2.53.0

