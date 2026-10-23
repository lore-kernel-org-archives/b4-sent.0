From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH RFC net-next v2 0/2] net/iucv: serialize the HiperSockets
 receive path with the socket lock
Date: Thu, 22 Oct 2026 22:00:37 -0500
Message-Id: <20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WOy2rDMBBFf8XMuhOshyXZlBIo9AOyDVlI1qRVw
 bIjKSEQ8u+R0+y6vJc5584NMqVAGYbmBokuIYc51sDfGhh/bPwmDL5m4C1XrOUcnUQf8oLMc+W
 MtqilHnsvHes7ARVbEh3D9ancw+7rc+0iFYx0LXD4O8hn90tjWcUvJNHpXMfLi5soZ/scH5r3f
 9tOdLZnncALwxa9lkp2Rqv6wXZJc5njZqKPVexsJhznaQplaIw/tkoYJowXcLjfHx5N1Hv8AAA
 A
X-Change-ID: 20261022-b4-disp-1d26b87a-747c9d4b1953
To: Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Thorsten Winkler <twinkler@linux.ibm.com>, Jakub Kicinski <kuba@kernel.org>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org, 
 linux-s390@vger.kernel.org, Hidayath Khan <hidayath@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792724438; l=5919;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=vRkzW2Uh/LRg3YuCuQWUZzq4vkYLc12PyTPaLfXFeds=;
 b=QmLHtjr+tAwN34cUn92rzFpPW+/AcYgBNd637P0oWRJrzTn8HPOe/1SXmlM/HCiacKt5KfFfj
 I8LE6n16O/mB9IspPeiaW6CZqZtRzeBd87D3TOpft4v6lDyEKJ5mR6Z
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v2 of stage 1 of the socket-locking rework [1], answering the reviews of
v1 [2]: Jakub's three points [3] (no forward declarations, a trimmed
commit message, and the AI review's items answered, here in the
changelog), the list's AI review [4] and Hidayath's test rounds on z/VM
[5], including his KCSAN report [6].

Changes in v2:

- a SYN|ACK, SYN|FIN or FIN that arrives while a task owns the socket is
  recorded in the socket, as bits (one SYN reply, the first to arrive,
  and a FIN), and applied in that order by the owner from release_cb(),
  not queued: v1's backlog path dropped a pfmemalloc skb, which qeth
  hands us under memory pressure, and nothing resends a control frame,
  so one queued there could be lost for good. The backlog still takes
  data frames in three cases: while the reply to our SYN is pending,
  behind frames already waiting, and a listener's SYNs, trimmed to their
  header. v1 charged deferred control frames to a budget; a stray
  control frame, a repeated SYN from a conforming peer or junk, can no
  longer push a FIN out of it (AI review)
