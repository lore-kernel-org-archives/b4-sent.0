From: Daejun Park <daejun7.park@samsung.com>
Subject: [PATCH v2 0/7] nfsd: layout recall and lease break fixes
Date: Wed, 14 Oct 2026 16:29:56 +0900
Message-Id: <20261014-nfsd-layout-recall-v2-0-764462bddfd1@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHQvz2oC/32NTQ6CMBBGr0Jm7Zj+KKIr72FYlDJAE2hNB4iE9
 O5WDuDyveR73w5M0RHDo9gh0urYBZ9BnQqwg/E9oWszgxKqlEKU6DtucTRbWGaMZM04YmOqsmq
 11jdJkIfvSJ37HNFXnXlwPIe4HR+r/Nm/uVWiwOZ6b7S0ptMX9WQz8eL7sw0T1CmlL6BjAsq2A
 AAA
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>, 
 NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <bcodding@redhat.com>, 
 Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>, 
 linux-nfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791962996; l=16561;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=CHqYC+mclk4++3ucHCoNlDxp0XFUfNC4MUf/xqj4Zlo=;
 b=MZ22kyC8cfSniBRyWVUIwHsVZ3Oz1chYZ95WRpqW09VfzQsuFSshnprpa6ESE10rYr6aWGVaV
 FEx0x5og8UnAiQLsStnVKkMPNjtbA3yqL3tmioG9Vv913wuBYILDgNu
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd polls a client that has accepted a CB_LAYOUTRECALL by sending the
callback again every 10 ms, with the stateid of the first callback. A
Linux client from v6.8 on answers the repeat with NFS4ERR_OLD_STATEID,
and nfsd takes that as a failed recall. So a client that needs more
than 10 ms to return a layout has the layout revoked and the fence path
run. With the block layout that client loses data it has written and
synced, with the SCSI layout it is cut off from the device. Patch 5
lets nfsd keep polling instead.

A recall that takes longer makes the operation that started it wait
longer. When that operation is a WRITE, a SETATTR that changes the
size, an ALLOCATE, a DEALLOCATE, a CLONE or a COPY, the nfsd thread
serving it waits in XFS until the layouts are returned or the lease
break times out. As Chuck pointed out on v1, a few such requests can
take every nfsd thread, and the server then cannot serve the
LAYOUTRETURN that would release them. Patch 2 recalls the layouts
before the operation without waiting, gives the layouts of other
clients 30 ms to come back when it starts their recall, and otherwise
answers NFS4ERR_DELAY.

The cost of patch 2: a client that writes to a file through its layout
and, for writes that are not aligned, through the server recalls its
own layout with each such WRITE and has its LAYOUTGETs fail with
NFS4ERR_RECALLCONFLICT meanwhile. In test 2 it wrote 48, 46 and 4 1 MiB
blocks through its layout in 30 seconds instead of 534, 537 and 505;
before, 6 of 7, 4 of 4 and 17 of 20 recalls ended in the failure path
and 7, 4 and 20 blocks were lost. The series on top of this one, with
the NFS client fix it needs, brings that to 193, 192 and 184 blocks.

Patches 3 and 4 are the other two that patch 5 needs. Patch 3: the
limit of two lease periods on the poll has never triggered, and without
it the poll would have no end. Patch 4: for the block layout a lease
break gives up after fs.lease-break-time (45 s) without running
/sbin/nfsd-recall-failed. Until now the recall had failed long before
that; with patch 5 it is polled for two lease periods (180 s). Patch 4
fences the client at fs.lease-break-time, as the SCSI layout does since
v7.1; by default that is shorter than the one lease period RFC 8881
section 12.5.5 has the server wait after a recall.

Patch 1 fixes a lease break that hits a LAYOUTGET in progress and then
waits for a layout that is never recalled. It comes first because
patch 2 makes that common: the break of patch 2 runs outside the XFS
iolock, so it can land between the allocation of a layout stateid and
the insertion of its first layout.

Patches 6 and 7 deal with two answers that the polls handle badly. A
client that a LAYOUTRETURN has moved past the seqid of the recall
answers every poll NFS4ERR_OLD_STATEID and is never asked for the
layouts it still holds; patch 6 polls such a client, one that has not
answered NFS4_OK, with a new seqid. A client that answers
NFS4ERR_BAD_STATEID after returning its last layout is fenced; patch 7
looks for layouts first.

