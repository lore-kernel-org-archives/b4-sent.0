From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 20 Jul 2026 17:25:13 -0700
Subject: [PATCH v3 10/13] WIP: Reproducer for allocation failure due to
 cgroup v2 memory limits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-hugetlb-alloc-failure-fixes-v3-10-7d2a169aa9ee@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784602387; l=7657;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=xlDHVWmQGlscLY1/vH8LU+p8GX41QLH6dh7Iau2jVGw=;
 b=pv1kHsyVab3V469NIs8r8t5Xu97t1OOkzogw/RCbJoFx5KM4tBpOxZYITemukdcxyGKrFYabG
 QV/4bwcsTqYDepVn6nKC1eniBcH5Toj295QFm8PkaHx229yv1ncKufR
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

(This reproducer was hacked up and not meant to be merged.)

cgroup_v2_allocation_failure.c triggers HugeTLB allocation failure by exploiting
cgroup v2 memory limits. This allows testing the error paths in the kernel when
memory control charging fails, even when physical huge pages are available.

The program performs the following steps to trigger the failure:

1. Enable hugetlb accounting in cgroup v2.
     + The program checks if memory_hugetlb_accounting is enabled in the cgroup2
       mount options. If not, it remounts /sys/fs/cgroup with this option
       enabled. This ensures that HugeTLB allocations are charged against the
       cgroup memory limits.

2. Create a test cgroup and set limits.
     + The program creates a new cgroup subdirectory named test_reproducer under
       /sys/fs/cgroup.
     + It sets the memory.max limit of this cgroup to 1MB (which is less than
       the 2MB huge page size).

3. Fork a child process and move it to the test cgroup.
     + The program forks a child process.
     + The child process moves itself into the test_reproducer cgroup by writing
       its PID (using 0 for current process) to cgroup.procs in the test cgroup
       directory.

4. Attempt to allocate and touch a 2MB huge page.
     + The child process maps a 2MB anonymous huge page using mmap with
       MAP_PRIVATE, MAP_ANONYMOUS, and MAP_HUGETLB.
     + The child process writes to the mapped address, triggering a page fault.

5. Triggering the kernel bugs.
     + The page fault handler calls alloc_hugetlb_folio to allocate the huge
       page.
     + The allocation of the physical page from buddy allocator succeeds
       (assuming nr_hugepages is sufficient).
     + The kernel then attempts to charge this allocation to the child process's
       cgroup by calling mem_cgroup_charge_hugetlb.
     + Since the child's cgroup memory limit is 1MB and the page is 2MB, the
       charge fails and mem_cgroup_charge_hugetlb returns -ENOMEM.
     + This triggers the error path in alloc_hugetlb_folio where the bugs (folio
       refcount mismatch, infinite loop on ENOMEM, and reservation leaks) are
       handled.
---
 cgroup_v2_allocation_failure.c | 160 +++++++++++++++++++++++++++++++++++++++++
 1 file changed, 160 insertions(+)

