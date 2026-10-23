From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v7 0/8] fuse: {io-uring} Allow to reduce the number of
 queues and request distribution
Date: Sat, 24 Oct 2026 00:50:29 +0200
Message-Id: <20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43Ny27CMBCF4VdBXtfIF+JLV7xHhaqxZwJe1KF2E
 1GhvDsOqFXZRF3+R5pvrqxSSVTZ6+bKCk2ppiG3sC8bFk+Qj8QTtmZKqE5YpXghHCMhz4WXlI/
 8c6SR6rvmBmKwHgG9daydnwv16XKn3w6tT6l+DeX7/mmSy/oPdJJccABH2gJ5S2aPmLdx+GALO
 alfRgqhVxjVGLtTfS/B9bFzz4z+w8g1RjfGoLPRAWgJ9MyYH8ZIodYYszCdU7qLPviA+1ADlYw
 Pap7nGyUqXIWXAQAA
X-Change-ID: 20250722-reduced-nr-ring-queues_3-6acb79dad978
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2897; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=439drljPCtun3e95Ug86Q73VP6NEzeD2ZKEwJOGShkM=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuP9nltXxJ2YtfQZWlcpNcOk/du3Mm9M3N6E1pk6+Kc
 WeJG83Z11HKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQATmXyMkeFUdWae1+Vrex0a
 TRtW5S1sePP3t/qeBTv3a97cL5/PE/yJ4Q/3N6aVrUKTHwjEfJm0bmrY/1f+WVvCz3RGdEXtrnT
 M7+QHAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow a server to negotiate fewer io-uring queues than CPUs through
FUSE_URING_REDUCED_Q in its INIT reply. Reduced mode requires ADD_QUEUE
and starts serving at the first entry. Legacy mode waits for every queue.
RCU-published CPU maps retain NUMA affinity, background queue selection
and limited retries of busy queues.

Libfuse PR: https://github.com/libfuse/libfuse/pull/1659

Assisted-by: <various-ai-models>
Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Changes in v7:
- Address a Sashiko review about possible holes in the system cpu map,
  iterating about all CPUs might have caused issues. 
  We use for_each_possible_cpu() as iterate now and also check 
  with cpu_possible() .
- Link to v6: https://patch.msgid.link/20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com

Changes in v6:
- Rebase onto ADD_QUEUE and bufpool support.
- Require FUSE_URING_REDUCED_Q in the INIT reply for reduced mode (Joanne).
- Publish CPU-to-queue maps through RCU (Joanne).

Changes in v5
- Rebased to miklos-for-next (Linux 7.2 base).
- Folded "Fetch a queued fuse request on command registration" into
  "Allow reduced number of ring queues", inlining fuse_uring_do_register()
  into fuse_uring_register().
  - Fixed retry logic in "Add retry attempts for numa local queues":
    replaced cpu++ with cpumask_next_wrap(qid, mask) so each retry
    advances to a genuinely different registered queue (Joanne)-
  - Simplified "Prefer the current core over mapping" (Joanne).
  - Folded READ_ONCE() annotation for ring->ready into "Allow reduced
    number of ring queues" to match WRITE_ONCE() on the writer side and
    suppress a KCSAN data-race warning.

To: Bernd Schubert <bernd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev

---
Bernd Schubert (8):
      fuse: {io-uring} Add queue length counters
      fuse: {io-uring} Rename ring->nr_queues to max_nr_queues
      fuse: {io-uring} Add CPU to queue maps
      fuse: {io-uring} Select the queue through the CPU to queue maps
      fuse: {io-uring} Allow reduced queues through INIT negotiation
      fuse: {io-uring} Queue background requests on a different core
      fuse: Add retry attempts for numa local queues for load distribution
      fuse: {io-uring} Prefer the current core over mapping

 fs/fuse/dev.c             |   2 +-
 fs/fuse/dev.h             |   1 +
 fs/fuse/dev_uring.c       | 324 ++++++++++++++++++++++++++++++++++++++++------
 fs/fuse/dev_uring_i.h     |  31 ++++-
 fs/fuse/inode.c           |   8 +-
 include/uapi/linux/fuse.h |   4 +
 6 files changed, 324 insertions(+), 46 deletions(-)
---
base-commit: 1d8630946017ead740c4126395d4763371f0107c
change-id: 20250722-reduced-nr-ring-queues_3-6acb79dad978

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

