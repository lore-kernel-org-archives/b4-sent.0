From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:15 -0700
Subject: [PATCH v3 12/13] WIP: Reproducer for false restoration on shared
 HugeTLB mappings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-12-7d2a169aa9ee@google.com>
References: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
In-Reply-To: <20260720-hugetlb-alloc-failure-fixes-v3-0-7d2a169aa9ee@google.com>
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Nhat Pham <nphamcs@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Peter Xu <peterx@redhat.com>, 
 Wupeng Ma <mawupeng1@huawei.com>, fvdl@google.com, rientjes@google.com, 
 jthoughton@google.com, Mike Kravetz <mike.kravetz@oracle.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>
Cc: vannapurve@google.com, erdemaktas@google.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, cgroups@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=7498;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=LHVH6iro3tu1LWvMV8EW8sUeU8cR100fPFYCaB/S9Ok=;
 b=oFS3CkZitpG+alLvyZpYlk3k8E2vLTClk7USUVHxwZULgXsGKKxJ5wYxunf0kfaIdDuqnt2Uz
 PLmIfYDnrhzAc+mzA9TR3qrqdQy11l2rm1O1H9SIo0pkl7ppy7gim/B
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

(This reproducer was hacked up and not meant to be merged.)

hugetlb_unreserve_pages() unconditionally returns reservations to the subpool
(via hugepage_subpool_put_pages()). This means that regardless of whether a
subpool reservation was actually used, the reservation is processed by the
subpool structure.

To create a false restoration, the reproducer performs these steps:

1.  Mount with min_size=2M (1 page). Global resv_hugepages becomes 1.
2.  The program maps 4MB (2 pages) shared (which also grows the file to
    4MB). Global resv_hugepages becomes 2 (1 from the mount, 1 new global
    reservation).
3.  The program populates only the first page. Global resv_hugepages decrements
    to 1 (reservation consumed by allocation).
4.  The program exits (closing VMAs/fds). For shared mappings, reservations are
    associated with the file inode, so they remain active. Global resv_hugepages
    remains 1.
5.  The script truncates the file to 2MB (truncate -s 2M).
    +   This synchronously triggers hugetlb_unreserve_pages() to release the
        reservation of the truncated range (the unallocated 2nd page).
    +   It calls hugepage_subpool_put_pages(spool, 1).
    +   On Vanilla Kernel (Buggy):
        +   used_hpages is 0 (not tracked).
        +   used_hpages (0) < min_hpages (1) is TRUE.
        +   The subpool incorrectly restores the reservation (spool->rsv_hpages
            becomes 1), even though Page 0 is still allocated and satisfies the
            mount's minimum guarantee.
        +   hugepage_subpool_put_pages() returns 0, skipping
            hugetlb_acct_memory(h, -1).
        +   Result: Global resv_hugepages remains stuck at 1 (Leak).
    +   On Fixed Kernel:
        +   used_hpages is tracked and is initially 2.
        +   hugepage_subpool_put_pages(1) decrements used_hpages to 1.
        +   used_hpages (1) < min_hpages (1) is FALSE.
        +   The subpool does not restore the reservation.
        +   hugepage_subpool_put_pages() returns 1.
        +   hugetlb_acct_memory(h, -1) is called.
        +   Result: Global resv_hugepages decrements to 0 (No leak).

When the filesystem is unmounted, hugetlbfs_put_super drops the subpool
reference. Since the filesystem is being unmounted, the reference count drops to
0, triggering unlock_or_release_subpool.

Inside unlock_or_release_subpool, the kernel checks if the subpool is free using
subpool_is_free.
+ On the buggy kernel, subpool_is_free checks if spool->rsv_hpages is equal to
  spool->min_hpages. Because of the phantom reservation, spool->rsv_hpages was
  restored to 1. Since min_hpages is 1, the check (1 == 1) returns true.
+ Since the subpool is considered free, the kernel releases the initial
  mount-time reservation by calling hugetlb_acct_memory to decrement
  resv_huge_pages by spool->min_hpages (which is 1).
+ This decrement reduces resv_huge_pages from 1 (the leaked state) to 0.

As a result, the leaked reservation is cleaned up during unmount and does not
persist afterward.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 subpool_shared_leak.c  | 29 +++++++++++++++++
 subpool_shared_leak.sh | 86 ++++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 115 insertions(+)

