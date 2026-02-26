From: Simon Baatz <gmbnomis@gmail.com>
Date: Thu, 26 Feb 2026 01:49:08 +0100
Subject: [PATCH RFC net-next v2 2/5] tcp: increase LINUX_MIB_BEYOND_WINDOW
 for SKB_DROP_REASON_TCP_OVERWINDOW
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-2-aa3f8f9cc639@gmail.com>
References: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
In-Reply-To: <20260226-tcp_rfc7323_retract_wnd_rfc-v2-0-aa3f8f9cc639@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Jon Maloy <jmaloy@redhat.com>, Jason Xing <kerneljasonxing@gmail.com>, 
 mfreemon@cloudflare.com, Shuah Khan <shuah@kernel.org>, 
 Stefano Brivio <sbrivio@redhat.com>
Cc: Christian Ebner <c.ebner@proxmox.com>, netdev@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772066964; l=994;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=93fRnxWZqbnzx4Mxdc8zEz40T5BbuQ5V9PbYF4g/mgk=;
 b=YUzvuvtU4ngaLSbzzTBtAqZv0HBJyEl8GgWKQ11NZIm8QNVuWZhqCk617T2fb1XOrx1VC/+tL
 Vgr6L7j1NoQBNOy+dLtIFoqU1H3+5jOB24pVhMRxaW1Owgpg2WGTlQs
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit 9ca48d616ed7 ("tcp: do not accept packets beyond
window"), the path leading to SKB_DROP_REASON_TCP_OVERWINDOW in
tcp_data_queue() is probably dead. However, it can be reached now when
tcp_max_receive_window() is larger than tcp_receive_window(). In that
case, increment LINUX_MIB_BEYOND_WINDOW as done in tcp_sequence().

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/ipv4/tcp_input.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/net/ipv4/tcp_input.c b/net/ipv4/tcp_input.c
index af9dd51256b01fd31d9e390d69dcb1d1700daf1b..f0ee3a599755aff00a00236728b430c7883087ff 100644
--- a/net/ipv4/tcp_input.c
+++ b/net/ipv4/tcp_input.c
@@ -5739,6 +5739,7 @@ static void tcp_data_queue(struct sock *sk, struct sk_buff *skb)
 	if (!before(TCP_SKB_CB(skb)->seq,
 		    tp->rcv_nxt + tcp_receive_window(tp))) {
 		reason = SKB_DROP_REASON_TCP_OVERWINDOW;
+		NET_INC_STATS(sock_net(sk), LINUX_MIB_BEYOND_WINDOW);
 		goto out_of_window;
 	}
 

-- 
2.53.0

