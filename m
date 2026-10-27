From: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
Date: Tue, 27 Oct 2026 15:04:01 +0100
Subject: [PATCH net v2 1/2] netlink: check sk_rcvbuf before charging the
 dump skb
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-netlink-dump-livelock-v2-1-c4bb05352a33@gmail.com>
References: <20261027-netlink-dump-livelock-v2-0-c4bb05352a33@gmail.com>
In-Reply-To: <20261027-netlink-dump-livelock-v2-0-c4bb05352a33@gmail.com>
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Kuniyuki Iwashima <kuniyu@google.com>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Jhonata Poma-Hansen <jhonata.poma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2509;
 i=jhonata.poma@gmail.com; h=from:subject:message-id;
 bh=dxWm9SYpOxRZ7FCUM9z5c49PD2TEyVD2AQsd/JcdWfE=;
 b=owGbwMvMwCX21S6Y7aK9oS7jabUkhqwH64NYJ2yQ3ry27o2cgkP4okyx2vztxtmxd59p1dU0Z
 vMvbQ/sKGVhEONikBVTZPE5+7iHW/Hjjv8Pd1yGmcPKBDKEgYtTACaiXM7I8PPHlgPt13WfL+i4
 vz78x/3Ch64Z0eyPczjnzJab/vjjpqWMDP0RC0TP6ey5lFrdwlfE/GrOFC3u2694HWzs7F49/DL
 xAQMA
X-Developer-Key: i=jhonata.poma@gmail.com; a=openpgp;
 fpr=4CCDE38C0B21F1B8FFE1B8D3F53E5306D13F312D
X-Endpoint-Received: by B4 Relay for jhonata.poma@gmail.com/default with auth_id=1288
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit ae8f160e7eb2 ("netlink: Fix wraparounds of
sk->sk_rmem_alloc."), netlink_dump() charges the dump skb first and
queues it only if sk_rmem_alloc is still below sk_rcvbuf. Commit
a215b5723922 ("netlink: make sure we allow at least one dump skb")
added an exception for an empty socket.

A dump that starts while something else is still charged to a socket
with a small receive buffer fails with ENOBUFS and stays running.
Every recvmsg() retries it, fails again and sets sk_err, so a reader
that peeks before reading, as libnl does, gets ENOBUFS on the read
after each peek, never consumes the message at the head of the queue
and spins forever.

I hit this with "iw dev wlan0 scan" hanging at 100% CPU on an arm64
board with a 6.6 based kernel (iw 5.19 sets SO_RCVBUF to 8KiB). A
kprobe trace showed the scan dump starting while the NEW_SCAN_RESULTS
notification iw had just read was still charged to its socket,
because iw had preempted the sender before netlink_broadcast()
returned.

Check the limit before charging, as before ae8f160e7eb2, which also
covers the empty socket. netlink_recvmsg() continues a dump only at
or below half of sk_rcvbuf, so the skb is then always queued, and a
dump goes over the limit by at most one skb. Refuse a skb that would
take sk_rmem_alloc past INT_MAX, so the wraparound stays fixed.

Reproduced on net in a KVM guest with a userspace reproducer and the
selftest in the next patch; both pass with this fix.

Fixes: ae8f160e7eb2 ("netlink: Fix wraparounds of sk->sk_rmem_alloc.")
Signed-off-by: Jhonata Poma-Hansen <jhonata.poma@gmail.com>
---
 net/netlink/af_netlink.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/net/netlink/af_netlink.c b/net/netlink/af_netlink.c
index a904dc3bc..4129e93a9 100644
--- a/net/netlink/af_netlink.c
+++ b/net/netlink/af_netlink.c
@@ -2318,9 +2318,13 @@ static int netlink_dump(struct sock *sk, bool lock_taken)
 	if (!skb)
 		goto errout_skb;
 
+	/* Check the limit before charging the skb: netlink_recvmsg() continues
+	 * the dump at or below half of sk_rcvbuf, and the skb must be queued
+	 * then. Keep sk_rmem_alloc at or below INT_MAX.
+	 */
 	rcvbuf = READ_ONCE(sk->sk_rcvbuf);
 	rmem = atomic_add_return(skb->truesize, &sk->sk_rmem_alloc);
-	if (rmem != skb->truesize && rmem >= rcvbuf) {
+	if (rmem - skb->truesize >= rcvbuf || rmem > INT_MAX) {
 		atomic_sub(skb->truesize, &sk->sk_rmem_alloc);
 		goto errout_skb;
 	}

-- 
2.54.0

