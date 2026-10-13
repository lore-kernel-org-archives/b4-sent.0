From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH 0/3] ceph: fix the buffered read size metric and make the
 subvolume metrics per CPU
Date: Wed, 14 Oct 2026 01:20:39 +0200
Message-Id: <20261014-ceph-metrics-percpu-v1-0-38c5a24fec6e@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqCUBBG4VeRWTdwRzShV4kWOf3mBNllRiUQ3
 71bLb/FORsF3BB0qjZyrBb2mgrkUJGO1+kOtlsx1ak+SpKGFXnkJ2Y3Dc5wzQuL9m1quqGTNlE
 ps2Ow9+96vvwdS/+Azt8V7fsH2vk3m3cAAAA=
X-Change-ID: 20261014-ceph-metrics-percpu-1cb5047f7150
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Viacheslav Dubeyko <slava@dubeyko.com>, 
 Milind Changire <mchangir@redhat.com>, Jeff Layton <jlayton@kernel.org>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan van der Ster <dan.vanderster@clyso.com>, Xiubo Li <xiubo.li@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791933643; l=1732;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=jswLlndUwvIJD4hLUM4C4P4iRpjAjyPosKHDox8DxEU=;
 b=8JJ8JcvUZQzt7nzZVNTxcXjwcrXcpJCqroeEPTbVRcNSOzIdoqN+DpeHohtKVb4Ux9Bt77Rqi
 0P1l8rGdoExAa7juMgvLxcIZ0wSPpZbcB4s/aSZniHSgaU5p/EARci4
X-Developer-Key: i=xiubo.li@clyso.com; a=ed25519;
 pk=V3NGr0AgAopiUhaLY51ipBkLN5LlcLhjOEfLEq1RoZ8=
X-Endpoint-Received: by B4 Relay for xiubo.li@clyso.com/20260625 with auth_id=840
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two problems in the client I/O metrics, reported by Dan van der Ster
while looking at IO500 runs on 144-core Grace clients.

Patch 1: metrics/size has reported 0 bytes for every page cache read
since buffered reads moved to CEPH_OSD_DATA_TYPE_ITER, because
finish_netfs_read() still reads osd_data->length, which only the page
vector type sets.

Patches 2-3: every OSD read and write completion updates the subvolume
metrics through state shared by the whole mount.  Even with subvolume
metrics disabled it bumped an atomic64 counter that nothing reads;
with them enabled it took a mount-wide spinlock and searched an rbtree.
Patch 2 drops the unused counters, patch 3 accumulates the counters in
a per-CPU slot and only folds them into the tree when the slot changes
subvolume or when the metrics are sent or dumped.

Tested on x86_64 against a main MDS with SUBVOLUME_METRICS: 16 jobs on
16 CPUs writing and reading two subvolumes and a plain directory.  The
read sizes are now reported, and the per-subvolume op and byte totals
summed over every metrics send match the I/O issued.

---
Xiubo Li (3):
      ceph: report the requested length in the netfs read metrics
      ceph: drop the unused subvolume metrics debug counters
      ceph: accumulate subvolume metrics per CPU

 fs/ceph/addr.c              |   2 +-
 fs/ceph/mds_client.c        |   6 +-
 fs/ceph/subvolume_metrics.c | 172 +++++++++++++++++++++++++++++++-------------
 fs/ceph/subvolume_metrics.h |  26 ++-----
 4 files changed, 133 insertions(+), 73 deletions(-)
---
base-commit: ed0502cb11f84fff29f374238e526ae94d9bdfde
change-id: 20261014-ceph-metrics-percpu-1cb5047f7150

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