diff --git a/cgroup_v2_allocation_failure.c b/cgroup_v2_allocation_failure.c
new file mode 100644
index 0000000000000..938cbf02ae6f7
--- /dev/null
+++ b/cgroup_v2_allocation_failure.c
@@ -0,0 +1,160 @@
+#define _GNU_SOURCE
+#include <stdio.h>
+#include <stdlib.h>
+#include <unistd.h>
+#include <fcntl.h>
+#include <sys/mman.h>
+#include <sys/stat.h>
+#include <sys/types.h>
+#include <sys/wait.h>
+#include <string.h>
+#include <errno.h>
+
+#define CGROUP_PATH "/sys/fs/cgroup"
+#define TEST_CGROUP "test_reproducer"
+#define TEST_CGROUP_PATH CGROUP_PATH "/" TEST_CGROUP
+
+void write_file(const char *path, const char *val) {
+    int fd = open(path, O_WRONLY);
+    if (fd < 0) {
+        fprintf(stderr, "Failed to open %s: %s\n", path, strerror(errno));
+        exit(1);
+    }
+    if (write(fd, val, strlen(val)) < 0) {
+        fprintf(stderr, "Failed to write %s to %s: %s\n", val, path, strerror(errno));
+        close(fd);
+        exit(1);
+    }
+    close(fd);
+}
+
+int is_hugetlb_accounting_enabled() {
+    FILE *fp = fopen("/proc/mounts", "r");
+    if (!fp) {
+        perror("fopen /proc/mounts");
+        return -1;
+    }
+
+    char line[1024];
+    int enabled = 0;
+    while (fgets(line, sizeof(line), fp)) {
+        char spec[256], file[256], type[256], opts[512];
+        if (sscanf(line, "%255s %255s %255s %511s", spec, file, type, opts) == 4) {
+            if (strcmp(file, CGROUP_PATH) == 0 && strcmp(type, "cgroup2") == 0) {
+                if (strstr(opts, "memory_hugetlb_accounting") != NULL) {
+                    enabled = 1;
+                }
+                break;
+            }
+        }
+    }
+    fclose(fp);
+    return enabled;
+}
+
+int enable_hugetlb_accounting() {
+    printf("Attempting to remount cgroup2 with memory_hugetlb_accounting...\n");
+    int ret = system("mount -o remount,memory_hugetlb_accounting " CGROUP_PATH);
+    if (ret != 0) {
+        fprintf(stderr, "Failed to remount: system() returned %d\n", ret);
+        return -1;
+    }
+    return 0;
+}
+
+int main() {
+    struct stat st;
+    if (stat(CGROUP_PATH, &st) != 0 || !S_ISDIR(st.st_mode)) {
+        fprintf(stderr, "cgroup v2 not mounted at %s\n", CGROUP_PATH);
+        return 1;
+    }
+
+    int enabled = is_hugetlb_accounting_enabled();
+    if (enabled < 0) {
+        return 1;
+    }
+    if (!enabled) {
+        if (enable_hugetlb_accounting() != 0) {
+            fprintf(stderr, "Could not enable memory_hugetlb_accounting\n");
+            return 1;
+        }
+        // Re-check
+        enabled = is_hugetlb_accounting_enabled();
+        if (enabled <= 0) {
+            fprintf(stderr, "Failed to enable memory_hugetlb_accounting (re-check failed)\n");
+            return 1;
+        }
+        printf("Successfully enabled memory_hugetlb_accounting\n");
+    } else {
+        printf("memory_hugetlb_accounting is already enabled\n");
+    }
+
+    // Enable memory controller in subtree
+    int fd = open(CGROUP_PATH "/cgroup.subtree_control", O_WRONLY);
+    if (fd >= 0) {
+        if (write(fd, "+memory", 7) < 0) {
+            // Might fail if already enabled or not supported, ignore for now
+        }
+        close(fd);
+    }
+
+    if (mkdir(TEST_CGROUP_PATH, 0755) != 0) {
+        if (errno != EEXIST) {
+            perror("mkdir test_reproducer");
+            return 1;
+        }
+    }
+
+    // Set memory limit to 1MB (less than 2MB hugepage)
+    write_file(TEST_CGROUP_PATH "/memory.max", "1M");
+
+    pid_t pid = fork();
+    if (pid < 0) {
+        perror("fork");
+        return 1;
+    }
+
+    if (pid == 0) {
+        // Child
+        // Move to cgroup
+        write_file(TEST_CGROUP_PATH "/cgroup.procs", "0");
+
+        printf("Child: Attempting to allocate and touch 2MB hugepage...\n");
+        // Allocate 2MB hugepage
+        size_t size = 2 * 1024 * 1024;
+        void *addr = mmap(NULL, size, PROT_READ | PROT_WRITE,
+                          MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB, -1, 0);
+        if (addr == MAP_FAILED) {
+            perror("Child: mmap MAP_HUGETLB");
+            exit(1);
+        }
+
+        printf("Child: mmap succeeded at %p, touching it now (should trigger fault)...\n", addr);
+        // This should trigger the fault and call alloc_hugetlb_folio -> mem_cgroup_charge_hugetlb
+        // which should fail and trigger the bug.
+        *(volatile char *)addr = 1;
+
+        printf("Child: Successfully touched page (bug not triggered?).\n");
+        munmap(addr, size);
+        exit(0);
+    }
+
+    // Parent
+    int status;
+    waitpid(pid, &status, 0);
+
+    printf("Parent: Child exited. Cleaning up.\n");
+    rmdir(TEST_CGROUP_PATH);
+
+    if (WIFSIGNALED(status)) {
+        printf("Parent: Child killed by signal %d (%s)\n",
+               WTERMSIG(status), strsignal(WTERMSIG(status)));
+        if (WTERMSIG(status) == SIGBUS) {
+            printf("Parent: Child got SIGBUS as expected (if kernel didn't crash).\n");
+        }
+    } else if (WIFEXITED(status)) {
+        printf("Parent: Child exited with status %d\n", WEXITSTATUS(status));
+    }
+
+    return 0;
+}

-- 
2.55.0.229.g6434b31f56-goog

