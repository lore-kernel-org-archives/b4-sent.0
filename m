From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net 0/4] net/smc: fix the failover cursor switch and wrap
 rollover
Date: Fri, 13 Nov 2026 23:14:39 -0500
Message-Id: <20261113-b4-disp-1a9ab9b0-v1-0-4a7c8d85d849@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDQAwAvyI5N7DRRbBfKT0ka6zxsJWNLQXx7
 27b4wzM7OBaTB2uzQ5F3+b2zBXo0kCaOT8UbawMbWh7IupQIo7mKxIPLIME5KicepoCSYSarUU
 n+/yWN8i6wf0v/SWLpu07g+M4ATRNTW95AAAA
X-Change-ID: 20261113-b4-disp-1a9ab9b0-a4eac61f01b4
To: Dust Li <dust.li@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, Jakub Kicinski <kuba@kernel.org>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>, 
 Paolo Abeni <pabeni@redhat.com>, Sidraya Jayagond <sidraya@linux.ibm.com>
Cc: Guangguan Wang <guangguan.wang@linux.alibaba.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, netdev@vger.kernel.org, 
 Wenjia Zhang <wenjia@linux.ibm.com>, Ursula Braun <ubraun@linux.ibm.com>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 Wen Gu <guwen@linux.alibaba.com>, Stefan Raspl <raspl@linux.ibm.com>, 
 linux-rdma@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794629679; l=6345;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=8Jc9TX0UDkIgro1gN3WPe+sNivrVaUF/2LnC1LPpDx4=;
 b=T2VHOLJc304xhq0zdHK6gZzAj7Arqe6C2YpIzvHhNphfTTHxx8totosXzOQosAOS3nKctxFOf
 aIZk/P78L26AOuirOnPyUkdee26xuN1fQ4J0kP6fDymbmE9///oX/3g
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smc_switch_cursor() runs at SMC-R link failover under send_lock only,
while smc_cdc_tx_handler() and the rx path update the same cursors under
the socket spinlock. Its catch-up orders the peer's consumer cursor
against local_tx_ctrl_fin with smc_curs_comp(), which misorders two
cursors across the u16 wrap rollover. The v9 cover of the CDC cursor
bounds series [1] lists the race against smc_cdc_tx_handler() and the
rollover as not fixed there; Sashiko's review of v8 [2] reported both.
The same switch has a third problem: a successful completion on the old
link handled after the switch still credits bytes that are being resent.

1/4 takes the socket spinlock around the switch. 2/4 tags each CDC pend
with a switch generation and credits a completion only from the current
generation and never backwards; both checks rely on 1/4's lock. 3/4
computes the catch-up from the signed cursor distance, bounds it by the
bytes sent and advances the RMB cursors across wraps; it uses
smc_curs_sdiff() from 2/4. 4/4 uses the same helper for the urgent mark
in smc_rx_update_consumer(), which has the same rollover problem.

Tested in an x86 KVM guest on a v7.4-rc2 KASAN kernel, with net/smc of
the base below built as a module, over soft-RoCE on a veth pair between
two network namespaces. Unless noted otherwise the RMB is 16 KiB, the
send buffer 64 KiB, and the failover is triggered by deleting an rdma
device. The module had test counters and test-only knobs, named where
they are used below. Three controls pass with and without the series: a
failover with no knob, one after 1 GiB with both cursors on the same
wrap (there the series is 1/4 to 3/4), and an urgent byte on the
reader's wrap. Leaving out 1/4, either of 2/4's two checks, 3/4 or 4/4
makes its test fail. No KASAN splat or WARN in any run. On a
PROVE_LOCKING build of the same kernel, a failover with no knob and the
first test below give no lockdep report with 1/4 to 3/4 (4/4 takes no
lock); with the two locks of 1/4 taken in the other order, lockdep
reports the inversion.

- Send buffer full. A completion handler held by a knob at its credit
  decision while a test hook takes the link down on another CPU, and a
  second knob holding the resend until the application has written: on
  net the switch runs while the handler is held, sndbuf_space ends 4096
  over the buffer size, and the application's new data replaces bytes
  still to be resent; the reader gets wrong data. With 1/4 the switch
  waits for the socket spinlock and the stream is intact.