Patches 1 to 5 have to go together, also to stable kernels. Patch 6
builds on patches 1 and 5, and patch 7 stands on its own. If patch 2
should not go to stable, patches 3 to 5 should not either; patches 1
and 7 can go alone. Kernels before v7.1 do not have the lease break
timeout that patch 4 fixes; there an operation on the server that does
not come from nfsd waits for the recall for up to two lease periods, as
it already does, without a limit, for a client that keeps answering
NFS4ERR_DELAY. Patch 2 uses nfsd_thread_local_info and needs adapting
where that is missing.

Tests. QEMU guests on one host: an nvmet-tcp target, the server (nfsd,
XFS on the nvmet namespace, pnfs export) and up to three clients, all
on the same kernel with KASAN and lockdep, NFS v4.2, block layout
unless noted, O_DIRECT I/O. "v2" is this series on nfsd-testing
56589cdb5881, "v1" is v1 on it, and "before" is that commit unless
noted. No KASAN or lockdep report on the server in any run, nor on the
clients and the target in tests 2, 3 and 5, where they were checked.

1. nfsd threads (patch 2), 4 nfsd threads. A client holds a layout of
   a file and its path to the device is cut for 70 s. Another client,
   without pNFS, sends 4 KiB WRITEs to the file through the server, all
   at once, and reads 4 KiB of another file every second:

                                            before     v1        v2
   8 WRITEs, NFSv4.0: the WRITEs take       46.7 s     -         45.2 s
     longest read of the other file         46.7 s     -         0.031 s
   64 WRITEs, NFSv4.0: the WRITEs take      -          49.2 s    45.4 s
     longest read of the other file         -          49.1 s    0.22 s
   8 WRITEs, NFSv3: the WRITEs take         47.0 s     -         51.2 s
     longest read of the other file         46.9 s     -         0.021 s

   The WRITEs wait for the lease break, which ends with
   /sbin/nfsd-recall-failed (patch 4). NFSv3 WRITEs take longer with
   v2 because the client waits 5 s after NFS3ERR_JUKEBOX. In the run
   with 64 WRITEs before this series, the recall failed after 10 ms, as
   described above, and the WRITEs were done in 0.5 s.

2. What patch 2 costs. Two clients write 1 MiB blocks to a new file for
   30 s, one through its layout and one (NFSv4.0) through the server,
   three runs. "+ follow-up" adds the nfsd series that goes on top of
   this one and an NFS client fix that it needs.

                      through the     of those, read      through the
                      layout          back as zeroes      server
   before             416/200/186     28/131/111          120/325/323
   v2                 174/176/170     0/0/0               184/203/220
   v2 + follow-up     170/175/176     0/0/0               284/223/207

   The 30 ms wait is what keeps the writer through the server going:
   two earlier revisions of v2 + follow-up that differ only in it gave
   79/79/80 blocks through the server without the wait and 238/230/137
   with it.

   One client doing both, 1 MiB blocks through its layout and 512 byte
   writes through the server:

                      through the     of those, read      writes through
                      layout          back as zeroes      the server
   before             534/537/505     7/4/20              32/21/87
   v2                 48/46/4         0/0/0               3600/3262/4917
   v2 + follow-up     193/192/184     0/0/0               1082/1488/1669

   With v2 alone, each WRITE of that client through the server recalls
   its layout. About half of its LAYOUTGETs then meet that recall and
   get NFS4ERR_RECALLCONFLICT, as before; the other half are in
   progress when the WRITE breaks the lease, and patch 1 fails them.
   The Linux client waits up to 15 s between LAYOUTGETs that fail with
   NFS4ERR_RECALLCONFLICT. The follow-up hands out the layout of such a
   LAYOUTGET and recalls it at once. That needs the referring call the
   follow-up adds to CB_LAYOUTRECALL: tried in this series, the recall
   overtook the LAYOUTGET reply, and in all three runs 92 to 104 of
   about 260 blocks read back as zeroes.

   On 214e388464bf, before and v2 gave the same picture, except that in
   one of three runs of the one-client case with v2 one block read back
   as zeroes, through the recall race described under "Not changed".

   The series applies to nfsd-testing c32fef6c476d unchanged, and there
   before and v2 gave the same picture again, also for NFSv3, whose
   replies now come from xdrgen. In test 1 the longest read of the
   other file was 47.8 s before and 0.036 s with v2 over NFSv4.0, and
   48.3 s and 0.019 s over NFSv3, where the WRITEs took 48.4 s and
   51.3 s. In this test, with two clients, 48, 94 and 90 of 180, 185
   and 181 blocks through the layout read back as zeroes before, and
   none of 161, 177 and 172 with v2; with one client, 8, 0 and 3
   before and none with v2.

   Writes to a file without leases: fio, NFSv4.0, no KASAN or lockdep,
   10 runs of 30 s, medians without and with an earlier revision of v2
   (the same path for such a file): 1 MiB sequential 65.8 and 67.5
   MiB/s, 4 KiB random 262 and 263 IOPS.

