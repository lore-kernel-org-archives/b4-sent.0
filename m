From: Bernd Schubert <bernd@bsbernd.com>
Date: Sun, 25 Oct 2026 23:29:16 +0100
Subject: [PATCH v8 8/8] fuse: {io-uring} Prefer the current core over
 mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-reduced-nr-ring-queues_3-v8-8-8a2570e8d2a4@bsbernd.com>
References: <20261025-reduced-nr-ring-queues_3-v8-0-8a2570e8d2a4@bsbernd.com>
In-Reply-To: <20261025-reduced-nr-ring-queues_3-v8-0-8a2570e8d2a4@bsbernd.com>
To: Joanne Koong <joannelkoong@gmail.com>, 
 Miklos Szeredi <miklos@szeredi.hu>
Cc: Bernd Schubert <bernd@bsbernd.com>, fuse-devel@lists.linux.dev
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=1450; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=tpcIJt64KMjnkQcqgwgIdVkmxlr0O8K5l+u5VmbpUA8=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLLuNR2smzFp/6fMJSXimv0S708s/adSKHLRhfHoX1ez5
 f8XS95Y0FHKwiDGwSArpsjSJbHHdso/Plm1r+uvw8xhZQIZwsDFKQATcc9kZPhbYyQ/OXZzRdSj
 KOfb9Wyry7d8kk1KX7PTQzA3IchwgRnDf5e3vsWvLnsf1V/XK3iklj+R687LgP8d/ApLZZNOqq8
 9xgAA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update the mapping to prefer queues that belong to the
current cpu. If no queue is registered for the current cpu,
fall back is to the existing round robin logic.

Example (with core binding)

unpatched WRITE: bw=841MiB/s
patched   WRITE: bw=1363MiB/s

With
fio --name=test --ioengine=psync --direct=1 \
    --rw=write --bs=1M --iodepth=1 --numjobs=1 \
    --filename_format=/redfs/testfile.\$jobnum --size=100G \
    --thread --create_on_open=1 --runtime=30s --cpus_allowed=1

In order to get the good number `--cpus_allowed=1` is needed.
This could be improved by a future change that avoids
cpu migration in fuse_request_end() on wake_up() call.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 fs/fuse/dev_uring.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/fs/fuse/dev_uring.c b/fs/fuse/dev_uring.c
index ca82965fdee1..2efea959d7e6 100644
--- a/fs/fuse/dev_uring.c
+++ b/fs/fuse/dev_uring.c
@@ -398,6 +398,12 @@ static void fuse_uring_cpu_qid_mapping(struct fuse_queue_map *q_map, int node)
 		if (node != -1 && fuse_uring_cpu_to_node(cpu) != node)
 			continue;
 
+		/* Prefer the queue belonging to the current cpu */
+		if (cpumask_test_cpu(cpu, q_map->registered_q_mask)) {
+			q_map->cpu_to_qid[cpu] = cpu;
+			continue;
+		}
+
 		qid_idx = mapping_count % q_map->nr_queues;
 		q_map->cpu_to_qid[cpu] = cpumask_nth(qid_idx,
 						     q_map->registered_q_mask);

-- 
2.55.0

