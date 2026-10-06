From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/6] nfsd: layout recall and lease break fixes
Date: Tue, 06 Oct 2026 13:29:42 +0900
Message-Id: <20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADZ5xGoC/x3MQQqAIBBA0avErBvQBJOuEi0spxoQDa0oorsnL
 d/i/wcyJaYMXfVAopMzx1Ag6wqm1YaFkF0xNKLRUgiNYc4Ovb3jsWOiyXqPozXaOKVUKwlKuCW
 a+fqn/fC+H0/RoZhkAAAA
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791260982; l=10430;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=P8rZ76r08DrwN5cIYUFVHziIfXgj/4Po31ImtTZlG8I=;
 b=WADKSuq4poz5mIo1vZs7v+S1e6Od+CAf4xyiG0pzKvzE5vDnY1oOXkR4+oKyEYoX7PUOGH8xj
 Uwn3f09SJ4IAJqeLTDgIVgNIhwL3q3GtO8znJWL3Gw4EUyowAdQWhjr
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd polls a client that has accepted a CB_LAYOUTRECALL by sending the
callback again every 10 ms, with the stateid of the first callback.  A
Linux client from v6.8 on answers the repeat with NFS4ERR_OLD_STATEID,
and nfsd takes that as a failed recall.  So a client that needs more
than 10 ms to return a layout has the layout revoked and the fence path
run.  With the block layout that client loses data it has written and
synced, with the SCSI layout it is cut off from the device.

Patch 3 lets nfsd keep polling instead.  It needs the two patches
before it.  Patch 1: the limit of two lease periods on that poll has
never triggered, and without it the poll would have no end.  Patch 2:
for the block layout a lease break gives up after fs.lease-break-time
(45 s) without running /sbin/nfsd-recall-failed.  Until now the recall
had failed long before that; with patch 3 it is polled for two lease
periods (180 s).  Patches 1 to 3 have to go together, also to stable
kernels.  Kernels before v7.1 do not have the lease break timeout that
patch 2 fixes; there the operation on the server waits for the recall,
for up to two lease periods, and that operation can be an nfsd thread
serving a WRITE of another client.  Whether that is wanted in older
stable kernels is for you to say; it is how they already treat a client
that keeps answering NFS4ERR_DELAY, then without any limit.

Patch 2 fences the client at fs.lease-break-time, as the SCSI layout
does since v7.1.  By default that is shorter than the one lease period
RFC 8881 section 12.5.5 has the server wait after a recall.

Patch 4 fixes a lease break that hits a LAYOUTGET in progress and then
waits for a layout that is never recalled.  It showed up as writes on
the server that hung for seconds in the tests for the other patches.

Patches 5 and 6 deal with two answers that the polls handle badly.  A
client that a LAYOUTRETURN has moved past the seqid of the recall
answers every poll NFS4ERR_OLD_STATEID and is never asked for the
layouts it still holds; patch 5 polls such a client, one that has not
answered NFS4_OK, with a new seqid.  A client that answers
NFS4ERR_BAD_STATEID after returning its last layout is fenced; patch 6
looks for layouts first.  Neither showed up in the runs below.  Patch 5
builds on patches 3 and 4 and should go to stable kernels with them;
patch 6 stands on its own.

Tests.  QEMU guests on one host: an nvmet-tcp target, the server (nfsd,
XFS on the nvmet namespace, pnfs export, 8 nfsd threads) and three
clients, all on nfsd-testing 32eb1a60b456 with KASAN and lockdep, NFS
v4.2, block layout, except in 5.  The clients do O_DIRECT I/O in 1 MiB
requests on one file for 30 seconds.  Each case was run once.  "before"
is that commit, "after" is that commit with patches 1 to 4.  With all
six, the block layout runs give the same results: no recall failed,
and no block read back as zeroes.

1. Recalls that ended in the failure path, out of the recalls sent, on
   a file that was written beforehand:

                                                    before      after
   2 clients read (different halves of the file)    7 / 9       0 / 9
   2 clients write                                  8 / 9       0 / 9
   3 clients write                                  19 / 20     0 / 47
   2 clients write, the server writes 4 KiB to
   the file every 50 ms                             216 / 229   0 / 275

   Over all cases of a run the server logged "failed to respond to
   layout recall" 362 times before and not at all after.

2. Blocks that read back as zeroes on the server, out of the 1 MiB
   blocks the clients wrote to a new file with O_DIRECT, followed by
   one successful fsync():

                                                    before      after
   2 clients write                                  6 / 564     0 / 475
   3 clients write                                  11 / 527    0 / 552
   1 client writes, the server sets the file size
   every second                                     21 / 469    0 / 481
   2 clients write, file preallocated               8 / 601     0 / 575
   1 client writes, 1 client reads                  4 / 493     0 / 37

   (In the last case the reader holds the layout after the patches and
   the writer makes little progress; see the end of this letter.  The
   commit message of patch 3 has the numbers with patches 1 and 3
   only.)

