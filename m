From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v5 0/2] net/smc: order the CDC receive path against
 buffer publication
Date: Thu, 15 Oct 2026 06:53:30 -0500
Message-Id: <20261015-b4-disp-2a8d85ef-v5-0-6b795e8263c9@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMzQrCMBAGX6V8ZxeS0GjwVcRDfra6HmLJtiKUv
 rtRjzMws0G5CSvOw4bGL1F51g7+MCDfY70xSekMZ9zRGuspjVREZ3IxlOB5IncaQ8rRGrYRPZs
 bT/L+LS+ovOD6l7qmB+flO8O+fwBr0whpeQAAAA==
X-Change-ID: 20261015-b4-disp-2a8d85ef-2748bca10e1a
To: Jakub Kicinski <kuba@kernel.org>, Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Simon Horman <horms@kernel.org>, Wenjia Zhang <wenjia@linux.ibm.com>, 
 Ursula Braun <ubraun@linux.ibm.com>, Hans Wippel <hwippel@linux.ibm.com>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Tony Lu <tonylu@linux.alibaba.com>, linux-rdma@vger.kernel.org, 
 Wen Gu <guwen@linux.alibaba.com>, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792065211; l=4756;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=ojTtm/s6ghvhqfVqGZpxsFVWWkyo0teHaxlRnB4svMw=;
 b=5mPEIctDtJFLhlsm2cF1XuIpR/sLLdEmcojEZU0dDPbUQqwr2UFZxsJHTSX556dvjNZJdckwi
 Li9k8jCumzKC5H8zD6DZk5i9vYJiZMocutX8FR5bur77tSwAyMPS1ea
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A CDC can reach a connection before its RMB, or its SMC-D nocopy send
buffer, is set, and smc_cdc_msg_recv_action() then derefs a NULL
pointer in softirq. For the SMC-R RMB (1/2) the CDC comes from a peer
in the link group that predicts the next token. For the nocopy sndbuf
(2/2, SMC-D loopback only) it comes from the old peer of a reused DMB.
Each patch sets its pointer last with a release store, and the rx path
drops the CDC (1/2) or skips the nocopy accounting (2/2) while the
pointer is unset.

1/2 goes back to 69cb7dc0218b (v4.18), 2/2 to cc0ab806fc52 (v6.10).
2/2 relies on b395dd319cea ("net/smc: do not dereference an unset send
buffer on the SMC-D teardown path"), already in 6.12.y, 6.18.y and
7.2.y.

The old peer can also close the new connection or, once the sndbuf is
attached, push the new connection's sndbuf_space past the sndbuf size,
with or without this series; 3/4 of my v7 series [1] bounds the send()
copy, not sndbuf_space. FWIW smc_conn_free() releasing the RMB before
the connection leaves the token tree [2] is pre-existing too.

1/2 conflicts in __smc_buf_create() with v7 2/4: keep v7's rmb_len
assignment at the top of the is_rmb block, before the release store,
and the tree is the same in either merge order.

v7 1/4 adds an rmb_desc->len load in smcr_cdc_msg_to_host() that any CDC
in 1/2's window reaches (by inspection), as Sashiko flagged [3]. In C,
net already loads rmb_desc->len later in smc_cdc_msg_recv_action(), as I
told Paolo [4], but in my x86 and s390x builds that load only runs when
the cursor wraps differ. 1/2 drops the CDC before both loads.

Tested with KASAN on x86 (v7.3-rc6, whose net/smc differs from net only
by 64a6b36b0e18) and on s390x under QEMU (net). Unpatched, two cases
with the cursor wraps apart reach their NULL loads: a CDC forged with
the next token (1/2, over rxe), and the old peer's consumer update to
a reused DMB (2/2). In the second, nothing is forged, but the old peer
times its read off a test-only counter and the new connect() is starved
of CPU. KASAN reports a null-ptr-deref on x86; on s390x, with the
default lowcore, each load reads page 0 and nothing faults. With the
series, and test-only delays holding the windows open, test-only probes
see the CDC dropped and the update skip the accounting with the cursor
wraps apart. With either NULL check removed they see the NULL load
again, and with either store moved back they see a CDC handled before
the fields that go with the pointer are set. On top of the v7 series and
two other net fixes [5] [6], the patched runs read the same. The
ordering was also checked against LKMM. Test patch and logs on request.

v5:
 - Split in two, one patch per Fixes: tag, and rebased on net, which
   now has the SMC-D teardown fixes 36cdf5d48ca1 and b395dd319cea.
 - Dropped the sndbuf_desc check on the consumer trigger, unneeded
   after b395dd319cea, and the tasklet's rmb_desc acquire, as
   smcd->lock orders that load (by inspection). The sndbuf_desc
   acquire moved into the nocopy branch.
 - Kept per-buffer checks: one readiness flag would drop a conforming
   client's first CDC on SMC-D, and registering the connection later
   would reorder the connect and listen paths.
 - The Closes: tag now points at Sashiko's report [3], not at a review
   of v2. Dropped the R-b tags from Dust Li and Sidraya Jayagond, since
   the patch changed.
v4: https://lore.kernel.org/all/20260728-b4-disp-52ee4e7d-v4-1-0dda94b0f397@proton.me/
v3: https://lore.kernel.org/all/20260716-b4-disp-aa52955a-v3-1-03a4411a7549@proton.me/
v2: https://lore.kernel.org/all/20260714-b4-disp-835288a6-v2-1-581555ef2145@proton.me/
v1: https://lore.kernel.org/all/20260711-b4-disp-c36a9798-v1-1-340b0c6053fb@proton.me/

[1] https://lore.kernel.org/all/20261013-b4-disp-f345196c-v7-0-ef3dddfbfa68@proton.me/
[2] https://lore.kernel.org/all/20260729165306.BE7C21F000E9@smtp.kernel.org/
[3] https://lore.kernel.org/all/sashiko-outbox-164917@kernel.org/
[4] https://lore.kernel.org/all/20260728172552.69349-1-hexlabsecurity@proton.me/
[5] https://lore.kernel.org/all/20261013-b4-disp-872a3689-v1-1-2a4c63b04761@proton.me/
[6] https://lore.kernel.org/all/20261013-b4-disp-193a2a59-v1-1-ed88ac10a41c@proton.me/

---
Bryam Vargas (2):
      net/smc: order the CDC receive path against RMB publication
      net/smc: skip the DMB nocopy accounting until the send buffer is set

 net/smc/smc_cdc.c  | 16 ++++++++++++++--
 net/smc/smc_core.c | 10 ++++++----
 2 files changed, 20 insertions(+), 6 deletions(-)
---
base-commit: 513444cc62e231a11c9b15ea88de0890da9b2b4f
change-id: 20261015-b4-disp-2a8d85ef-2748bca10e1a

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

