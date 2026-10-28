From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Subject: [PATCH net v3 0/2] vsock/bpf: fix waiting and flag handling in
 recvmsg
Date: Wed, 28 Oct 2026 18:55:39 +0100
Message-Id: <20261028-kbh3-1-022-fix-v2-v3-0-bc0752b2d3db@eldare.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NSw6CMBCGr0Jm7ZhOQRRW3sOwKGWQqimmrY2Gc
 HdL3bv8/ucCnp1hD22xgONovJltgnJXgJ6UvTKaITFIIWsSgvDeTyUSCilxNG+MErkcqZKNqCt
 SkHpPx8nJmxewHKD7if7V31iHbW2LTcaH2X3yc6Qc/nMSKbEeFTeHk6LmWJ/5MSjH+4GhW9f1C
 8dh32bJAAAA
X-Change-ID: 20261001-kbh3-1-022-fix-v2-e3f14290641a
To: Stefano Garzarella <sgarzare@redhat.com>, 
 Bobby Eshleman <bobbyeshleman@meta.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, "Michael S. Tsirkin" <mst@redhat.com>
Cc: Michal Luczaj <mhal@rbox.co>, virtualization@lists.linux.dev, 
 netdev@vger.kernel.org, linux-kernel@vger.kernel.org, bpf@vger.kernel.org, 
 stable@vger.kernel.org, Jerome Mohm <jrmmhm.kernel@eldare.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793210158; l=3124;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=5BjgUPTK+Q5h2bvpD5C1SETglAWcW6+J75MQCpy5pss=;
 b=hIkUf7xsHfJhu8is5rphbJIa8ojwE74njpamLIww2+KFea5blbCiVJ7YFgrtSD8m2+PX1ycYc
 Nb2geFyhP/SDVckrvVsn8DykNasVOYCwvTL8t3zP8dQ5S391WhRH2JC
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() holds lock_sock() while it sleeps for data, so the
transport's delivery worker, which needs that lock to queue the data,
deadlocks with the reader. Patch 1 releases the lock around the wait and
makes the wait loop with the exit conditions of the native path,
including a state check that ends the wait on a reset connection after
getsockopt(SO_ERROR) has cleared sk_err. Patch 2 handles the reads that
should never reach the sockmap wait: len == 0, MSG_ERRQUEUE and MSG_OOB.

v2 was one patch; as Michal noted, it mixed the deadlock fix with
fixes for pre-existing issues, so v3 splits it. Patch 1 alone fixes the
deadlock, the dataless wakeup, the peer shutdown and the reset cases;
the zero-length, MSG_ERRQUEUE and MSG_OOB reads keep their current
behaviour until patch 2.

Not addressed here: the netdev Sashiko review of v2 also noted a
pre-existing case where data that sits only in psock->ingress_skb makes
recvmsg() fall back to the native path, which never looks at the psock
queues. It is independent of this series and I will send a separate
patch for it. Annotating the lockless accesses with
READ_ONCE()/WRITE_ONCE() is likewise left for a separate patch that also
covers the native vsock_connectible_wait_data().

The deadlock and the MSG_ERRQUEUE case were found with the help of
Anthropic's Claude; the other cases come from the netdev Sashiko review.
The reproducers are available on request.

Changes in v3:
- Split into two patches (Michal): 1/2 releases the lock and loops in
  the wait, 2/2 handles len == 0, MSG_ERRQUEUE and MSG_OOB.
- 1/2: also end the wait once the socket is no longer TCP_ESTABLISHED
  (0 with SOCK_DONE, else -ENOTCONN, as __vsock_connectible_recvmsg()
  does), so a reset connection whose error was read with SO_ERROR no
  longer waits out the timeout (Sashiko review of v2).
- 2/2: reject MSG_OOB with -EOPNOTSUPP before the len == 0 check, as
  unix_bpf does; this also stops MSG_OOB from consuming ordinary bytes
  (Sashiko review of v2).
- Stefano's Acked-by on v1 is not carried: neither patch matches v1.
- Drop the Assisted-by trailer (removed upstream); tool use is disclosed
  above instead.
- Rebase onto current net.
- Link to v2: https://lore.kernel.org/netdev/20261001-kbh3-1-022-fix-v2-v1-1-cfae958a1976@eldare.de/

Changes in v2:
- Make vsock_msg_wait_data() loop, check sk_err and the peer
  SEND_SHUTDOWN, and add the len == 0 guard (Sashiko review of v1);
  route MSG_ERRQUEUE to the native path ahead of the guard.
- Link to v1: https://lore.kernel.org/netdev/20260929-kbh3-1-022-fix-v1-1-cc97cc95d269@eldare.de/

---
Jerome Mohm (2):
      vsock/bpf: release sock lock while waiting for data in recvmsg
      vsock/bpf: fix zero-length, MSG_OOB and MSG_ERRQUEUE reads in recvmsg

 net/vmw_vsock/vsock_bpf.c | 71 +++++++++++++++++++++++++++++++++++++----------
 1 file changed, 57 insertions(+), 14 deletions(-)
---
base-commit: 363c8c79220d0db4d65dcd570529ddda15067cb5
change-id: 20261001-kbh3-1-022-fix-v2-e3f14290641a

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

