From: Xiubo Li <xiubo.li@clyso.com>
Subject: [PATCH v2 0/4] ceph: fix the buffered read size metric and make
 the subvolume metrics per CPU
Date: Mon, 19 Oct 2026 13:33:26 +0200
Message-Id: <20261019-ceph-metrics-percpu-v2-0-1fa5229b00b8@clyso.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NSw6CQBAFr0J6bZuZkY9x5T0MC2gbaSPOZBqIh
 HB3AfcuK6lXbwblKKxwSWaIPIqKf6/gDglQW70fjHJfGZxxuTU2ReLQYsd9FFIMHCkMaKnOTFo
 0hc0MrMsQuZHPXr2VP9ahfjL1W2ozWtHex2m/He3m/X8YLRo8nSmrXNow5Xyl16T+SL6DclmWL
 1q2Tx3IAAAA
X-Change-ID: 20261014-ceph-metrics-percpu-1cb5047f7150
To: Ilya Dryomov <idryomov@gmail.com>, Alex Markuze <amarkuze@redhat.com>, 
 Xiubo Li <xiubo.li@clyso.com>, Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dan van der Ster <dan.vanderster@clyso.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792409634; l=3625;
 i=xiubo.li@clyso.com; s=20260625; h=from:subject:message-id;
 bh=vVnTRYzCIxXjqhYevgdB5gW6MuvRqOmBdio78LPOP4k=;
 b=jbqguYpXcDsTHT4x/xvUqUYpY9T36RaZdbs7ZEjNVRoSGkeduh4xh+RoGsNLPKW1Ap8ybnSUJ
 Ff0bhnealKdDHiZIVKhk3EIh0/adOQgEBpRo+2Sy992nAGvOFczAYmd
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

Patches 2-4: every OSD read and write completion updates the subvolume
metrics through state shared by the whole mount.  Even with subvolume
metrics disabled it bumped an atomic64 counter that nothing reads;
with them enabled it took a mount-wide spinlock and searched an rbtree.
Patch 2 drops the unused counters.  Patch 3 flushes the OSD completion
workqueue before the mds client and its metrics are freed.  Patch 4
accumulates the counters in a per-CPU slot and only folds them into the
tree when the slot changes subvolume or when the metrics are sent or
dumped.

Tested on a 12-vCPU x86_64 VM against a main MDS with SUBVOLUME_METRICS,
with KASAN, lockdep and kmemleak enabled:

- 12 fio jobs doing 4k direct I/O in one subvolume: the op and byte
  totals the MDS received over all metrics sends match what fio issued.
  Alternating between two subvolumes on every I/O, the MDS sees the
  same totals as with the unpatched client.
- The same with failslab failing half of the subvolume entry
  allocations: in one subvolume v1 lost about 9% of the ops and this
  version loses none; alternating between two subvolumes it drops 64
  of 240k I/Os, those whose direct insert failed as well.
- lock_stat over 20s of 12-job random reads in one subvolume:
  tracker->lock goes from 90k acquisitions and 78 contentions to 316
  and none; the per-CPU slot locks see no contention.
- umount -f with the OSDs paused and I/O in flight, and MDS failover
  and kill -9 under I/O: no KASAN, lockdep or kmemleak reports.  The
  race patch 3 closes was not hit there: all 3840 aborted requests
  completed before ceph_mdsc_destroy().

Throughput on that VM is unchanged within noise: at 12 vCPUs the
tracker lock is not a bottleneck, so the gain is only expected on
large clients like the ones in the report.

---
Changes in v2:
- Fold a per-CPU slot into the tree under the tracker lock and clear it
  only once its entry is in the tree, so its counters are kept when the
  entry allocation fails (Alex Markuze)
- New patch 3: flush osdc->completion_wq in ceph_mdsc_destroy() before
  the metrics are freed (Alex Markuze)
- Link to v1: https://patch.msgid.link/20261014-ceph-metrics-percpu-v1-0-38c5a24fec6e@clyso.com

To: Ilya Dryomov <idryomov@gmail.com>
To: Alex Markuze <amarkuze@redhat.com>
To: Xiubo Li <xiubo.li@clyso.com>
To: Viacheslav Dubeyko <slava@dubeyko.com>
Cc: ceph-devel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Xiubo Li (4):
      ceph: report the requested length in the netfs read metrics
      ceph: drop the unused subvolume metrics debug counters
      ceph: flush the OSD completions before destroying the mds client
      ceph: accumulate subvolume metrics per CPU

 fs/ceph/addr.c                  |   2 +-
 fs/ceph/mds_client.c            |   8 +-
 fs/ceph/subvolume_metrics.c     | 275 ++++++++++++++++++++++++++++------------
 fs/ceph/subvolume_metrics.h     |  26 +---
 include/linux/ceph/osd_client.h |   1 +
 net/ceph/osd_client.c           |  11 ++
 6 files changed, 217 insertions(+), 106 deletions(-)
---
base-commit: ed0502cb11f84fff29f374238e526ae94d9bdfde
change-id: 20261014-ceph-metrics-percpu-1cb5047f7150

Best regards,
--  
Xiubo Li <xiubo.li@clyso.com>

