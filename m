From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v8 0/8] fuse: {io-uring} Allow to reduce the number of
 queues and request distribution
Date: Sun, 25 Oct 2026 23:29:08 +0100
Message-Id: <20261025-reduced-nr-ring-queues_3-v8-0-8a2570e8d2a4@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NTU7DMBCG4atUXmPkn8Rjs+o9EEKOZ9x6gVNsE
 oGq3B2nEtBsIpbvJ80zV1apJKrs6XBlheZU05hb2IcDC2efT8QTtmZKqF6AUrwQToGQ58JLyif
 +PtFE9VVz48MADj06sKydXwrF9Hmjn19an1P9GMvX7dMs1/Uf6Cy54N5b0uDJAZkjYn4M4xtby
 Vn9MlIIvcOoxkCnYpTextDbLaPvGLnH6MYYtBCs91p62jLmhzFSqD3GrExvle6DG9yAx6EOVDL
 +UXBPdTsUNKojAFK2i9jZLbUsyzdPHkrZ4gEAAA==
X-Change-ID: 20250722-reduced-nr-ring-queues_3-6acb79dad978
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=3122; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=CYo6sDs3WQXmK8jeohKh+18IGAcALzYcj0hLeTiLakI=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLLuNe2bdP+Q1JZ+GbHtR5nrLbbsqlzoco/xW3c61w+d0
 Dl1LvvlOkpZGMQ4GGTFFFm6JPbYTvnHJ6v2df11mDmsTCBDGLg4BWAil18yMvy/eTx+6a9QF8en
 /3/EFZ2QrE4zbzPtV7oTNlHAJFZexIThn/3ud59cluwq3ezL7Xn61Yy7TlPfSQTMaVljETfV7Em
 DIhMA
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
Changes in v8:
- Address another Sashiko review, FUSE_URING_REDUCED_Q should be
  in the fuse_uring_enabled() group
- Link to v7: https://patch.msgid.link/20261024-reduced-nr-ring-queues_3-v7-0-4e77e284fd48@bsbernd.com

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
 fs/fuse/inode.c           |   9 +-
 include/uapi/linux/fuse.h |   4 +
 6 files changed, 325 insertions(+), 46 deletions(-)
---
base-commit: 1d8630946017ead740c4126395d4763371f0107c
change-id: 20250722-reduced-nr-ring-queues_3-6acb79dad978

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