- Two completions on the old link held back by a knob and handed back
  after the switch, send buffer full, the resend held as above: on net
  they credit 8192 bytes that are still to be resent, and the reader
  gets wrong data. With 2/4 they credit nothing.
- The peer shut down its write side, so the switch moves the link
  without a rewind; an old-link completion held back by a knob is
  handed back after one on the new link: on net tx_curs_fin moves back
  and sndbuf_space ends 4096 over the buffer size. With 2/4 nothing
  moves.
- 1 GiB through the RMB, so that at the failover local_tx_ctrl_fin is
  on wrap 0 and the peer's consumer cursor 12288 bytes behind it on
  wrap 65535: on net the catch-up runs, sndbuf_space goes 20480 over,
  an RDMA write is refused (remote access error) and the reader gets EOF
  65536 bytes short while every send() succeeded. Also on net, with a
  16 KiB send buffer and one 48 KiB send() after the failover, send()
  takes 36864 bytes and copies 12288 of them past the end of the send
  buffer (a test counter; KASAN does not see it, the buffer is
  page-allocated). With 3/4 there is no catch-up, all data arrives,
  and send() takes 16384.
- Old-link completions held back by a knob while the peer reads 24576
  bytes past local_tx_ctrl_fin, then the failover: on net the catch-up
  is 8192, 16384 short, and the connection stalls with no write space.
  With 3/4 it is 24576 and all data arrives.
- 1 GiB through the RMB with the reader stopped on wrap 65535 and an
  urgent byte sent so that it lands on wrap 0, no SO_OOBINLINE: on net
  recv(MSG_OOB) fails with EINVAL, the urgent byte is never consumed,
  and the sender, which waits for that, sends nothing more (its send()
  times out with 32768 bytes unsent). With 4/4 the byte is read OOB and
  the stream is intact.

The series is on net and does not depend on [1]. Patches 1/4, 2/4 and
4/4 apply on top of [1] as they are; 3/4 conflicts with [1] 6/6 in
smc_switch_cursor(), where 3/4's version replaces 6/6's: 3/4 bounds the
catch-up by the bytes sent, which is tighter than 6/6's bound,
tx_curs_prep (by inspection). With [1] alone, [1] 3/6 keeps send()
inside the send buffer, but the misordered catch-up still runs: it
advances the cursors by up to tx_curs_prep - tx_curs_fin bytes without
sending them on the new link and tells the peer they are in its RMB (by
inspection).

Not run, by inspection only: a CDC received during the switch (1/4), a
consumer cursor that is ahead across the rollover (3/4) and one past the
bytes sent, where 3/4's bound applies. Not run with 1/4: a completion
handled between the switch's first two cursor copies, which leaves
tx_curs_sent and the producer cursor out of step; [1] measured that case
without this series.

Test patch and logs on request.

[1] https://lore.kernel.org/all/20261112-b4-disp-0287c16e-v9-0-e5e8fa688177@proton.me/
[2] https://lore.kernel.org/all/179364387382.3131.13471253186660322977@kernel.org/

---
Bryam Vargas (4):
      net/smc: take the socket spinlock across the failover cursor switch
      net/smc: do not credit stale CDC completions after a link switch
      net/smc: fix the failover catch-up across the cursor wrap rollover
      net/smc: order the urgent mark across the cursor wrap rollover

 net/smc/smc.h      |  3 +++
 net/smc/smc_cdc.c  | 11 ++++++++++-
 net/smc/smc_cdc.h  | 28 +++++++++++++++++++---------
 net/smc/smc_core.c | 36 +++++++++++++++++++++++++-----------
 net/smc/smc_rx.c   |  4 ++--
 5 files changed, 59 insertions(+), 23 deletions(-)
---
base-commit: ead6fa9a0ab194f02a2f36d634b193e9c5f9a1c6
change-id: 20261113-b4-disp-1a9ab9b0-a4eac61f01b4

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