3. Recall polling (patches 3 to 6). With v2 no recall ended in the
   failure path (0 of 9, 9, 63 and 277 in the arms of patch 5) and no
   block written to a new file was lost (0 of 545, 511, 477, 577 and
   36). Patch 5 has the runs before.
   On c32fef6c476d, four of those arms lost 4, 2, 18 and 9 blocks
   before, with 46 recall failures logged, and none with v2, with no
   recall failure.

4. One client writing through a block layout whose path to the device
   is cut while it can still talk to the server, and a 4 KiB write to
   the file on the server ("before" of the 15 s case is 32eb1a60b456).
   The client's write that is in flight stays stuck until the path is
   back.

                                                   before      v2
   path cut for 15 s: the server write takes       0.05 s      15.6 s
     the recall                                    fails       completes
     /sbin/nfsd-recall-failed is run               at once     no
   path cut for 70 s: the server write takes       0.05 s      47.2 s
     /sbin/nfsd-recall-failed is run               at once     at 47.1 s

   The same 70 s case with a script that expires the client it fences
   through /proc/fs/nfsd/clients/<clid>/ctl: with v1's fence worker,
   which runs the script itself, the script never finished and the
   server write went on only after the path was back, after 93 s. With
   v2 the script was done 36 ms after it started, and the server write
   took 46.1 s. With a lease time of 15 s, the recall reaches its limit
   (patch 3) after 30 s, before the lease break times out, and the
   recall failure path runs the script: there it hangs with v2 as well,
   the script in nfsd4_shutdown_callback() and rpciod in
   call_usermodehelper_exec().

5. A lease break during a LAYOUTGET (patch 1). With v2 the longest of
   424 writes on the server took 55 ms, and 108 ms with a delay of
   100 ms added to LAYOUTGET for the test. Patch 1 has the runs without
   it.

6. SCSI layout. The target runs a kernel with "nvmet: fix preempt of
   another registrant by the reservation holder" [1], so that the
   preempt removes the registration. With v2, the path of a client cut
   for 15 s: the server write takes 15.2 s and the client is not
   fenced; cut for 70 s: 47.6 s, and the fence worker fences the client
   (registrants 2 -> 1).

pynfs BLOCK1, BLOCK2, BLOCK4 and BLOCK5 pass before and with v2 (BLOCK3
fails in both with a TypeError in the test). The commit messages of
patches 6 and 7 have pynfs clients that answer as described there.

Not changed by these patches:

- A layout granted between the check of patch 2 and the break in XFS
  still makes the nfsd thread wait. No new layout lease is granted
  while a break is pending, so that needs a LAYOUTGET for a file that
  had no layout at the check. An asynchronous COPY runs in its own
  kthread and still waits there.

- The recall failure path still runs /sbin/nfsd-recall-failed from
  nfsd4_cb_layout_done(), in rpciod, while the callback is in flight.
  A script that expires the client it fences hangs there, because the
  teardown waits for that callback in nfsd4_shutdown_callback(); test 4
  shows it. Neither path looks at the exit status of the script, and
  the recall failure path does not look at the result of
  ->fence_client(): a fence that fails is taken as done there, and the
  layouts it drops end the retries of a fence worker that a lease break
  has started (patch 3 says so).

- nfsd still polls a client that has answered NFS4_OK with the seqid it
  has used, where RFC 8881 section 12.5.3 has the server increment the
  seqid in each request. Patch 5 only makes nfsd bear the answer
  (patch 6 gives a new seqid only to a client that has not answered
  NFS4_OK), and while it polls, nfsd sends a callback every 10 ms for
  up to two lease periods.

