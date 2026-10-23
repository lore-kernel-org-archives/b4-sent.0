From: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
Date: Fri, 23 Oct 2026 13:26:07 +0200
Subject: [PATCH net 1/2] netlink: retry a dump skb that does not fit with
 the minimum size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-netlink-dump-livelock-v1-1-478214a635d2@gmail.com>
References: <20261023-netlink-dump-livelock-v1-0-478214a635d2@gmail.com>
In-Reply-To: <20261023-netlink-dump-livelock-v1-0-478214a635d2@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Kuniyuki Iwashima <kuniyu@google.com>, 
 Jhonata Poma-Hansen <jhonata.poma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2113;
 i=jhonata.poma@gmail.com; h=from:subject:message-id;
 bh=wpiSXo5U0PAbR1oO+UlU/ssinpjnck+7Z7pQkTuLTv8=;
 b=owGbwMvMwCX21S6Y7aK9oS7jabUkhqzbLv4TN7/T0dzqESTLuX5WpoopX9pVz5DKved6xaR7j
 x/ReqfdUcrCIMbFICumyOJz9nEPt+LHHf8f7rgMM4eVCWQIAxenAEyEj53hF9Pm395xN2rPsbas
 n3ZZWjZEf0/StDndDSGNKTeWfthwbSIjw8q23LKf0QdzH/J/F1dOWVp2kEHm+M/NNYr9m+aofwh
 5ywIA
X-Developer-Key: i=jhonata.poma@gmail.com; a=openpgp;
 fpr=4CCDE38C0B21F1B8FFE1B8D3F53E5306D13F312D
X-Endpoint-Received: by B4 Relay for jhonata.poma@gmail.com/default with auth_id=1288
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

netlink_dump() sizes the skb after the largest buffer the reader passed
to recvmsg(), up to 32KiB. Since commit ae8f160e7eb2 ("netlink: Fix
wraparounds of sk->sk_rmem_alloc.") the skb is only queued if it fits
in sk_rcvbuf, or if nothing else is charged to the socket.

A reader with a small receive buffer that still has data charged to
its socket when a dump starts gets ENOBUFS, even when a minimum size
skb would fit. The dump stays marked as running and every recvmsg()
retries it, so a reader that peeks before reading, as libnl does,
never consumes the data at the head of the queue and spins forever.

"iw dev wlan0 scan" hits this: its socket has an 8KiB buffer, it joins
the nl80211 multicast groups, and it dumps the scan results as soon as
it has read the NEW_SCAN_RESULTS notification. When it preempts the
sender, the notification is still charged to its socket until
netlink_broadcast() returns, the dump fails to start and iw spins at
100% CPU.

Retry with alloc_min_size before failing the dump.

Fixes: ae8f160e7eb2 ("netlink: Fix wraparounds of sk->sk_rmem_alloc.")
Signed-off-by: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
---
 net/netlink/af_netlink.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/net/netlink/af_netlink.c b/net/netlink/af_netlink.c
index a904dc3bc..b750e79fe 100644
--- a/net/netlink/af_netlink.c
+++ b/net/netlink/af_netlink.c
@@ -2318,10 +2318,21 @@ static int netlink_dump(struct sock *sk, bool lock_taken)
 	if (!skb)
 		goto errout_skb;
 
+retry:
 	rcvbuf = READ_ONCE(sk->sk_rcvbuf);
 	rmem = atomic_add_return(skb->truesize, &sk->sk_rmem_alloc);
 	if (rmem != skb->truesize && rmem >= rcvbuf) {
 		atomic_sub(skb->truesize, &sk->sk_rmem_alloc);
+		/* A skb sized after max_recvmsg_len may not fit next to data
+		 * still charged to the socket, while a minimum size one does.
+		 */
+		if (alloc_size > alloc_min_size) {
+			kfree_skb(skb);
+			alloc_size = alloc_min_size;
+			skb = alloc_skb(alloc_size, GFP_KERNEL);
+			if (skb)
+				goto retry;
+		}
 		goto errout_skb;
 	}
 

-- 
2.54.0

