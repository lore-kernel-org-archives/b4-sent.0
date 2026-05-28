From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v5 0/7] fuse: {io-uring} Allow to reduce the number of
 queues and request distribution
Date: Fri, 29 May 2026 00:55:04 +0200
Message-Id: <20260529-reduced-nr-ring-queues_3-v5-0-1dc08c2fccf6@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMjHGGoC/43Nyw6CMBCF4VcxXVvTi9DiyvcwxoztFLqwaCtEQ
 3h3CwsvG+LyP8l8M5CE0WMiu9VAIvY++TbkKNYrYhoINVJvcxPBRMGUEDSi7QxaGiKNPtT01mG
 H6SRpCeasKgu2Uprk82tE5x8zfTjmbny6t/E5f+r5tP6B9pwyCqBRKsBKYbm3NmxMeyET2Ys3w
 xmTC4zIjNoK5zhoZwr9y8gvhi8xMjOl1cpoAMkBP8w4ji/RJSX/TAEAAA==
X-Change-ID: 20250722-reduced-nr-ring-queues_3-6acb79dad978
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, Luis Henriques <luis@igalia.com>, 
 Gang He <dchg2000@gmail.com>, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bschubert@ddn.com>, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780008905; l=2550;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=QZwi2+4P0m+eJRFUsdOIG+lBm5lAYwWOJStlyDgC8U8=;
 b=pwzoR5JUxGJQNSaHJVMgT7CCBsDiCqw7zWpGcsCc6ke4g+vZ25Q5TdsvcVLQrfSx7Op+3y2r5
 0ATJoR6FPXNBezf8ArQCk3mheHnbVYnGBCsOaULcyqUn7cnsEV1ZftV
X-Developer-Key: i=bernd@bsbernd.com; a=ed25519;
 pk=EZVU4bq64+flgoWFCVQoj0URAs3Urjno+1fIq9ZJx8Y=
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/20240529 with auth_id=732
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds bitmaps that track which queues are registered and which queues
do not have queued requests.
These bitmaps are then used to map from request core to queue
and also allow load distribution. NUMA affinity is handled and
fuse client/server protocol does not need changes, all is handled
in fuse client internally.

Signed-off-by: Bernd Schubert <bschubert@ddn.com>
---
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

Changes in v4:
- Fix leak of ring->numa_q_map
- Fix q-imbalance due to an issue in static cpu->qid mapping
- Performance tunings, like preferring the current cpu
- Removal of distribution among queues, Joanne had concerns about it.
  As it is an optimization, it can be added later again. At least
  most of it was removed, some light distribution is still left in.
- At the end of the series, add fuse debugfs entries. This could
  be factored out.
- Link to v3: https://lore.kernel.org/r/20251013-reduced-nr-ring-queues_3-v3-0-6d87c8aa31ae@ddn.com

---
Bernd Schubert (7):
      fuse: {io-uring} Add queue length counters
      fuse: {io-uring} Rename ring->nr_queues to max_nr_queues
      fuse: {io-uring} Use bitmaps to track registered queues
      fuse: {io-uring} Allow reduced number of ring queues
      fuse: {io-uring} Queue background requests on a different core
      fuse: {io-uring} Add retry attempts for numa local queues for load distribution
      fuse: {io-uring} Prefer the current core over mapping

 fs/fuse/dev_uring.c       | 313 ++++++++++++++++++++++++++++++++++------------
 fs/fuse/dev_uring_i.h     |  25 +++-
 fs/fuse/inode.c           |   2 +-
 include/uapi/linux/fuse.h |  10 +-
 4 files changed, 269 insertions(+), 81 deletions(-)
---
base-commit: 2dcf16d41cc04472a4f9bc6e99d0ab26cfb1afb1
change-id: 20250722-reduced-nr-ring-queues_3-6acb79dad978

Best regards,
-- 
Bernd Schubert <bernd@bsbernd.com>

