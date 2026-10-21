From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH 0/4] nfsd: keep a layout whose recall overtakes the
 LAYOUTGET reply
Date: Wed, 21 Oct 2026 10:03:02 +0900
Message-Id: <20261021-nfsd-layout-refcall-v1-0-797096b92377@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEYP2GoC/x2MQQqAIBAAvxJ7bkFFhPpKdDBda0EstKKI/p50H
 IaZBwplpgJ980CmkwuvqYJsG3CLTTMh+8qghDJSKIkpFI/R3uuxY6bgbIxoxKRD502ntYdablX
 w9V+H8X0/Z0sSOmUAAAA=
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792544582; l=6203;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=XlCKRZQ1Fv9OeSsQKdpQstdH4Advnnpuw/c9IVwOY00=;
 b=b9UWjxDBjAJawimMTjzQWvdWHqUwcQSLcF0zdn1tTGiz2LWdHrbprPCdpdNrH1Ol/zHjvhZl5
 3vCKJI3trb8Bbdfh/OJJprEmFOxrp2T1411qwoC5+pXOgQZRLDSLdnh
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With [3], a client that writes to a file through the metadata server
while it does I/O through a layout of the same file gets
NFS4ERR_RECALLCONFLICT for LAYOUTGET after LAYOUTGET. One Linux block
layout client writing 1 MiB blocks with O_DIRECT through its layout and
512 bytes at the middle of a page, which it sends through the metadata
server, to the same file did 54, 54 and 51 of its 1 MiB writes in 30
seconds in three runs with patches 1 to 3. Patch 4 lets such a LAYOUTGET
succeed with an immediate recall instead when the lease break comes from
the same client (244, 249 and 241). That recall can overtake the
LAYOUTGET reply: a client that does not know the layout stateid yet
answers NFS4ERR_NOMATCHING_LAYOUT, nfsd drops the layout, and the Linux
client loses the writes it then sends through it, which read back as
zeroes although fsync() succeeded. Without patches 2 and 3, patch 4 lost
85 of 600, 87 of 584 and 79 of 600 blocks. The same race exists today
with a client that is slow to process a LAYOUTGET reply. Patch 2 has the
details.

Patch 1 lets layouts share the record of the slot that carried a grant
with the delegation code [1]. Patch 2 resends the recall once, as the
delegation code does, when the client answers NFS4ERR_NOMATCHING_LAYOUT
before the slot of the LAYOUTGET has retired. Patch 3 names the
LAYOUTGET as a referring call (RFC 8881 sections 2.10.6.3 and
12.5.5.2.1), so that a client that honors it holds the recall back; the
Linux client does with [2]. The resend comes first because the referring
call alone does not help the Linux client without [2] once it needs
more than half a second: it then answers NFS4ERR_NOMATCHING_LAYOUT
anyway, and the half second it waits makes more recalls meet an
unprocessed reply.

A pNFS client writes 1 MiB blocks with O_DIRECT to a new file for 60
seconds next to an NFSv4.0 client writing to another range of it, with a
test-only delay of one second in the pNFS client before
pnfs_layout_process(). Blocks that read back as zeroes / blocks written
through a layout, and the NFSv4.0 client, two runs each:

  nfsd-testing                         14/58, 14/57  600 in 15.0, 15.3 s
  + patch 1, referring call, no resend 31/56, 29/56  600 in 33.9, 32.4 s
  + patches 1 and 2                    0/27, 0/26    600 in 37.8, 51.9 s
  + patches 1 to 3                     0/23, 0/23    71, 76 in 62 s
  + patches 1 to 4                     0/25, 0/27    600 in 28.6, 27.9 s
  + patches 1 to 4, [2] on client      0/19, 0/23    600 in 40.9, 32.8 s

Every block lost was one whose reply the recall overtook. Patch 4 does
not act in this test, as the lease breaks come from the other client, so
patches 1 to 3 and 1 to 4 behave the same here. The cost is on the
writer that breaks the lease: a recall that meets a LAYOUTGET reply the
client has not processed within half a second lasts at least two and a
half seconds, and WRITEs through the metadata server get NFS4ERR_DELAY
meanwhile. With fs.lease-break-time at two seconds or less, such a
recall outlasts the lease break and the client is fenced. The NFSv4.0
client needs about 15 seconds plus, for each recall that meets an
unprocessed reply, nothing on nfsd-testing, half a second with the
referring call alone, two seconds with patches 1 and 2, and two and a
half from patch 3 on. Such recalls numbered 14 and 14, 31 and 29, 11 and
18, 23 and 23, and 5 and 5 in the rows above without [2]. How many there
are varies between runs: in twelve runs with patches 1
to 3 or 1 to 4, 23 or 24 met an unprocessed reply in eight, and the
NFSv4.0 client wrote 6 to 76 blocks in a minute; in the other four it
finished in 20.3 to 49.1 seconds. Two runs do not rank the stages.

With a delay of four seconds, longer than the resend covers, a client
without [2] loses every block whose reply the recall overtakes: 7 and 8
of 15 with patches 1 and 2, where the NFSv4.0 client was done after 29.0
and 31.5 seconds and broke no lease after that, and 15 of 15 in each of
two runs with patches 1 to 4, where it was still writing after 60
seconds. With [2], none (8 and 9 blocks).

QEMU guests (nvmet-tcp target, nfsd on XFS, NFSv4.2 block layout clients
and an NFSv4.0 client), nfsd-testing b4e06bef3884 with KASAN and
lockdep; no KASAN or lockdep report from nfsd or the clients. SCSI and
flexfiles layouts were not tested. Without the delay, one block read
back as zeroes in one of 17 runs of 30 seconds on nfsd-testing, in a run
that was not traced; the eight traced ones showed no recall overtaking a
reply. One boot of the target VM, on an image with patch 1 and the
referring call only, reported "BUG: KASAN: wild-memory-access in
do_raw_spin_lock" 0.6 seconds in, before any NFS traffic; twelve more
boots did not repeat it. pynfs BLOCK3 fails with NFS4ERR_BADXDR with and
without the series; local recall tests (not posted) pass from patch 2
on.

The series applies on nfsd-testing, which has [1] and [3]. Patch 2 needs
patches of [3] that it names, patch 3 should not go before v7.1, and
patch 4 needs patches 2 and 3.

[1] https://lore.kernel.org/r/20260802-nfsd-deleg-destroy-badhandle-v1-0-323aa7196055@kernel.org
[2] https://lore.kernel.org/r/20261020-nfs-referring-call-delay-v1-1-0be8f0608f7c@samsung.com
[3] https://lore.kernel.org/r/20261015-nfsd-layout-recall-v3-0-ba3269f8ca22@samsung.com

---
Daejun Park (4):
      nfsd: share the grant slot record between delegations and layouts
      nfsd: resend a layout recall once before trusting NOMATCHING_LAYOUT
      nfsd: send a referring call with CB_LAYOUTRECALL
      nfsd: do not fail a LAYOUTGET on a lease break by the same client

 fs/nfsd/nfs4layouts.c | 144 +++++++++++++++++++++++++++++++++++++++++++++-----
 fs/nfsd/nfs4proc.c    |   6 +++
 fs/nfsd/nfs4state.c   | 115 +++++++++++++++++++++++++++-------------
 fs/nfsd/state.h       |  53 ++++++++++++++++---
 fs/nfsd/trace.h       |   2 +
 5 files changed, 264 insertions(+), 56 deletions(-)
---
base-commit: b4e06bef38843c8b909d0b4317dfaaf87dba6d72
change-id: 20261021-nfsd-layout-refcall-60b4f9d6944d

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