diff --git a/subpool_shared_leak.c b/subpool_shared_leak.c
new file mode 100644
index 0000000000000..5811e18d7f8be
--- /dev/null
+++ b/subpool_shared_leak.c
@@ -0,0 +1,29 @@
+#include <stdio.h>
+#include <stdlib.h>
+#include <unistd.h>
+#include <sys/mman.h>
+#include <sys/stat.h>
+#include <fcntl.h>
+
+#define HPAGE_SIZE (2 * 1024 * 1024)
+
+int main(int argc, char **argv) {
+    if (argc < 2) {
+        fprintf(stderr, "Usage: %s <file_path>\n", argv[0]);
+        return 1;
+    }
+    const char *file_path = argv[1];
+
+    int fd = open(file_path, O_CREAT | O_RDWR, 0666);
+    if (fd < 0) { perror("open"); return 1; }
+
+    void *addr = mmap(NULL, 2 * HPAGE_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
+    if (addr == MAP_FAILED) { perror("mmap"); close(fd); return 1; }
+
+    *(volatile char *)addr = 1; // Allocate 1st page only. 2nd page remains unallocated (but reserved).
+
+    munmap(addr, 2 * HPAGE_SIZE);
+    close(fd);
+
+    return 0;
+}
diff --git a/subpool_shared_leak.sh b/subpool_shared_leak.sh
new file mode 100755
index 0000000000000..46c622b18559a
--- /dev/null
+++ b/subpool_shared_leak.sh
@@ -0,0 +1,86 @@
+#!/bin/bash
+
+if [ "$EUID" -ne 0 ]; then
+    echo "Please run as root"
+    exit 1
+fi
+
+MNT_PATH="/tmp/mnt_hugetlb_shared_leak"
+FILE_PATH="$MNT_PATH/test_file"
+
+# Save original values
+orig_nr=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages)
+
+cleanup() {
+    echo "Cleaning up..."
+    rm -f "$FILE_PATH"
+    umount "$MNT_PATH" 2>/dev/null
+    rmdir "$MNT_PATH" 2>/dev/null
+    echo "$orig_nr" > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
+    echo "Cleanup done."
+}
+trap cleanup EXIT
+
+# 1. Set nr_hugepages to 2
+echo 2 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
+
+# 2. Mount hugetlbfs with min_size=2M (1 page)
+mkdir -p "$MNT_PATH"
+if ! mount -t hugetlbfs -o min_size=2M none "$MNT_PATH"; then
+    echo "Failed to mount hugetlbfs"
+    exit 1
+fi
+
+# Check resv_hugepages after mount (should be 1)
+initial_resv=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/resv_hugepages)
+echo "Initial resv_hugepages (after mount): $initial_resv"
+if [ "$initial_resv" -ne 1 ]; then
+    echo "ERROR: Initial resv_hugepages is not 1!"
+    exit 1
+fi
+
+# Verify reproducer binary exists
+if [ ! -x ./subpool_shared_leak ]; then
+    echo "reproducer binary './subpool_shared_leak' not found or not executable."
+    echo "Please compile it first: gcc -static -o subpool_shared_leak subpool_shared_leak.c"
+    exit 1
+fi
+
+# 3. Run helper to map 4MB, allocate 2MB, and close.
+# This creates 2 reservations, consumes 1 (by allocating Page 0).
+# The unallocated Page 1 reservation remains active in the inode's resv_map.
+echo "Running helper..."
+./subpool_shared_leak "$FILE_PATH"
+
+resv_after_helper=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/resv_hugepages)
+echo "resv_hugepages after helper (should be 1): $resv_after_helper"
+# Page 0 is allocated (no longer reserved). Page 1 is reserved.
+# So resv_hugepages should be 1.
+if [ "$resv_after_helper" -ne 1 ]; then
+    echo "ERROR: resv_hugepages is not 1 after helper run!"
+    exit 1
+fi
+
+# 4. Truncate file to 2MB (releases Page 1 reservation)
+echo "Truncating file to 2MB (releasing 1 page reservation)..."
+truncate -s 2M "$FILE_PATH"
+
+# Check resv_hugepages after truncate.
+# Since Page 0 is still allocated (and in page cache), and satisfies the
+# min_size=2M guarantee, we should have 0 reservations remaining.
+# If the bug is present, the truncate path will incorrectly restore the
+# reservation to the subpool and skip releasing it globally, leaving
+# resv_hugepages at 1.
+final_resv=$(cat /sys/kernel/mm/hugepages/hugepages-2048kB/resv_hugepages)
+echo "Final resv_hugepages (after 2MB truncate): $final_resv"
+
+if [ "$final_resv" -eq 1 ]; then
+    echo "RESULT: LEAK DETECTED (FAIL)"
+    exit 1
+elif [ "$final_resv" -eq 0 ]; then
+    echo "RESULT: NO LEAK (PASS)"
+    exit 0
+else
+    echo "RESULT: UNEXPECTED STATE ($final_resv)"
+    exit 2
+fi

-- 
2.55.0.229.g6434b31f56-goog