3. One client writing through a block layout whose path to the device
   is cut while it can still talk to the server, and a 4 KiB write to
   the file on the server.  The client's write that is in flight stays
   stuck until the path is back.

                                                    before      after
   path cut for 15 s: the server write takes        0.05 s      15.5 s
     the recall                                     fails       completes
     /sbin/nfsd-recall-failed is run                at once     no
   path cut for 70 s: the server write takes        0.05 s      47.7 s
     /sbin/nfsd-recall-failed is run                at once     at 47.7 s

   Before, the write of the client reaches the device after the write
   on the server has returned, 15 and 70 seconds later.  After, the
   server waits for the client, and when the lease break times out it
   runs the script first (patch 2; with patches 1 and 3 only, the write
   on the server went on after 47.0 s without the script).  With a lease
   time of 15 seconds and the path cut for 70 seconds, the recall fails
   30 seconds after the first answer of the client and the script is
   run (patch 1).

4. A lease break during a LAYOUTGET (patch 4).  Two clients writing
   while the server writes 4 KiB to the file every 50 ms.  One write on
   the server took 9.7 seconds before and 13.9 seconds with patches 1
   to 3, in both runs until the clients were done.  With patch 4 the
   longest write took 56 ms.  With a delay of 100 ms added to LAYOUTGET
   for this test, between the lookup of the layout stateid and the
   insertion of the layout: the second write on the server took 30
   seconds, the whole run, without patch 4, and the longest write took
   108 ms with it.

5. SCSI layout.  The target runs a kernel with "nvmet: fix preempt of
   another registrant by the reservation holder" [1], so that the
   preempt removes the registration.

                                                    before      after
   2 clients write: recalls that fenced the client  2 / 2       0 / 9
   registrants on the namespace afterwards (of 4)   2           4
   2 clients write a new file (fresh boot): blocks
   that read back as zeroes                         1 / 630     0 / 540
   path of a client cut for 15 seconds: the client
   is fenced                                        yes         no

   The fenced clients logged reservation conflicts and did the rest of
   the run through the server.

pynfs BLOCK1, BLOCK2 and BLOCK4 pass before and after (BLOCK3 fails in
both with a TypeError in the test).  The commit messages of patches 5
and 6 have pynfs clients that answer as described there.  No KASAN or
lockdep report on the server, the clients or the target in any run.

Rebased onto nfsd-testing 56589cdb5881 for posting; the numbers above
are from 32eb1a60b456.  The one conflict was with "nfsd: drain pNFS
fence work during state teardown", in
nfsd4_layout_lm_breaker_timedout(): patch 2 now drops only the early
return for a layout type without ->fence_client, and the fenced and
stopped checks under ls_lock stay.  On 56589cdb5881 with these patches
and the two series that go on top of them, case 3 with the path cut for
70 s gives 48.7 s and the script run at that point (0.05 s and at once
without the patches), and the SCSI case with the path cut for 15 s gives
14.9 s with no fencing.  With the SCSI path cut for 70 s, the write on
the server waits 48.3 s and the fence worker fences the client
(registrants 2 to 1).  pynfs gives the same as above.  No KASAN or
lockdep report.

Not changed by these patches:

- nfsd still polls a client that has answered NFS4_OK with the seqid it
  has used, where RFC 8881 section 12.5.3 has the server increment the
  seqid in each request.  Patch 3 only makes nfsd bear the answer
  (patch 5 gives a new seqid only to a client that has not answered
  NFS4_OK), and while it polls, nfsd sends a callback every 10 ms for
  up to two lease periods.  Ending the callback on NFS4_OK and letting the
  LAYOUTRETURN finish the recall would be the cleaner fix; I can look
  at that next.

- CB_LAYOUTRECALL carries no referring call, as CB_RECALL does since
  "NFSD: Send referring calls with CB_RECALL".  When a recall overtakes
  the reply to the LAYOUTGET that created the layout stateid, the Linux
  client answers NFS4ERR_NOMATCHING_LAYOUT, nfsd drops the layout and
  the client uses it afterwards.  With these patches a client that
  writes through a layout still loses a few blocks that way when
  another client writes to the file through the MDS (2 to 3 of about
  165 in 30 seconds, where it lost 35 to 217 before).  I am sending a
  series for that separately, on top of this one.

- Which client makes progress when several clients use one file.  With
  these patches the client that holds the layout still wins, and with
  every recall done properly it wins more thoroughly than before.

[1] https://lore.kernel.org/r/20261002065931epcms2p1cb2c16f98cf3b05f8c859ad92b0ad465@epcms2p1

---
Daejun Park (6):
      nfsd: make the time limit of a layout recall work
      nfsd: run the fence script when a block layout lease break times out
      nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID
      nfsd: fail a LAYOUTGET in progress when the layout lease is broken
      nfsd: poll a layout recall with a new seqid when the client is past it
      nfsd: do not fence a client for a layout recall with no layouts left

 fs/nfsd/nfs4layouts.c | 122 ++++++++++++++++++++++++++++++++++++++++++++------
 fs/nfsd/state.h       |   3 ++
 fs/nfsd/trace.h       |   2 +
 3 files changed, 113 insertions(+), 14 deletions(-)
---
base-commit: 56589cdb58819ce54decedbbfddf231d94b5ce41
change-id: 20261006-nfsd-layout-recall-ba868d33371e

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