- the data budget, the msg_recv check in recvmsg() and the window-update
  threshold read the window advertised in the SYN, kept in a new
  msglimit_adv, not the live SO_MSGLIMIT: lowering it in IUCV_BOUND no
  longer loses data (AI review, Hidayath's reproducer)
- a SYN|ACK or SYN|FIN that no socket state accepts is freed in
  afiucv_hs_rcv(), and a SYN to a socket that does not listen is refused
  there; a deferred SYN is refused when applied if the listener closed
  or its accept queue filled meanwhile
- iucv_sock_shutdown() sets sk_shutdown and purges under sk_lock.slock on
  HiperSockets: the data frame that bypasses the backlog tests
  RCV_SHUTDOWN under that lock (Hidayath, KCSAN)
- a reader parked when the peer closed gets EOF, not -ENOTCONN, and
  poll() reports EPOLLRDHUP: 1/2's wait loop returns EOF on IUCV_DISCONN
  with nothing left, which also covers the z/VM sever; 2/2, new in v2,
  sets RCV_SHUTDOWN at the FIN (Hidayath, AI review)
- no forward declaration for afiucv_hs_dispatch(); two remain, for the
  backlog and release_cb handlers referenced from the proto and
  iucv_sock_alloc(). They sit in the file's existing block of them,
  which aa5ec571b93f added to in September; if the IUCV maintainers
  would rather see the handlers moved below their users, that is fine
  by me (Jakub)
- the SHT accounting and the hs_dev ordering went to net as fixes of
  their own [7]; commit message trimmed (Jakub)

Applies on top of [7].

Tested like v1, on s390x under QEMU TCG, net-next 8df0638138d3, KASAN +
PROVE_LOCKING + DEBUG_ATOMIC_SLEEP, this time against an emulated
HiperSockets adapter under the real qeth and qdio drivers, tx completion
included, and an emulated CP for the z/VM transport. Of the 53 default
tests bare net-next fails 8 (7 with [7] applied; its 2/2 fixes one), v1
fails one (the parked reader) and this series fails none, with no KASAN
or lockdep report. Of 10 kernels each missing
one piece of it, 9 fail a test this series passes; the shutdown
spinlock's piece shows only under a probe that widens the window with
udelay(), and the one without the filter that frees stray control
frames in afiucv_hs_rcv() passes every test, told apart only by the
probe's frame count. The opt-in sets (window, strays, shutdown under
the probe, z/VM, MTTCG at HZ=100) and the details are below the --- of
1/2.

QEMU is patched too. Hidayath's table, compared with the code, showed
that TCG's s390x CPU emulation lacked things this needs; besides the
adapter, the QEMU here carries my patches for that, a large set too
specific to this setup to go to QEMU as it is. Where this setup and
Hidayath's z/VM runs disagree, the hardware is the reference.

Still open, as in v1: afiucv_hs_callback_txnotify() and the z/VM
callbacks change sk_state without checking whether a task owns the
socket, and so does afiucv_netdev_event(), whose fix Nagamani is holding
for this series [8]. backlog_skb_q stays unbounded for a peer that
ignores its window, on net-next as here; release_cb() exists now, and
Hidayath's proposal to reset the socket on an overrun from it goes on
top. The child socket leaked on afiucv_hs_callback_syn()'s refusal paths
is pre-existing; Hidayath flagged it in August [9] and his fix for it is
pending.

[1] https://lore.kernel.org/all/20260724222917.134769-1-hexlabsecurity@proton.me/
[2] https://lore.kernel.org/netdev/20261011-b4-disp-410518f4-v1-1-753bf3258292@proton.me/
[3] https://lore.kernel.org/netdev/20261019183223.49a59d6f@kernel.org/
[4] https://lore.kernel.org/netdev/179183431327.434549.446348148837850426@kernel.org/
[5] https://lore.kernel.org/netdev/51a4a40a-f34b-4d41-b049-69aa53f4dcf5@linux.ibm.com/
[6] https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/
[7] https://lore.kernel.org/netdev/20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me/
[8] https://lore.kernel.org/netdev/1d9d3cc1-24fb-40e0-a4c7-6fbfbcf4dc37@linux.ibm.com/
[9] https://lore.kernel.org/netdev/5f88daf4-cd8e-4464-b132-ac45be205121@linux.ibm.com/

---
Bryam Vargas (2):
      net/iucv: serialize HiperSockets receive with the socket lock
      net/iucv: return EOF to a reader parked at the HiperSockets peer's FIN

 include/net/iucv/af_iucv.h |   5 +
 net/iucv/af_iucv.c         | 564 +++++++++++++++++++++++++++++++++++----------
 2 files changed, 444 insertions(+), 125 deletions(-)
---
base-commit: 8df0638138d3e0344fd1fb36cf2d1ca1cf5028f0
change-id: 20261022-b4-disp-1d26b87a-747c9d4b1953
prerequisite-message-id: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
prerequisite-patch-id: 5ef9b0bd1d5842e07b00218ef6ab3f8dd53431fe
prerequisite-patch-id: ff94c57f1b7a45e7bf1d178b252018fac71c6190

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