- CB_LAYOUTRECALL carries no referring call, as CB_RECALL does since
  "NFSD: Send referring calls with CB_RECALL". When a recall overtakes
  the reply to the LAYOUTGET that created the layout stateid, the Linux
  client answers NFS4ERR_NOMATCHING_LAYOUT, nfsd drops the layout and
  the client uses it afterwards. nfsd also trusts
  NFS4ERR_NOMATCHING_LAYOUT while it still has layouts on the layout
  stateid. The series on top of this one adds the referring call and
  resends the recall once before it trusts that answer, and with it
  recalls a layout handed out by a LAYOUTGET that a lease break met,
  instead of failing that LAYOUTGET (see test 2).

- Which client makes progress when several clients use one file: the
  client that holds a layout now keeps it while it does I/O through
  it, where before its layout was revoked after 10 ms. Nothing here
  limits how long one client can keep others out.

[1] https://lore.kernel.org/r/20261002065931epcms2p1cb2c16f98cf3b05f8c859ad92b0ad465@epcms2p1

---
Changes in v2:
- New patch 2, which recalls the layouts without waiting before an
  operation that modifies the file and answers NFS4ERR_DELAY, as Chuck
  asked:
  https://lore.kernel.org/r/63ef8d7c-086f-4cc8-84bb-72c1b23bf596@slotpi15m67
- v1 4/6 is now patch 1, ahead of patch 2, which makes its case common.
  v1 1/6 to 3/6 are patches 3 to 5, v1 5/6 and 6/6 are patches 6 and 7.
- Sashiko on v1:
  - 2/6, the fence script waiting for itself when it expires the client
    through /proc/fs/nfsd/clients/<clid>/ctl: patch 4 runs the script
    in a work item on a new workqueue, nfsd4_fence, and the fence
    worker checks every 100 ms whether it is done. Teardown waits only
    for the fence worker, which no longer waits for the script.
  - 2/6, sleeping fence workers filling system_dfl_wq: the same change;
    a script that runs long occupies nfsd4_fence.
  - 3/6, ktime_get() stops during suspend: patch 3 takes the time with
    ktime_get_boottime().
  - 5/6, si_generation written under sc_lock in ->done and read under
    ls_mutex only: patch 6 reads it under sc_lock in
    nfsd4_preprocess_layout_stateid() as well.
  - 1/6, the result of ->fence_client() not looked at on the recall
    failure path, which also ends the retries of the fence worker: not
    changed, said in patch 3. Patch 3 makes the path reachable after two
    lease periods for a client that keeps answering; before, a client
    from v6.8 on reached it after 10 ms.
  - 2/6, the exit status of the script not looked at: not changed.
    Retrying a failed script would block the file for good on a server
    that has no /sbin/nfsd-recall-failed. Said in patch 4.
  - 6/6, NFS4ERR_NOMATCHING_LAYOUT trusted while layouts are left:
    preexisting, not changed here (see the list above).
- Rebased onto nfsd-testing c32fef6c476d without changes, and tests 1
  to 3 run again there.
- Test numbers in the cover from v2; the commit messages of patches 1,
  4 and 5 keep their runs on nfsd-testing 32eb1a60b456 for the side
  without the patch. Commit messages with one space after a period.
- Link to v1: https://lore.kernel.org/r/20261006-nfsd-layout-recall-v1-0-b59b31caf342@samsung.com

---
Daejun Park (7):
      nfsd: fail a LAYOUTGET in progress when the layout lease is broken
      nfsd: answer NFS4ERR_DELAY instead of waiting for a layout recall
      nfsd: make the time limit of a layout recall work
      nfsd: run the fence script when a block layout lease break times out
      nfsd: keep polling a layout recall answered with NFS4ERR_OLD_STATEID
      nfsd: poll a layout recall with a new seqid when the client is past it
      nfsd: do not fence a client for a layout recall with no layouts left

 fs/nfsd/nfs4layouts.c | 301 ++++++++++++++++++++++++++++++++++++++++++++++----
 fs/nfsd/nfs4proc.c    |   8 ++
 fs/nfsd/pnfs.h        |  15 +++
 fs/nfsd/state.h       |   8 ++
 fs/nfsd/trace.h       |   2 +
 fs/nfsd/vfs.c         |  81 +++++++++++++-
 fs/nfsd/vfs.h         |   1 +
 7 files changed, 391 insertions(+), 25 deletions(-)
---
base-commit: c32fef6c476daa5830f600614657baee59c83339
change-id: 20261006-nfsd-layout-recall-ba868d33371e

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

