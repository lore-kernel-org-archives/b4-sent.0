From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v6 0/3] net/smc: order the CDC receive path against
 buffer publication
Date: Thu, 12 Nov 2026 19:32:47 -0500
Message-Id: <20261112-b4-disp-1c8d3a53-v6-0-36a38ae35021@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMSwoCMRAFrzK8tQ3mYxCvIi7y6Wi7iEN6FGGYu
 xt1WQVVK5S7sOI0rej8EpVHGxB2E/IttiuTlMGwexuMMZaSpyI6k8nH4uLBUY2u5FSD9zZgZHP
 nKu/f8ozGCy5/qc9057x8Z9i2D2ajWgx5AAAA
X-Change-ID: 20261112-b4-disp-1c8d3a53-fa3dcbf64426
To: Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>
Cc: Hans Wippel <hwippel@linux.ibm.com>, linux-kernel@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-rdma@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org, 
 Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794529967; l=9061;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=7XgC16ZIVTlO1AO6zrIOxz7J0W0kAAwidGvfD80fYV4=;
 b=IwsbfYh+E/t7JfHeKnOthqBbehJUYMc21hhMAqIaF91puK6Hwge3DN6SAT+HhvT+MoJ8wE6Jo
 9EkEuIz5T32DnIcVWh7pZ0Ri714bKS2YKFcYEmuuK9EyOJetOfiJPNV
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A peer can make smc_cdc_msg_recv_action() deref a NULL pointer in
softirq with a CDC that reaches a connection before its RMB, or its
SMC-D nocopy send buffer, is set: an SMC-R peer in the link group
predicts the token (1/3), and the old peer of a reused DMB still
holds its token (3/3). 1/3 and 3/3 are v5's two patches: each sets
its pointer last with a release store, and the rx path drops the CDC
(1/3) or skips the nocopy accounting (3/3) while the pointer is unset.

2/3 is new. Sashiko found [1] that the NULL test of 1/3 misses a
handshake that retries: when the SMC-Rv2 attempt of the listen worker
fails in smc_listen_rdma_reg(), smc_conn_abort() releases the buffers
(to the link group's pool or, after a failed MR registration, to the
allocator) and leaves rmb_desc and sndbuf_desc pointing at them, and
the SMC-Rv1 retry registers the connection under a new token with
those stale pointers. A CDC with that token is then handled on a
buffer the connection no longer owns. The NULL test of 1/3 does not
see it, and the bug is there without 1/3 too. A peer fails the
SMC-Rv2 attempt with a negative CONFIRM_RKEY response. 2/3 clears
both pointers in smc_conn_create() under the socket spinlock, and
tests rmb_desc again under that lock in smc_cdc_msg_recv_action(),
for a handler that found the connection before the clear. 2/3 needs
1/3, and 3/3 has a line of 2/3 as context.

The clear is at registration and not at release: every registration
goes through smc_conn_create(), while smc_conn_free() skips the
release when the link group is already unlinked and would leave the
pointers set there.

Both NULL tests are needed. The one in smc_cdc_rx_handler() (1/3)
also keeps the CDC out of smc_cdc_msg_validate(), which runs before
the socket spinlock is taken; the one in smc_cdc_msg_recv_action()
(2/3) is the one under that lock.

