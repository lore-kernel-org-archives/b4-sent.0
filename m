From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v2 0/6] net/smc: fix the failover cursor switch and
 wrap rollover
Date: Sat, 28 Nov 2026 09:23:42 -0500
Message-Id: <20261128-b4-disp-360e65c5-v2-0-d9c05004d430@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCQAwFf6XkbKBNukvxV8SD3T41HtayaUUo/
 XdXPc7AzEaOYnA6NhsVvMztmSvIoaF0v+Qb2KbKJK3ErpOBx54n85k1toghBQaSDr2oBo1Us7n
 gau/f8kQZC53/0tfxgbR8Z7TvH6ntiFN5AAAA
X-Change-ID: 20261128-b4-disp-360e65c5-eec384233536
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Eric Dumazet <edumazet@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>
Cc: Stefan Raspl <raspl@linux.ibm.com>, Simon Horman <horms@kernel.org>, 
 Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 linux-rdma@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Tony Lu <tonylu@linux.alibaba.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Hidayath Khan <hidayath@linux.ibm.com>, 
 Wenjia Zhang <wenjia@linux.ibm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795875822; l=11907;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=hNsS+F6klXASIIdN/mjH0/jpkgd//le+doZX/sNfPPI=;
 b=/+6dxNQCkGQl7G8yuuEo9cQyv3bD/9qFvkxRokIacnvS9/1cG4ADAGPT6ZPcLKe7vdKDkhZJr
 62zT/pEFIbfDY/tfo589FqlnvLFsEqyBGzWklOwpEcUdVcgsJ0iDTuE
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() runs at SMC-R link failover under send_lock only,
while smc_cdc_tx_handler() and the CDC receive handler update the same
cursors under the socket spinlock. Its catch-up orders the peer's
consumer cursor against local_tx_ctrl_fin with smc_curs_comp(), which
misorders two cursors across the u16 wrap rollover. A successful
completion on the old link handled after the switch still credits bytes
that are being resent. The urgent mark has the same rollover problem,
and recv() tests and sets the urgent state under the socket lock only,
while the CDC receive handler sets it under the socket spinlock.

1/6 takes the socket spinlock around the switch. 2/6 tags each CDC pend
with a switch generation and credits a completion only from the current
generation and never backwards; both checks rely on 1/6's lock. 3/6
makes the switch work on copies of the cursors and store each one once.
4/6 computes the catch-up from the signed cursor distance, bounds it by
tx_curs_prep and advances the RMB cursors across wraps. 5/6 uses the
signed distance for the urgent mark. 6/6 takes the socket spinlock
around the reader's two test-and-set sequences on the urgent state.
From 2/6 on each patch needs the ones before it.

Sidraya's review of v1 had three points: the half-updated cursor [2],
the bound of 3/4 [3] and the smc_rx_recv_urg() race [4]. They are 3/6,
the bound in 4/6, and 6/6. v1's 3/4 bounded the catch-up by
tx_curs_sent as it was before the rewind; an earlier failover whose
resend has not run leaves that cursor on tx_curs_fin, and the bound
then cuts a conforming peer's catch-up to nothing. tx_curs_prep is not
rewound. A consumer cursor past tx_curs_prep, which only a forging peer
has, is still clamped and leaves the producer cursor behind it (first
item of "Not fixed here").

Tested in an x86 KVM guest on a v7.4-rc4 KASAN kernel, with net/smc from
the base below built as a module, over soft-RoCE on veth between two
network namespaces. RMB 16 KiB, sndbuf 64 KiB. A failover is
triggered by deleting an rdma device, except in v1's first test (the
switch against a held completion handler) and the held CDC test below,
where a test hook takes the link down. The module had test counters
and test-only knobs, named where they are used. The knob that holds
back the completions of the bytes in flight is also set in the wrap
65535 test, in the forged cursor test and in the resend test of "Not
fixed here". No KASAN report or WARN in any run.

The tests in the v1 cover, except the one with a 16 KiB send buffer,
were run again on this kernel with the same results: each fails on net
and passes with v2. A failover with no knob is clean on net, with 1/6
to 3/6, with 1/6 to 4/6 and with v2. v1's short catch-up test still
fails with 1/6 to 3/6, v1's urgent test with 1/6 to 4/6, and the two
urgent tests of 6/6 below with 1/6 to 5/6. 1/6 and 2/6 are unchanged;
v1's runs without each of them were not repeated. The torn read that
3/6 closes was not run; in the object code, with 3/6 each of the four
cursors the switch updates is written by one 64-bit store, and without
it there are 12 narrower stores into them.

