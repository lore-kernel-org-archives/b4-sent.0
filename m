From: Simon Baatz <gmbnomis@gmail.com>
Date: Mon, 09 Mar 2026 09:02:27 +0100
Subject: [PATCH net-next v3 2/6] mptcp: keep rcv_mwnd_seq in sync with
 subflow rcv_wnd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-2-4c7f96b1ec69@gmail.com>
References: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-0-4c7f96b1ec69@gmail.com>
In-Reply-To: <20260309-tcp_rfc7323_retract_wnd_rfc-v3-0-4c7f96b1ec69@gmail.com>
To: Eric Dumazet <edumazet@google.com>, 
 Neal Cardwell <ncardwell@google.com>, Kuniyuki Iwashima <kuniyu@google.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 David Ahern <dsahern@kernel.org>, Jon Maloy <jmaloy@redhat.com>, 
 Jason Xing <kerneljasonxing@gmail.com>, mfreemon@cloudflare.com, 
 Shuah Khan <shuah@kernel.org>, Stefano Brivio <sbrivio@redhat.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 mptcp@lists.linux.dev, Simon Baatz <gmbnomis@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773043425; l=1316;
 i=gmbnomis@gmail.com; s=20260220; h=from:subject:message-id;
 bh=ChftbPgxBgowAH5jlThlLmD2ZcIdQ5MNv0dOVMZk0bc=;
 b=ebwxj9jswhY7N+FX93x/tqn0TUOf6ljdixhMtvB9X8ZTBTSLzUET9CMuG0w7U6djoehuAO9z1
 K6f847zwt1VANVMgE8WgLKsGJzlx1Qb2yKGdLXsQZf0vswy9hFLWe/W
X-Developer-Key: i=gmbnomis@gmail.com; a=ed25519;
 pk=T/JIz/6F5bf1uQJr69lmyi7czVG+F9TVZ/8x5z9Wtqw=
X-Endpoint-Received: by B4 Relay for gmbnomis@gmail.com/20260220 with auth_id=641
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MPTCP shares a receive window across subflows and applies it at the
subflow level by adjusting each subflow's rcv_wnd when needed.  With
the new TCP tracking of the maximum advertised window sequence,
rcv_mwnd_seq must stay consistent with these subflow-level rcv_wnd
adjustments.

Signed-off-by: Simon Baatz <gmbnomis@gmail.com>
---
 net/mptcp/options.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/net/mptcp/options.c b/net/mptcp/options.c
index 43df4293f58bfbd8a8df6bf24b9f15e0f9e238f6..8a1c5698983cff3082d68290626dd8f1e044527f 100644
--- a/net/mptcp/options.c
+++ b/net/mptcp/options.c
@@ -1076,6 +1076,7 @@ static void rwin_update(struct mptcp_sock *msk, struct sock *ssk,
 	 * resync.
 	 */
 	tp->rcv_wnd += mptcp_rcv_wnd - subflow->rcv_wnd_sent;
+	tcp_update_max_rcv_wnd_seq(tp);
 	subflow->rcv_wnd_sent = mptcp_rcv_wnd;
 }
 
@@ -1338,8 +1339,9 @@ static void mptcp_set_rwin(struct tcp_sock *tp, struct tcphdr *th)
 		 */
 		rcv_wnd_new = rcv_wnd_old;
 		win = rcv_wnd_old - ack_seq;
-		tp->rcv_wnd = min_t(u64, win, U32_MAX);
-		new_win = tp->rcv_wnd;
+		new_win = min_t(u64, win, U32_MAX);
+		tp->rcv_wnd = new_win;
+		tcp_update_max_rcv_wnd_seq(tp);
 
 		/* Make sure we do not exceed the maximum possible
 		 * scaled window.

-- 
2.53.0

