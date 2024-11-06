From: Dmitry Safonov <0x7f454c46@gmail.com>
Date: Wed, 06 Nov 2024 18:10:19 +0000
Subject: [PATCH net 6/6] net/netlink: Correct the comment on netlink
 message max cap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241106-tcp-md5-diag-prep-v1-6-d62debf3dded@gmail.com>
References: <20241106-tcp-md5-diag-prep-v1-0-d62debf3dded@gmail.com>
In-Reply-To: <20241106-tcp-md5-diag-prep-v1-0-d62debf3dded@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 David Ahern <dsahern@kernel.org>, Ivan Delalande <colona@arista.com>, 
 Matthieu Baerts <matttbe@kernel.org>, Mat Martineau <martineau@kernel.org>, 
 Geliang Tang <geliang@kernel.org>, Boris Pismenny <borisp@nvidia.com>, 
 John Fastabend <john.fastabend@gmail.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mptcp@lists.linux.dev, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730918994; l=1447;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=Kmj21DwNJNOs65kiQumd7s7cSWkgFWMCJrFg+lJ9ggE=;
 b=ITm5BD/vJrJwTvNmV1V6c7esw02waru8s1F/KcRHpnPwih8VvLb5zrhOJkimS2VHKQBziP56v
 jdM9oPDoaHECjZpmFpJOoueAzKPXBTDCuVXLCz8+ouoidSykBvuUtd8
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit d35c99ff77ec ("netlink: do not enter direct reclaim from
netlink_dump()") the cap is 32KiB.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
 net/netlink/af_netlink.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/net/netlink/af_netlink.c b/net/netlink/af_netlink.c
index 0a9287fadb47a2afaf0babe675738bc43051c5a7..27979cefc06256bde052898d193ed99f710c2087 100644
--- a/net/netlink/af_netlink.c
+++ b/net/netlink/af_netlink.c
@@ -2279,7 +2279,7 @@ static int netlink_dump(struct sock *sk, bool lock_taken)
 		goto errout_skb;
 
 	/* NLMSG_GOODSIZE is small to avoid high order allocations being
-	 * required, but it makes sense to _attempt_ a 16K bytes allocation
+	 * required, but it makes sense to _attempt_ a 32KiB allocation
 	 * to reduce number of system calls on dump operations, if user
 	 * ever provided a big enough buffer.
 	 */
@@ -2301,7 +2301,7 @@ static int netlink_dump(struct sock *sk, bool lock_taken)
 		goto errout_skb;
 
 	/* Trim skb to allocated size. User is expected to provide buffer as
-	 * large as max(min_dump_alloc, 16KiB (mac_recvmsg_len capped at
+	 * large as max(min_dump_alloc, 32KiB (max_recvmsg_len capped at
 	 * netlink_recvmsg())). dump will pack as many smaller messages as
 	 * could fit within the allocated skb. skb is typically allocated
 	 * with larger space than required (could be as much as near 2x the

-- 
2.42.2