New in v2:

- Two failovers of one connection. A knob holds back the completions of
  the bytes in flight on the first link and a second knob holds the
  resend. After the first failover the peer reads 4000 of those bytes,
  across the end of its RMB, then the second link's device is deleted:
  net catches up 4000 bytes at the second switch and all data arrives.
  v1 catches up nothing, peer_rmbe_space is -12384, an RDMA write is
  refused and the reader gets wrong data from byte 20001 on. v2 catches
  up 4000 and all data arrives. With the 4000 bytes read before the
  first failover and short of the end of the RMB, all data arrives with
  v1 and with v2.
- recv(MSG_OOB) held by a knob between its test of the urgent state and
  its copy of the byte while a second urgent byte arrives: on net and
  with 1/6 to 5/6 it returns the second byte, and the next
  recv(MSG_OOB) returns it again. With 6/6 the softirq waits for the
  spinlock: the first byte, then the second.
- recv() held by a knob in smc_rx_update_consumer() between its test
  and its store of the urgent state while a second urgent byte arrives,
  then a recv() and a recv(MSG_OOB): on net and with 1/6 to 5/6 the new
  mark is overwritten, the recv() skips nothing, recv(MSG_OOB) fails
  with EINVAL and the sender's next send() times out. With 6/6 the
  recv() skips the byte, recv(MSG_OOB) returns it and the data behind
  it arrives. Without the recv() in between, with 6/6 recv(MSG_OOB)
  returns the byte and the sender's next send() still times out: the
  last item of "Not fixed here".
- A CDC that moves the consumer cursor, held by a knob in
  smc_cdc_msg_recv_action() while the link goes down: on net the switch
  runs while the CDC is held and the CDC's credit is added on top.
  peer_rmbe_space is 20384 for the 16384-byte RMB, one RDMA write is
  longer than the RMB and the reader gets wrong data. With 1/6 and
  2/6, and with v2, the switch waits for the CDC: peer_rmbe_space is
  16384 and all data arrives.
- A failover with local_tx_ctrl_fin on wrap 65535 and the peer's
  consumer cursor on wrap 0, 6144 bytes ahead: on net and with 1/6 to
  3/6 the catch-up is skipped, peer_rmbe_space is -10240, send()
  returns EAGAIN and the reader times out. With 1/6 to 4/6 and with v2
  the catch-up runs and all data arrives. With the same failover
  16384 bytes later in the stream, all data arrives on net too.
- A knob raises the consumer cursor in one received CDC before a
  failover: to 1000 bytes past tx_curs_prep, to one wrap ahead, and to
  one wrap ahead with a count of 20000 (the RMB has 16384 bytes). On net
  and with 1/6 to 3/6, tx_curs_sent and tx_curs_fin end past
  tx_curs_prep and sndbuf_space is 66536, 77920 and 89920 for the
  65536-byte sndbuf. With 1/6 to 4/6 and with v2 they stop at
  tx_curs_prep and sndbuf_space is 65536 in all three. What then
  happens to the data is in the first item of "Not fixed here".
- recv(MSG_OOB) with the urgent state still valid and the consumer
  cursor past the mark on the RMB's next wrap. The reader reads up to
  the urgent byte, which is skipped, sets SO_OOBINLINE with the next
  bytes already queued, reads 15883 bytes, clears the option and
  calls recv(MSG_OOB). On net and with 1/6 to 4/6, urg_rx_skip_pend is
  then left set with no byte to skip; with 1/6 to 5/6 and with v2 it
  is not. The byte is returned once and the data behind it arrives in
  all four. With the cursor and the mark on one wrap the flag is not
  set, with 1/6 to 4/6 or with v2.

On a PROVE_LOCKING build of the same kernel there is no lockdep report
with v2 in a failover with no knob, v1's test of the switch against a
held completion handler, the two-failover test and the two urgent tests
of 6/6. With the two locks of 1/6 taken in the other order lockdep
reports the inversion, and without the BH disable in
smc_rx_update_consumer() an inconsistent lock state.

With 6/6 smc_rx_update_consumer() takes the socket spinlock only while
an urgent mark is valid or its skip is pending; a first test without
the lock keeps every other read as it is. A mark that arrives right
after that test is picked up by the next recv(): run with the reader
held there, same result on net and with 6/6. The cost while a mark is
valid was not measured.

