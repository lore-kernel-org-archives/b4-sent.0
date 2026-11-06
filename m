From: Jerome Mohm <jrmmhm.kernel@eldare.de>
Subject: [PATCH net v4 0/2] vsock/bpf: fix waiting and flag handling in
 recvmsg
Date: Fri, 06 Nov 2026 22:57:20 +0100
Message-Id: <20261106-kbh3-1-022-fix-v2-v4-0-c7d36703814d@eldare.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NOw7CMBBErxK5ZpG9zpeKeyAKfzbEgBJkBwsU5
 e44oUmBKN/uzJuJBfKOAjtkE/MUXXBDnyDfZcx0qr8QOJuYIcdScC7gpjsJAjgitO4FEYFkK3J
 seJkLxVLv4Sl9VueJ9TSy8/cYnvpKZlxsS6xzYRz8e12OYg3/GYkisWkVNUWtRFOVR7pb5Wlva
 fVHuTFg/csggYM2vCpQo5VWbw3zPH8AJ4gEqgsBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794002242; l=3156;
 i=jrmmhm.kernel@eldare.de; s=20260928; h=from:subject:message-id;
 bh=3N1HVbW/FKojBN21DNx2VL0tmiNZKFzaJqEUw7vm67M=;
 b=dzk2bNoM+L/XeEtTJDqisAtunD/8hRkFnTCN+GQfp2y4JcrBsy04acBNPoTkUcxKfYxQm442M
 4vz/Xn5ONiVC2M5bVBzXmgcbfqPuYtoIEKpgY5HrdJ2I16tmzZnqwXK
X-Developer-Key: i=jrmmhm.kernel@eldare.de; a=ed25519;
 pk=xRCxNXbnNottaHpmvPDAOC9NuMJxqKo24abkehKRVlo=
X-Endpoint-Received: by B4 Relay for jrmmhm.kernel@eldare.de/20260928 with auth_id=1075
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vsock_bpf_recvmsg() holds lock_sock() while it sleeps for data, so the
transport's delivery worker, which needs that lock to queue the data,
deadlocks with the reader. Patch 1 releases the lock around the wait and
makes the wait loop with the exit conditions of the native path. Patch 2
handles the reads that should never reach the sockmap wait: len == 0,
MSG_ERRQUEUE and MSG_OOB.

Not addressed here, as in v3: data that sits only in psock->ingress_skb,
and READ_ONCE()/WRITE_ONCE() for the lockless accesses; both are left for
separate patches. Not run: the ns_* tests of vmtest.sh (they need root on
the host); the reproducers ran in a guest over virtio-vsock (PCI) and
vsock-loopback only.

The deadlock and the MSG_ERRQUEUE case were found with the help of
Anthropic's Claude; the other cases come from the netdev Sashiko review.
The reproducers are available on request.

Changes in v4:
- 1/2: comment why the wait stops on sk_err and why it checks
  signal_pending() (Stefano).
- 1/2: one data <= 0 check in vsock_bpf_recvmsg() (Stefano).
- 1/2: say why this is one patch and how non-blocking reads change
  (Stefano).
- 2/2: say that MSG_ERRQUEUE consumed stream bytes and why the checks
  come in this order (Stefano).
- Shorter commit messages.
- Rebase onto current net.
- Retested, with a new reproducer for a dataless wakeup during a timed
  wait.
- Link to v3: https://patch.msgid.link/20261028-kbh3-1-022-fix-v2-v3-0-bc0752b2d3db@eldare.de

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

 net/vmw_vsock/vsock_bpf.c | 77 ++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 63 insertions(+), 14 deletions(-)
---
base-commit: 6d2cf411aba2aa0bd641b49be5b1964ac5097a50
change-id: 20261001-kbh3-1-022-fix-v2-e3f14290641a

Best regards,
--  
Jerome Mohm <jrmmhm.kernel@eldare.de>

