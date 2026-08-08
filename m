From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v2 0/2] net/smc: close the SMC-D teardown window around
 the ghost send buffer
Date: Sat, 08 Aug 2026 02:21:22 -0500
Message-Id: <20260808-b4-disp-22f119e6-v2-0-61647601a6f3@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27CbbpRDwK8YDLYuuh0q6aEwIf
 6fCcSaZWcEkqxhcqxWyfNX0nQrwpYL4HNJDUMfCwMQtddRh8Diqzcg8OddLi6Em6ofG+zo6KNm
 cZdLfsbxBkgXup7RPeElc/jPYth2UAqSgeQAAAA==
X-Change-ID: 20260808-b4-disp-22f119e6-b3009a5443c1
To: Dust Li <dust.li@linux.alibaba.com>, 
 Sidraya Jayagond <sidraya@linux.ibm.com>, Paolo Abeni <pabeni@redhat.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Wenjia Zhang <wenjia@linux.ibm.com>, "D. Wythe" <alibuda@linux.alibaba.com>, 
 Mahanta Jambigi <mjambigi@linux.ibm.com>, 
 Tony Lu <tonylu@linux.alibaba.com>, Wen Gu <guwen@linux.alibaba.com>, 
 Eric Dumazet <edumazet@google.com>
Cc: linux-kernel@vger.kernel.org, linux-rdma@vger.kernel.org, 
 netdev@vger.kernel.org, Simon Horman <horms@kernel.org>, 
 linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786173683; l=5306;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=mCPKlTskOIb8w7OnErnb66jmUGG7UFKFuHYmLZdquTs=;
 b=o+MK9M7DpMq/hGc2HYvusJGYjs5f0UESIR+rtrAkDErIXmejbuwCZyDyDerRwZaljhmTwMCkl
 AqkxpfjmgLhDRQ9qwmA+azd5O2JoofOToQ6PGV3aVd+uLc+XurLfOS9
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both patches only matter on the SMC-D DMB-nocopy path, where the ghost send
buffer exists, and the only in-tree provider of support_mmapped_rdmb is
dibs_loopback. CONFIG_DIBS_LO is default n and its help calls it a testing aid,
so on a stock config neither bug is reachable.

v1 moved smcd_buf_detach() after the drain. Dust Li replied that it does not
fully eliminate the race and asked whether RCU is the better shape. He is right
about the first part; I built both and measured them.

An SMC-D loopback KASAN rig, one module binary, teardown form selected at
runtime. "path" counts connections reaching either teardown site with the link
group already unlinked, "armable" how many of those still had both gates in
smcd_handle_irq() open when the drain returned, "re-armed" the device arming
the tasklet again afterwards:

  form                                   path  armable  re-armed
  upstream                                169       73        29
  v1 (drain, then detach)                 172       78        33
  unregister first, then drain             31        0         0
  v1 + RCU                                 24        9         3

Two caveats on that table. The last two arms ran far shorter than the first two,
so compare the armable/re-armed ratios rather than the absolute path counts. And
the third row also forced tasklet_kill() in the !soft path, which 1/2 does not;
that was inert here because smc_lgr_terminate_work() passes soft=true, so the
same call ran either way.

The reorder alone leaves the window open, which is what Dust saw. RCU doesn't
close it either: smcd_buf_detach() both frees the descriptor and clears the
field, and RCU defers only the free, so a re-armed tasklet still runs and still
finds conn->sndbuf_desc NULL. The gate has to be shut before the drain, and
that is 1/2. RCU on the descriptor would still be a reasonable thing to want
for the free itself; it just doesn't substitute for 1/2, so I didn't fold it
in. Your call if you want it anyway.

Caveat on 1/2: the two changes the table covers -- unconditional
smc_ism_unset_conn(), and drain before detach -- were measured together, not
separately. It also clears conn->sndbuf_desc before freeing it, so a reader
that samples the pointer cannot get one that is already freed; that part is
by inspection.

2/2 is a second dereference the same teardown reaches, found while running the
above. smc_close_stream_wait() calls smc_tx_prepared_sends() from inside
sk_wait_event(), which evaluates its condition once with the socket lock
released, and a terminating link group clears conn->sndbuf_desc right there.
SIOCOUTQ reads the same field by hand, and smc_close_cancel_work() drops the
socket lock across two cancel_*_sync() calls, so 2/2 bounds that too. Eight
faults across three boots, the earliest 89 seconds in:

  RIP: smc_close_stream_wait+0x66d [smc]
   smc_close_active -> __smc_release -> smc_release -> __x64_sys_close

The faulting address is NULL plus offsetof(struct smc_buf_desc, len), nothing
there is attacker-chosen, and the value read never reaches userspace, so there
is no memory-safety primitive and no leak oracle -- it is an oops. The task dies
inside close() holding the socket lock, so I would expect the socket to leak with
it, but I didn't isolate that from the rig's own effects and I'm not claiming it.

Reaching either bug needs a link-group teardown while a socket is parked in that
wait. smc_lgr_cleanup_early() off a failed first-contact handshake gets there, as
does smc_clc_wait_msg() on a peer DECLINE with FIRST_CONTACT -- both by
inspection. The rig instead drove smc_lgr_terminate_sched() from a debug module
parameter, so only the initiation is synthetic; the unlink, the deferred worker,
smc_conn_free() and smcd_handle_irq() are the unmodified path. Logs and the rig
on request.

I haven't touched tasklet_unlock_wait() in the !soft path of smc_conn_kill().
It waits out TASKLET_STATE_RUN without clearing TASKLET_STATE_SCHED, but I have
no measurement showing that reachable here, so it stays as it is.

v2:
- 1/2: unregister the connection unconditionally rather than only while the
  link group is still on its device list. That guard, not the ordering, is why
  the tasklet can be re-armed after tasklet_kill().
- 2/2: new.
- v1: https://lore.kernel.org/all/20260726-b4-disp-a135b4e5-v1-1-705aaec79986@proton.me/

Bryam Vargas (2):
  net/smc: unregister the connection before draining the rx tasklet
  net/smc: do not dereference an unset send buffer on the SMC-D teardown path

 net/smc/af_smc.c   |  3 ++-
 net/smc/smc_core.c | 13 +++++++------
 net/smc/smc_tx.h   |  6 +++++-
 3 files changed, 14 insertions(+), 8 deletions(-)

base-commit: 3dbb44d88b1e
---
Bryam Vargas (2):
      net/smc: unregister the connection before draining the rx tasklet
      net/smc: do not dereference an unset send buffer on the SMC-D teardown path

 net/smc/af_smc.c   |  3 ++-
 net/smc/smc_core.c | 13 +++++++------
 net/smc/smc_tx.h   |  6 +++++-
 3 files changed, 14 insertions(+), 8 deletions(-)
---
base-commit: 3dbb44d88b1e94dd31fe43588af7437b34b44d56
change-id: 20260808-b4-disp-22f119e6-b3009a5443c1

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

