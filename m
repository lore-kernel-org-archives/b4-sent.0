From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 23 Oct 2026 22:28:48 +0200
Subject: [PATCH v6 6/8] fuse: {io-uring} Queue background requests on a
 different core
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261023-reduced-nr-ring-queues_3-v6-6-658235c9b9bd@bsbernd.com>
References: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
In-Reply-To: <20261023-reduced-nr-ring-queues_3-v6-0-658235c9b9bd@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=4021; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=8MeKPCFTmCl0gpq+o5smzXXdVYG5SfMu4GgpY26S2OI=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLJuH26adef1noWCDK8aQo6d1k89mGIxYWpp78lnHLfnP
 uo0XMeX3lHKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQAT4Z7AyHA3d8fB8gnbjyYx
 SL246R9mNzlM6fvmhdXnWkvbH8+e9U2XkeE6p1W15DT2c4u5Ni7om7NhYWt/wp2r7X+PtgcGX9u
 1xpwbAA==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Running background IO on a different core makes quite a difference.

fio --directory=/tmp/dest --name=iops.\$jobnum --rw=randread \
--bs=4k --size=1G --numjobs=1 --iodepth=4 --time_based\
--runtime=30s --group_reporting --ioengine=io_uring\
 --direct=1

unpatched
   READ: bw=272MiB/s (285MB/s) ...
patched
   READ: bw=650MiB/s (682MB/s)

Reason is easily visible, the fio process is migrating between CPUs
when requests are submitted on the queue for the same core.

With --iodepth=8

unpatched
   READ: bw=466MiB/s (489MB/s)
patched
   READ: bw=641MiB/s (672MB/s)

Without io-uring (--iodepth=8)
   READ: bw=729MiB/s (764MB/s)

Without fuse (--iodepth=8)
   READ: bw=2199MiB/s (2306MB/s)

(Test were done with
<libfuse>/example/passthrough_hp -o allow_other --nopassthrough  \
[-o io_uring] /tmp/source /tmp/dest
)

Additional notes:

With FURING_NEXT_QUEUE_RETRIES=0 (--iodepth=8)
   READ: bw=903MiB/s (946MB/s)

With just a random qid (--iodepth=8)
   READ: bw=429MiB/s (450MB/s)

With --iodepth=1
unpatched
   READ: bw=195MiB/s (204MB/s)
patched
   READ: bw=232MiB/s (243MB/s)

With --iodepth=1 --numjobs=2
unpatched
   READ: bw=366MiB/s (384MB/s)
patched
   READ: bw=472MiB/s (495MB/s)

With --iodepth=1 --numjobs=8
unpatched
   READ: bw=1437MiB/s (1507MB/s)
patched
   READ: bw=1529MiB/s (1603MB/s)
fuse without io-uring
   READ: bw=1314MiB/s (1378MB/s), 1314MiB/s-1314MiB/s ...
no-fuse
   READ: bw=2566MiB/s (2690MB/s), 2566MiB/s-2566MiB/s ...

In summary, for async requests the core doing application IO is busy
sending requests and processing IOs should be done on a different core.
Spreading the load on random cores is also not desirable, as the core
might be frequency scaled down and/or in C1 sleep states. Not shown here,
but differnces are much smaller when the system uses performance govenor
instead of schedutil (ubuntu default). Obviously at the cost of higher
system power consumption for performance govenor - not desirable either.

Results without io-uring (which uses fixed libfuse threads per queue)
heavily depend on the current number of active threads. Libfuse uses
default of max 10 threads, but actual nr max threads is a parameter.
Also, no-fuse-io-uring results heavily depend on, if there was already
running another workload before, as libfuse starts these threads
dynamically - i.e. the more threads are active, the worse the
performance.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 9 ++++++---
 1 file changed, 6 insertions(+), 3 deletions(-)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index d5d83506ae5a..87c8ea35d2c9 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -1955,7 +1955,8 @@ static void fuse_uring_send_in_task(struct io_tw_req tw_req, io_tw_token_t tw)
 	}
 }
 
-static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring)
+static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring,
+						       bool background)
 {
 	struct fuse_queue_maps *maps;
 	struct fuse_queue_map *q_map;
@@ -1976,6 +1977,8 @@ static struct fuse_ring_queue *fuse_uring_select_queue(struct fuse_ring *ring)
 	if (!q_map->nr_queues)
 		q_map = &maps->global;
 	qid = q_map->cpu_to_qid[cpu];
+	if (qid == cpu && background)
+		qid = cpumask_next_wrap(qid, q_map->registered_q_mask);
 	if (WARN_ON_ONCE(qid >= ring->max_nr_queues))
 		goto out;
 
@@ -2003,7 +2006,7 @@ void fuse_uring_queue_fuse_req(struct fuse_iqueue *fiq, struct fuse_req *req)
 	int err;
 
 	err = -EINVAL;
-	queue = fuse_uring_select_queue(ring);
+	queue = fuse_uring_select_queue(ring, false);
 	if (!queue)
 		goto err;
 
@@ -2046,7 +2049,7 @@ bool fuse_uring_queue_bq_req(struct fuse_req *req)
 	struct fuse_ring_queue *queue;
 	struct fuse_ring_ent *ent = NULL;
 
-	queue = fuse_uring_select_queue(ring);
+	queue = fuse_uring_select_queue(ring, true);
 	if (!queue)
 		return false;
 

-- 
2.55.0