The series is on net and does not depend on the CDC cursor bounds
series [1], which is marked changes requested. 1/6, 2/6, 5/6 and 6/6
apply on top of [1] as they are. 3/6 and 4/6 rewrite the block that
[1] 6/6 changes in smc_switch_cursor() and replace it. The bound is the
same, tx_curs_prep. [1] 6/6 also refuses the catch-up for a consumer
cursor whose count is not inside the RMB; that check goes away, the
bound caps the credit without it (the forged cursor test above).

Not fixed here:

- A peer whose consumer cursor is past tx_curs_prep, IOW past every
  byte queued for it. The catch-up stops at tx_curs_prep and leaves the
  producer cursor behind the consumer cursor, so peer_rmbe_space is
  wrong. In the forged cursor test, 1000 bytes past: the next write
  covers bytes the peer has not read and its reader gets wrong data,
  as on net. One wrap ahead: tx stops. It started again when the
  peer's next CDC carried its real cursor, and all data arrived; a
  cursor that goes back is only accepted on wrap 0, and the real one
  was on wrap 0. net delivers wrong data and is 16384 bytes short.
  A count beyond the RMB: the next RDMA write ends past the RMB and is
  refused, and the link group is terminated, as on net. It is the
  forging peer's own link group.
- A conforming peer that keeps reading between the switch and the
  resend. Its consumer cursor passes the rewound producer cursor, as
  on net; if it crosses the end of the RMB the resend's write ends
  past it and is refused, and the link group is terminated ([1] 5/6
  keeps that write inside the RMB). Until the resend, peer_rmbe_space
  is above the RMB size (20384 after a read of 4000), so a sender
  waiting for its urgent byte to be consumed is not released (by
  inspection). The rest, except [1] 5/6, was run with a knob holding
  the resend, on net and with v2: same result. The link group had one
  link left after the failover.
- recv(MSG_OOB) with the urgent byte as the next unread byte returns
  the byte (0 and MSG_TRUNC for a zero length) but does not skip it,
  and the sender's next send() times out. Same on net and with the
  series; 6/6 rewrites that function and keeps this.

Test patch and logs on request.

v2:
 - 3/6: new. smc_switch_cursor() stores each cursor once; a reader
   outside the locks could see tx_curs_sent half updated [5].
 - 4/6 (v1 3/4): the catch-up is bounded by tx_curs_prep, not by the
   pre-failover tx_curs_sent [6].
 - 5/6 (v1 4/4): also orders the two cursors in smc_rx_recv_urg(); the
   distance is kept in an s64.
 - 6/6: new. The urgent state is tested and set under the socket
   spinlock in smc_rx_recv_urg() [7] and in smc_rx_update_consumer().
 - 1/6, 2/6: unchanged.
 - On net e9e45fcb6d39; net/smc has not changed since v1's base.
v1: https://lore.kernel.org/all/20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me/

[1] https://lore.kernel.org/all/20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me/
[2] https://lore.kernel.org/all/83784e4c2e7a0df1e16a791dfe588f36@linux.ibm.com/
[3] https://lore.kernel.org/all/366063ac0493ac4f48df9947b98d6613@linux.ibm.com/
[4] https://lore.kernel.org/all/c769cd79c084c38804b606cbe0b0d79a@linux.ibm.com/
[5] https://lore.kernel.org/all/sashiko-outbox-215218@kernel.org/
[6] https://lore.kernel.org/all/sashiko-outbox-215219@kernel.org/
[7] https://lore.kernel.org/all/sashiko-outbox-215220@kernel.org/

---
Bryam Vargas (6):
      net/smc: take the socket spinlock across the failover cursor switch
      net/smc: do not credit stale CDC completions after a link switch
      net/smc: store each cursor once in smc_switch_cursor()
      net/smc: fix the failover catch-up across the cursor wrap rollover
      net/smc: order the urgent mark across the cursor wrap rollover
      net/smc: update the urgent state under the socket spinlock

 net/smc/smc.h      |   3 ++
 net/smc/smc_cdc.c  |  11 +++++-
 net/smc/smc_cdc.h  |  28 +++++++++-----
 net/smc/smc_core.c |  59 ++++++++++++++++++-----------
 net/smc/smc_rx.c   | 109 ++++++++++++++++++++++++++++++++---------------------
 5 files changed, 135 insertions(+), 75 deletions(-)
---
base-commit: e9e45fcb6d39bee9325e6a7dca72bd14e82760f3
change-id: 20261128-b4-disp-360e65c5-eec384233536

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