Not fixed here, all pre-existing:
 - A handler that found the connection before smc_conn_free()
   unregistered it still runs on the released RMB (the window of
   Weiming Shi's patch [2]). 2/3 does not close that window: its
   clear comes at the next smc_conn_create(). Such a handler can also
   still reach smc_cdc_msg_validate() on the retried connection, as
   Sashiko noted on Hidayath Khan's patch [3]. 2/3 clears the two
   pointers only; whatever else the failed attempt left in the
   connection stays.
 - The old peer of a reused DMB, rated [Critical] by Sashiko on v5
   2/2 [4]: its CDCs are still applied to the new connection. They
   can close it, leave their consumer cursor in it before the attach
   or, once the sndbuf is attached, add to its sndbuf_space. 3/3
   removes the NULL deref only. 3/6 of my v9 cursor series [5] bounds
   the send() copy to the send buffer; it does not correct
   sndbuf_space.
 - The unbounded producer cursor: 1/6 of [5].

1/3 conflicts in __smc_buf_create() with 2/6 of [5]: keep [5]'s
rmb_len store at the top of the is_rmb block, before the release
store, and the tree is the same in either order.

Tested with KASAN on x86 over rxe: v7.4-rc2 plus the two net/smc commits
net has on top (d7900fa51642, e227b5115828), plus the series. rxe has no
RoCEv1 GID, so the SMC-Rv1 retry is not reachable on it unmodified: a
test-only change lets the SMC-Rv1 lookup take the RoCEv2 GID. The retry
then joins the link group of the failed attempt, which is what lets the
peer's CDC reach it. On a device with both GIDs the retry joins a link
group the peer has a link in when the SMC-Rv1 part of the proposal names
the GID and MAC of a link of that group: of the failed attempt's SMC-Rv2
link (smcr_lgr_match() does not compare the version), or of a link of an
SMC-Rv1 link group of the same peer. By inspection, not run on such a
device.

Test-only knobs fail the SMC-Rv2 attempt in one of two ways (the
client answers CONFIRM_RKEY negatively, or the server's MR
registration fails), fail the retry's RMB allocation, and delay the
retry between its registration and smc_buf_create(); the client
sends a CDC forged with the retried connection's token in that
window.

Without 2/3 the forged CDC gets past the NULL test of 1/3. After the
negative CONFIRM_RKEY, the case a peer forces, the descriptor is
back in the link group's pool: KASAN is silent and test-only
counters show smc_cdc_msg_recv_action() running on it. After the
failed MR registration, which the test forces locally and I have
not shown a peer forcing, KASAN reports a slab-use-after-free read
in smc_cdc_msg_recv_action(). With the retry's RMB allocation failed
as well, and no forged CDC, it reports one in smc_conn_free(),
followed by a GPF in smcr_buf_unuse(). With the series the forged
CDC is dropped, KASAN is silent, and the retried connection
completes and carries data (over TCP when its RMB allocation is
failed).

Three variants of the series, counters only (no KASAN boot of them):
 - the clear removed, the second test kept: as without 2/3;
 - the second test removed: a handler delayed between the lookup and
   the socket spinlock across the retry finds rmb_desc NULL where
   smc_cdc_msg_recv_action() loads it (the access was not run);
 - the test in smc_cdc_rx_handler() removed: a forged CDC with the
   failover_validation flag reaches smc_cdc_msg_validate(), at the
   first registration and at the retry. The series drops it in both.
The clear of sndbuf_desc is covered by a counter at the registration
only: no run fails the retry's send buffer create.

On the client, a counter shows a non-blocking connect() that failed
after smc_buf_create() (a test-only knob shuts the server's CLC
socket down) entering smc_conn_create() again on the second
connect() after the failure, with the old pointers before 2/3 and
NULL after. Nothing else was measured on the client: no CDC was sent
at it.

v5's cases give the same results with the series: a CDC forged with the
next token is dropped at the first registration, and the old peer's
update to a reused DMB (loopback) skips the accounting.

The retry and client cases also ran on s390x under QEMU TCG (rxe, two
vCPUs, KASAN and lockdep), by the counters only (the boots that give the
two KASAN reports were not run there), once with deterministic
scheduling and once with the vCPUs on host threads: the same results as
on x86. With the vCPUs on host threads the delayed handler missed its
window in three of nine boots, none of them of the series; those cells
are not measured. Not run on s390 hardware. v5's cases were not repeated
on s390x: 1/3 and 3/3 are v5's code.

Under lockdep (the x86 tree with PROVE_LOCKING, one boot per case, and
the s390x runs) the series is silent in the retry and client cases and,
on x86, in v5's cases; the tree without it is silent in the retry cases.
With spin_lock() in place of spin_lock_bh() in smc_conn_create(),
lockdep reports an inconsistent lock state on slock-AF_SMC.

Checked with herd7 against LKMM: the handler neither loads NULL after
its test nor sees the new descriptor before its length. Without the lock
or without the second test it can do either; with a plain load in the
second test, the latter. Test patch and logs on request.

v6:
 - New 2/3, for the retry Sashiko found on v5 1/2 [1].
 - 1/3: code as v5 1/2, two comments reworded: the one at the test
   no longer says that rmb_desc is never cleared.
 - 3/3: code as v5 2/2. The message now says that the rest of the
   old peer's update is still applied to the new connection, in
   answer to [4]; v5's said only that the current peer loses none.
 - Rebased on net.
v5: https://lore.kernel.org/all/20261015-b4-disp-2a8d85ef-v5-0-6b795e8263c9@proton.me/
v4: https://lore.kernel.org/all/20260728-b4-disp-52ee4e7d-v4-1-0dda94b0f397@proton.me/
v3: https://lore.kernel.org/all/20260716-b4-disp-aa52955a-v3-1-03a4411a7549@proton.me/
v2: https://lore.kernel.org/all/20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me/
v1: https://lore.kernel.org/all/20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me/

[1] https://lore.kernel.org/all/179241208347.3135.18021879529736748765@kernel.org/
[2] https://lore.kernel.org/all/20261021171256.166870-2-bestswngs@gmail.com/
[3] https://lore.kernel.org/all/20261006073550.1595003-1-hidayath@linux.ibm.com/
[4] https://lore.kernel.org/all/179241208501.3135.14193534440423847161@kernel.org/
[5] https://lore.kernel.org/all/20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me/

---
Bryam Vargas (3):
      net/smc: order the CDC receive path against RMB publication
      net/smc: clear the buffer pointers before registering a connection
      net/smc: skip the DMB nocopy accounting until the send buffer is set

 net/smc/smc_cdc.c  | 20 ++++++++++++++++++--
 net/smc/smc_core.c | 19 +++++++++++++++----
 2 files changed, 33 insertions(+), 6 deletions(-)
---
base-commit: 2a24ba1694f14299fbde3fa107e5d56629f2f8b6
change-id: 20261112-b4-disp-1c8d3a53-fa3dcbf64426

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

