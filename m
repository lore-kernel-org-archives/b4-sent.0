From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v6 0/8] fuse: {io-uring} Allow to reduce the number of
 queues and request distribution
Date: Fri, 23 Oct 2026 22:28:42 +0200
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43Nyw6CMBCF4VcxXVvTi7TFle9hjBnbAbqwaCtEQ
 3h3CwsvG+LyP8l8M5CE0WMiu9VAIvY++TbkUOsVsQ2EGql3uYlgomBaCBrRdRYdDZFGH2p667D
 DdJJUgT3r0oErtSH5/Bqx8o+ZPhxzNz7d2/icP/V8Wv9Ae04ZBTAoNWCpUe2dCxvbXshE9uLNc
 MbkAiMyo7eiqjiYyhbml5FfDF9iZGaUM9oaAMkBP8w4ji/okbxkTAEAAA==
X-Change-ID: 20250722-reduced-nr-ring-queues_3-6acb79dad978
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=2558; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=KUk6hPwjwJba4divXeCUDPAxEnplWEnau4Zm9bn6kd0=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH25QOBT/7+Wi0IbPm/1LL80+ZjujXnzzqx9rpKwMp
 YS2358T01HKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQATeerKyLB62kHvHqO2ax57
 bp4w40lO7he4ffq/y0/x8DnFQTyKcxwZ/qdtk6xyWqvN5zI3Z2XVXP+FderNZTWXL6lUl6VUeD0
 7yg8A
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
 fs/fuse/dev_uring.c       | 318 ++++++++++++++++++++++++++++++++++++++++------
 fs/fuse/dev_uring_i.h     |  31 ++++-
 fs/fuse/inode.c           |   8 +-
 include/uapi/linux/fuse.h |   4 +
 6 files changed, 320 insertions(+), 44 deletions(-)
---
base-commit: 1d8630946017ead740c4126395d4763371f0107c
change-id: 20250722-reduced-nr-ring-queues_3-6acb79dad978

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

