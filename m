From: Bernd Schubert <bernd@bsbernd.com>
Subject: [PATCH 0/2] fuse: io-uring: tidy memory ordering for lockless
 ring/queue reads
Date: Mon, 15 Jun 2026 14:07:17 +0200
Message-Id: <20260615-fix-7-2-next-v1-0-0a4c3908f13c@bsbernd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avErBtQSYWuEi0qp5oWFlohRHfPa
 vnxeP8FkQJThLq4INDJkVefIcsChrnzEyG7bFBCGWGkxpETWlToKe1YWbKV1EI5LSFftkB5/3J
 N+zse/ULD/jbgvh8a0l6ZcAAAAA==
X-Change-ID: 20260615-fix-7-2-next-47e741502d51
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: fuse-devel@lists.linux.dev, Bernd Schubert <bernd@bsbernd.com>, 
 stable@kernel.org
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1308; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=D59Tczt7UHCecWDFEmcqrImxwSLUnFWmAPZf/E1O2N4=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL0X30vrXp89qH4eru2P6oWFm/UZlqY1Dk0eCf+PZU4e
 f3ldIuUjlIWBjEOBlkxRZYuiT22U/7xyap9XX8dZg4rE8gQBi5OAZiIfywjw41ZuXJ5jb8d1n4t
 OPR14u2Q1euvZcx4FxOR7151Sfdy5F1Ghm+C5+bYLJkt0NN2zYzx6tRdL3sOORdZO+jkTfjYOG+
 3DxcA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fuse io-uring code publishes fch->ring and ring->queues[qid] once and
then reads them mostly without holding fch->lock.  Reviewing that access
discipline turned up one genuine data race and one read that only looks
unsynchronized.

Patch 1 adds the READ_ONCE() that pairs with the existing WRITE_ONCE() on
ring->queues[qid]: the entry is published under fch->lock in
fuse_uring_create_queue() but read locklessly in the fast path of
fuse_uring_register().  That is a real data race - a torn/refetched load
could slip a garbage pointer past the NULL check - so it is tagged for
stable.

Patch 2 moves the fch->ring read in the race branch of fuse_uring_create()
back under fch->lock.  The read was already ordered by the under-lock
existence check, so this is a readability cleanup only; no functional
change.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
Bernd Schubert (2):
      fuse: {io-uring} use READ_ONCE() for ring->queues[] in fuse_uring_register()
      fuse: read fch->ring under fch->lock in fuse_uring_create()

 fs/fuse/dev_uring.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
---
base-commit: bb43b4c7ea2a8265141aa93240f3f0ca71d85c0e
change-id: 20260615-fix-7-2-next-47e741502d51

Best regards,
--  
Bernd Schubert <bernd@bsbernd.com>

