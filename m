From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v3 0/5] ceph: fix lazyio for shared-file writers
Date: Tue, 27 Oct 2026 08:00:44 +0100
Message-Id: <20261027-b4-wip-ceph-lazyio-fix-v3-0-df2926c30867@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0K6dgwtBcGV9zAuYJhKDVJCsYqEu
 9viho1x+SZ/3puZpUGTZcdoZgM5bbXpPCS7iGFTdlcCXXtmIhYZj0UMlYSn7gGpb6At35M2oPQ
 LUsUTRTzJFSLzz/1A/ryKz5cv20d1IxyDLSwabUczTGvZ8bD7G3EcYlASMRMyLerkcMJ2smaP5
 s5CxImthv/UCK8RaS1yeSjqjMqtZlmWD41MyVsVAQAA
X-Change-ID: 20261020-b4-wip-ceph-lazyio-fix-5f13fe138fcc
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793084460; l=9480;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=H4Dnd8DTxKhrQrkaPaZyqNXUnOL51OeL0d4ag1YWXTA=;
 b=e/ohbaSAcg9viWYB+uJTbInbLdZN0X3708NtJzWVwGImbUEX0OgO1kSq8BOKqqWae8Qx7G7DK
 So6MBHTKQ/dBqhHa6KB+b/CPd5QD8J/syW30JPo3fkbCcF3y84uAv5l
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The lazyio mount option lets several clients buffer and cache writes to
one shared file.  With it, the io500 ior-hard phase fails its read
verification and the whole run is marked invalid.  ior-hard has every
process write 47008-byte records (11 pages plus 2112 bytes) into one
shared file, interleaved with the records of the other processes, so
the record boundaries fall inside pages that two clients share.  A
client writes such a page back whole, and the bytes around its own
record, read before the write or zero-filled beyond its local EOF,
overwrite the records another client wrote into the same page.  In the
tests below each client is a separate kernel client mount.

Patch 3 is the fix: a page that a lazy I/O write dirtied only in part
keeps its dirty byte range, and writeback sends only that range.  A
write without lazy I/O starts no range, so non-lazy writeback is
unchanged and sends whole pages as before.  Nor does a page that may be
pinned for writing (GUP): the pin could write outside the range without
the page being dirtied again.

Patches 1, 2, 4 and 5 fix cap handling problems found while testing it:

 - Patch 1: ceph_check_caps() could put off invalidating a cache whose
   CACHE or LAZYIO was being revoked while the session's cap was stale,
   and nothing checked it again.  The MDS then waited for the revoke
   for good.  A lazy writer on a slow client (arm64, 64K pages, under
   QEMU) hung that way after shared-file writes.

 - Patches 2 and 4: a lazy I/O open no longer asks for LAZYIO while
   CACHE (for a reader) or BUFFER (for a writer) is available, and asks
   for it only once the MDS turns those down.  This saves a cap update
   and a grant per lazy open of a cached inode, and the LAZYIO revoke
   when the only client of a file opened for writing becomes its loner.

 - Patch 5: a closed file keeps LAZYIO as long as it keeps its read
   caps, instead of sending the MDS a cap update for every closed file
   only to give LAZYIO back.  With lazyio, io500 mdtest-hard-read sent
   about one such message per file read.

Testing
=======

One host, 3 OSDs on NVMe, 3 active MDS with a distributed tree pin on
the mdtest directories, 4 kernel client mounts, 16 io500 processes
(4 per client), io500 with all phases unless noted.

Data verification, lazyio mount option:

+-------------------------------+------------------+------------------+
| Test                          | Without series   | With series      |
+-------------------------------+------------------+------------------+
| ior-hard only, bad records    | 131881           | 0 (3 runs)       |
| Full io500, bad records       | 142876, 73999    | 0 (10 runs)      |
| Full io500 result             | invalid          | valid            |
+-------------------------------+------------------+------------------+

Full io500, unpatched kernel without lazyio vs this series with
lazyio (2 runs each):

+---------------------------+-----------------+-----------------+-----+
| Phase / score             | Unpatched       | Series + lazyio | Diff|
+---------------------------+-----------------+-----------------+-----+
| ior-hard-write (GiB/s)    | 0.193 / 0.192   | 0.267 / 0.272   | +40%|
| ior-hard-read (GiB/s)     | 0.459 / 0.457   | 0.460 / 0.458   | +1% |
| BW score                  | 0.914 / 0.908   | 0.982 / 0.980   | +8% |
| MD score                  | 27.30 / 26.36   | 27.45 / 27.53   | +3% |
| TOTAL                     | 4.994 / 4.893   | 5.192 / 5.193   | +5% |
+---------------------------+-----------------+-----------------+-----+

Without the lazyio mount option the series changes nothing measurable:
full io500 TOTAL 4.932 / 4.929 unpatched vs 4.935 / 4.910 with patches
1-3 (patch 4 only changes lazy I/O opens).  A non-lazy fio sub-page
overwrite test was within the run-to-run spread (about +-4%).

