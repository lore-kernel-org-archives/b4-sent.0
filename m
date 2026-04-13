From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH v4 0/8] fuse: {io-uring} Allow to reduce the number of
 queues and request distribution
Date: Mon, 13 Apr 2026 11:41:23 +0200
Message-Id: <20260413-reduced-nr-ring-queues_3-v4-0-982b6414b723@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEO63GkC/43Nyw6CMBCF4VchXVvTC9DiyvcwxoztAF1YtBWiI
 by7hYWXDXH5n2S+GUnE4DCSXTaSgIOLrvMp8k1GTAu+QepsaiKYKJgSgga0vUFLfaDB+Ybeeuw
 xniQtwZxVZcFWSpN0fg1Yu8dCH46pWxfvXXgunwY+r3+gA6eMAmiUCrBSWO6t9VvTXchMDuLNc
 MbkCiMSo3JR1xx0bQr9y8gvhq8xMjGl1cpoAMkBP8w0TS/5S30/TAEAAA==
X-Change-ID: 20250722-reduced-nr-ring-queues_3-6acb79dad978
To: Miklos Szeredi <miklos@szeredi.hu>
Cc: Joanne Koong <joannelkoong@gmail.com>, linux-fsdevel@vger.kernel.org, 
 Luis Henriques <luis@igalia.com>, Gang He <dchg2000@gmail.com>, 
 Bernd Schubert <bschubert@ddn.com>, Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.15-dev-2a633
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776073284; l=2588;
 i=bernd@bsbernd.com; s=20240529; h=from:subject:message-id;
 bh=AYgMO8orETGEoNQ5KR2Hk5OZqWEsKJP9Um0payT4u9w=;
 b=+p2yCPDTjU0sgCtn1wVYrq0J3JjtJrpqKVifALPfz0ghb41UD8BR7GzKBTwDTXdjBS/w6KehS
 pi367cqPDxZDXFpS+Ik+0/y9DBusSLCDeozx4r31vCc0kmDQENTSdZL
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
Changes in v4:
- Fix leak of ring->numa_q_map
- Fix q-imbalance due to an issue in static cpu->qid mapping
- Performance tunings, like preferring the current cpu
- Removal of distribution among queues, Joanne had concerns about it.
  As it is an optimization, it can be added later again. At least
  most of it was removed, some light distribution is still left in.
- Link to v3: https://lore.kernel.org/r/20251013-reduced-nr-ring-queues_3-v3-0-6d87c8aa31ae@ddn.com

Changes in v3:
- removed FUSE_URING_QUEUE_THRESHOLD (Luis)
- Fixed accidentaly early return of queue1 in fuse_uring_best_queue()
- Fixed similar early return 'best_global'
- Added sanity checks for cpu_to_node()
- Removed retry loops in fuse_uring_best_queue() for code simplicity
- Reduced local numa retries in fuse_uring_get_queue
- Added 'FUSE_URING_REDUCED_Q' FUSE_INIT flag to inform userspace
  about the possibility to reduced queues
- Link to v2: https://lore.kernel.org/r/20251003-reduced-nr-ring-queues_3-v2-0-742ff1a8fc58@ddn.com
- Removed wake-on-same cpu patch from this series, 
  it will be send out independently
- Used READ_ONCE(queue->nr_reqs) as the value is updated (with a lock being
  hold) by other threads and possibly cpus.

---
Bernd Schubert (8):
      fuse: {io-uring} Add queue length counters
      fuse: {io-uring} Rename ring->nr_queues to max_nr_queues
      fuse: {io-uring} Use bitmaps to track registered queues
      fuse: Fetch a queued fuse request on command registration
      fuse: {io-uring} Allow reduced number of ring queues
      fuse: {io-uring} Queue background requests on a different core
      fuse: Add retry attempts for numa local queues for load distribution
      fuse: {io-uring} Prefer the current core over mapping

 fs/fuse/dev_uring.c       | 303 ++++++++++++++++++++++++++++++++++------------
 fs/fuse/dev_uring_i.h     |  25 +++-
 fs/fuse/inode.c           |   2 +-
 include/uapi/linux/fuse.h |   3 +
 4 files changed, 252 insertions(+), 81 deletions(-)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20250722-reduced-nr-ring-queues_3-6acb79dad978

Best regards,
-- 
Bernd Schubert <bernd@bsbernd.com>