arm64 with 64K pages (QEMU guest): fsx, overwrites checked from a
second mount, and lazy writes of 47008-byte and 3000-byte records from
4 mounts all pass, with 0 bad words, in crc, legacy and secure
messenger modes.

Lazy I/O functional tests (x86_64 QEMU guest with KASAN and lockdep,
vstart cluster, two or four independent lazyio kernel client mounts;
every test checks the file from another client):

+------------------------------------------+----------------+----------+
| Test                                     | Without fix    | v3       |
+------------------------------------------+----------------+----------+
| ior-hard pattern, read-back check (1)    | 3 of 3 runs    | 0 of 3   |
|                                          | fail, with     |          |
|                                          | 2408-2693      |          |
|                                          | errors each    |          |
| Truncate below a lazy dirty range whose  | -              | 0 of 80  |
| cached prefix another client rewrote (2) |                | cases    |
| Same, truncate injected on the writer    | v1: 19 of 20   | 0 of 80  |
| (3)                                      | dropped-range  | cases    |
|                                          | cases fail     |          |
| Same, writer's session stale across the  | -              | pass     |
| truncate (4)                             |                |          |
| Writable GUP pin held across writeback   | v2: 3 of 3     | 0 of 3   |
| (5)                                      | runs fail      |          |
+------------------------------------------+----------------+----------+

 (1) io500's ior-hard arguments (47008-byte records, 1000 segments),
     8 processes on 4 mounts.
 (2) A caches a page, B rewrites it, A writes 32 bytes at its tail,
     and A or B truncates the file below them, with and without
     extending it again.  The MDS revokes A's BUFFER cap first, so A
     writes back before the truncate.
 (3) A test-only hook, not part of this series, moves A's EOF below or
     into its dirty range (with and without truncate_pagecache())
     before A writes back, which reaches the clipping and dropping
     paths of patch 3.  v1 sent the stale bytes in front of a range
     that the truncate dropped.
 (4) A's MDS connection is blocked until its session goes stale, B
     truncates below A's range, and A reconnects.
 (5) A 2 MiB O_DIRECT read from a dm-delay device into mmapped pages of
     the file, held across an fsync and a 100-byte lazy write into every
     page.  v2 lost the other 3996 bytes of every page.

KASAN, lockdep and hung task checks stayed clean in all of them.

Known issues, not addressed here
================================

 - mdtest's read phase opens files read-write.  With lazyio that still
   costs about one LAZYIO revoke per file in io500 mdtest-hard-read
   (2.5-2.7M per run, against a few dozen without lazyio); patch 4
   removes it only in a smaller reproducer.  Opening the files read-only
   in mdtest removes the revokes in both modes.

 - A lazy read that starts about a second after a lazy write of the
   same file can hang in __ceph_get_caps(): a LAZYIO revoke is held back
   while the cap is in use, and nothing calls ceph_check_caps() again
   once the use ends.  Full io500 runs, which have other phases between
   ior-hard-write and ior-hard-read, have not hit it.

Signed-off-by: Xiubo Li <xiubo.li@clyso.com>
---
Changes in v3:
- Patch 3: start no dirty range on a folio that may be pinned for
  writing (GUP).  A pin older than the folio's last writeback could
  write outside the range, and the unpin does not dirty an already
  dirty folio again, so writeback dropped those bytes.  Reproduced with
  an O_DIRECT read into mmapped pages of the file, held across an fsync
  and a lazy write into every page. (Alex)
- Link to v2: https://patch.msgid.link/20261021-b4-wip-ceph-lazyio-fix-v2-0-25d28479d6ea@clyso.com

Changes in v2:
- Patch 3: when a truncate clips a lazy dirty range to nothing, or EOF
  moves below the range, drop the folio's dirty state instead of writing
  the whole folio up to EOF, which sent the stale bytes in front of the
  range.  Fixed in ceph_invalidate_folio(), ceph_check_folio_before_write()
  and write_folio_nounlock().  The new ceph_folio_drop_dirty() also
  decrements mdsc->dirty_folios. (Alex)
- Link to v1: https://patch.msgid.link/20261020-b4-wip-ceph-lazyio-fix-v1-0-f4cc62459d37@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Xiubo Li <xiubo.li@clyso.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Xiubo Li (5):
      ceph: invalidate a revoked cache even while its cap is stale
      ceph: do not ask for LAZYIO for a lazy reader that holds CACHE
      ceph: write back only the dirty bytes of a lazy I/O write
      ceph: ask for LAZYIO only once the MDS turns CACHE or BUFFER down
      ceph: keep LAZYIO with the read caps of a closed file

 fs/ceph/addr.c       | 402 ++++++++++++++++++++++++++++++++++++++++++++++-----
 fs/ceph/caps.c       |  51 ++++++-
 fs/ceph/file.c       |   4 +
 fs/ceph/mds_client.c |  10 ++
 fs/ceph/super.h      |   1 +
 5 files changed, 428 insertions(+), 40 deletions(-)
---
base-commit: ed0502cb11f84fff29f374238e526ae94d9bdfde
change-id: 20261020-b4-wip-ceph-lazyio-fix-5f13fe138fcc

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

