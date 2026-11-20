From: "Gregory Price (Meta)" <gourry@gourry.net>
Date: Fri, 20 Nov 2026 13:09:49 -0500
Subject: [PATCH 58/60] selftests/dax: test memory policy on private nodes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-private_nodes_v6-v1-58-74f5f9a115c2@gourry.net>
References: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
In-Reply-To: <20261120-private_nodes_v6-v1-0-74f5f9a115c2@gourry.net>
To: Yury Norov <yury.norov@gmail.com>, 
 Rasmus Villemoes <linux@rasmusvillemoes.dk>, 
 David Hildenbrand <david@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Michal Hocko <mhocko@suse.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Oscar Salvador <osalvador@suse.de>, Johannes Weiner <hannes@cmpxchg.org>, 
 Suren Baghdasaryan <surenb@google.com>, 
 Brendan Jackman <brendan.jackman@linux.dev>, Zi Yan <ziy@nvidia.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Johan Hovold <johan@kernel.org>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Matthew Brost <matthew.brost@intel.com>, Byungchul Park <byungchul@sk.com>, 
 Alistair Popple <apopple@nvidia.com>, SJ Park <sj@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Barry Song <baohua@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Michal Hocko <mhocko@kernel.org>, David Rientjes <rientjes@google.com>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Xu Xin <xu.xin@linux.dev>, Chengming Zhou <chengming.zhou@linux.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, Pedro Falcato <pfalcato@suse.de>, 
 Jann Horn <jannh@google.com>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Youngjun Park <youngjun.park@lge.com>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Waiman Long <longman@redhat.com>, Ridong Chen <ridong.chen@linux.dev>, 
 Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Dan Williams <djbw@kernel.org>, Vishal Verma <vishal.l.verma@intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, 
 Alison Schofield <alison.schofield@intel.com>, 
 Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 linux-cxl@vger.kernel.org, linux-doc@vger.kernel.org, 
 driver-core@lists.linux.dev, damon@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 cgroups@vger.kernel.org, nvdimm@lists.linux.dev, 
 linux-kselftest@vger.kernel.org, "Gregory Price (Meta)" <gourry@gourry.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795198154; l=24841;
 i=gourry@gourry.net; s=20261120; h=from:subject:message-id;
 bh=TVkO3GwJ3kh7qlGFMS/WBZp+U7Dx4lFdHzMJui1AVa8=;
 b=7BhNun0jABqPgycL8r7uaJPI7XVSq9N0uLZlcZQBgM44Tv4Q1OZQup+grwby3JwK/1NV7X/83
 xD2UVfJkbZID/lnaMTIxCjTy8wR0VhrJS63Fg3t7qlOkhWRyQoDogVc
X-Developer-Key: i=gourry@gourry.net; a=ed25519;
 pk=BZWDlx4htkR5KcvGjGtSDfx1tM0E5dlyBR43FEhjWVc=
X-Endpoint-Received: by B4 Relay for gourry@gourry.net/20261120 with auth_id=1586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test the userspace interfaces for private memory with
kmem_private_policy_tool, which reports KTAP results:
  - MPOL_F_PRIVATE_NODES: mbind() binds one private node and
    get_mempolicy() reports the flag, while set_mempolicy(), other
    modes and flags, other masks and HugeTLB mappings are rejected.
  - unflagged, relative and static masks naming the private node use
    only common memory.
  - move_pages() and migrate_pages() move pages to and from the node.
  - reclaim: MADV_PAGEOUT, and node and memcg reclaim splitting
    partially mapped THPs.
  - exhausting private memory fails the fault with SIGBUS and leaves
    another task on the node alone. The test forks the faulting tasks.

Raise the dax selftest timeout to 300 seconds; the policy test faults in
node-sized buffers.

Run with DAX_KMEM_TEST_DEV=<daxX.Y|auto>.

Signed-off-by: Gregory Price (Meta) <gourry@gourry.net>
---
 tools/testing/selftests/dax/.gitignore             |   2 +
 tools/testing/selftests/dax/Makefile               |   4 +
 tools/testing/selftests/dax/config                 |   3 +
 tools/testing/selftests/dax/kmem_private_policy.sh |  58 ++
 .../selftests/dax/kmem_private_policy_tool.c       | 620 +++++++++++++++++++++
 tools/testing/selftests/dax/private_node_common.sh |  28 +
 tools/testing/selftests/dax/settings               |   2 +-
 7 files changed, 716 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/dax/.gitignore b/tools/testing/selftests/dax/.gitignore
new file mode 100644
index 000000000000..fce2950a4e05
--- /dev/null
+++ b/tools/testing/selftests/dax/.gitignore
@@ -0,0 +1,2 @@
+# SPDX-License-Identifier: GPL-2.0-only
+kmem_private_policy_tool
diff --git a/tools/testing/selftests/dax/Makefile b/tools/testing/selftests/dax/Makefile
index 55d2ba0de8d9..26473b640a4c 100644
--- a/tools/testing/selftests/dax/Makefile
+++ b/tools/testing/selftests/dax/Makefile
@@ -4,6 +4,10 @@ all:
 TEST_PROGS := dax-kmem-hotplug.sh
 TEST_PROGS += kmem_private.sh
 TEST_PROGS += kmem_private_services.sh
+TEST_PROGS += kmem_private_policy.sh
 TEST_FILES := private_node_common.sh
+TEST_GEN_FILES := kmem_private_policy_tool
+
+CFLAGS += -Wall $(KHDR_INCLUDES)
 
 include ../lib.mk
diff --git a/tools/testing/selftests/dax/config b/tools/testing/selftests/dax/config
index 42853ed9e99f..5436c4a195c8 100644
--- a/tools/testing/selftests/dax/config
+++ b/tools/testing/selftests/dax/config
@@ -4,3 +4,6 @@ CONFIG_MEMORY_HOTPLUG=y
 CONFIG_MEMORY_HOTREMOVE=y
 CONFIG_NUMA=y
 CONFIG_COMPACTION=y
+CONFIG_MIGRATION=y
+CONFIG_MEMCG=y
+CONFIG_TRANSPARENT_HUGEPAGE=y
diff --git a/tools/testing/selftests/dax/kmem_private_policy.sh b/tools/testing/selftests/dax/kmem_private_policy.sh
new file mode 100755
index 000000000000..98727927ea25
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_policy.sh
@@ -0,0 +1,58 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Check memory policy, migration, reclaim and exhaustion on private kmem
+# memory. The checks live in kmem_private_policy_tool, which reports the
+# KTAP plan and results.
+#
+# Needs root, DAX_KMEM_TEST_DEV=<daxX.Y|auto> (see private_node_common.sh)
+# and one common memory node. A memoryless node, swap and a cgroup-v2 memory
+# controller enable a few more checks.
+
+# shellcheck disable=SC1091
+DIR="$(dirname "$(readlink -f "$0")")"
+. "$DIR"/../kselftest/ktap_helpers.sh
+. "$DIR"/private_node_common.sh
+
+TOOL="$DIR/kmem_private_policy_tool"
+CG="$CGROOT/kmem-private-policy-$$"
+
+# shellcheck disable=SC2317 # invoked by the EXIT trap
+cleanup()
+{
+	[ -d "$CG" ] && rmdir "$CG" 2>/dev/null
+	if [ -n "${MEMCG_ENABLED:-}" ]; then
+		echo -memory > "$CGROOT/cgroup.subtree_control" 2>/dev/null
+	fi
+	pn_unbind_kmem_private
+}
+trap cleanup EXIT
+
+pn_setup
+[ -x "$TOOL" ] || pn_skip "kmem_private_policy_tool not built"
+pn_find_common_nodes 1
+pn_require_mask_nodes "$PN" "${COMMON[0]}"
+
+# A memoryless node lets the tool check that a private binding names one node.
+MEMLESS=
+possible=$(cat "$NODE_BASE/possible")
+for ((nid = 0; nid < $(getconf LONG_BIT); nid++)); do
+	pn_nodelist_has "$possible" "$nid" || continue
+	pn_node_in "$nid" has_memory && continue
+	MEMLESS=$nid
+	break
+done
+
+# memcg reclaim needs the tool in a non-root memory cgroup.
+CG_PROCS=/dev/null
+if [ "$(stat -fc %T "$CGROOT" 2>/dev/null)" = cgroup2fs ] &&
+   grep -qw memory "$CGROOT/cgroup.controllers" 2>/dev/null; then
+	if ! grep -qw memory "$CGROOT/cgroup.subtree_control" &&
+	   echo +memory > "$CGROOT/cgroup.subtree_control" 2>/dev/null; then
+		MEMCG_ENABLED=1
+	fi
+	mkdir "$CG" 2>/dev/null && CG_PROCS="$CG/cgroup.procs"
+fi
+
+# An empty MEMLESS omits the optional argument.
+sh -c "echo \$\$ > '$CG_PROCS'; exec '$TOOL' '$PN' '${COMMON[0]}' $MEMLESS"
diff --git a/tools/testing/selftests/dax/kmem_private_policy_tool.c b/tools/testing/selftests/dax/kmem_private_policy_tool.c
new file mode 100644
index 000000000000..0769436b6068
--- /dev/null
+++ b/tools/testing/selftests/dax/kmem_private_policy_tool.c
@@ -0,0 +1,620 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Memory policy, migration, reclaim and exhaustion on a private memory node,
+ * reported as KTAP results. kmem_private_policy.sh prints the KTAP header,
+ * provisions the node and runs:
+ *
+ *   kmem_private_policy_tool <private-nid> <common-nid> [memoryless-nid]
+ */
+#define _GNU_SOURCE
+#include <errno.h>
+#include <linux/mempolicy.h>
+#include <poll.h>
+#include <signal.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <sys/syscall.h>
+#include <sys/wait.h>
+#include <time.h>
+#include <unistd.h>
+
+#include "../kselftest.h"
+
+#ifndef MLOCK_ONFAULT
+#define MLOCK_ONFAULT 1
+#endif
+
+#ifndef MPOL_F_PRIVATE_NODES
+#define MPOL_F_PRIVATE_NODES (1 << 12)
+#endif
+
+#define NR_PAGES 64
+#define PATTERN 0xab
+#define NR_THPS 8
+/* The kernel reads maxnode - 1 bits. */
+#define MAXNODE (8 * sizeof(unsigned long) + 1)
+
+enum { FAIL, PASS, SKIP };
+
+static long page_size;
+static size_t huge_len;
+
+static void report(int result, const char *name)
+{
+	if (result == SKIP)
+		ksft_test_result_skip("%s\n", name);
+	else
+		ksft_test_result(result == PASS, "%s\n", name);
+}
+
+static void *anon_map(size_t len)
+{
+	void *ptr = mmap(NULL, len, PROT_READ | PROT_WRITE,
+			 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+
+	return ptr == MAP_FAILED ? NULL : ptr;
+}
+
+/* How many of the @nr pages at @addr are on @nid, by a move_pages() query. */
+static long pages_on_node(void *addr, long nr, int nid)
+{
+	void **pages = calloc(nr, sizeof(*pages));
+	int *status = calloc(nr, sizeof(*status));
+	long i, count = -1;
+
+	if (pages && status) {
+		for (i = 0; i < nr; i++)
+			pages[i] = addr + i * page_size;
+		if (!syscall(SYS_move_pages, 0, nr, pages, NULL, status, 0UL)) {
+			count = 0;
+			for (i = 0; i < nr; i++)
+				count += status[i] == nid;
+		}
+	}
+	free(pages);
+	free(status);
+	return count;
+}
+
+static long mbind_mask(void *addr, size_t len, int mode, unsigned long mask)
+{
+	return syscall(SYS_mbind, addr, len, mode, &mask, MAXNODE, 0UL);
+}
+
+static long bind_private(void *addr, size_t len, int nid)
+{
+	return mbind_mask(addr, len, MPOL_BIND | MPOL_F_PRIVATE_NODES,
+			  1UL << nid);
+}
+
+static int rejected(long rc)
+{
+	return rc == -1 && errno == EINVAL;
+}
+
+static long read_long(const char *path)
+{
+	FILE *file = fopen(path, "r");
+	long val = -1;
+
+	if (file) {
+		if (fscanf(file, "%ld", &val) != 1)
+			val = -1;
+		fclose(file);
+	}
+	return val;
+}
+
+/* A field of /sys/devices/system/node/node<nid>/meminfo, in kB. */
+static long node_meminfo(int nid, const char *field)
+{
+	char path[64], line[256], key[64];
+	FILE *file;
+	long val = -1;
+
+	snprintf(path, sizeof(path), "/sys/devices/system/node/node%d/meminfo",
+		 nid);
+	snprintf(key, sizeof(key), " %s:", field);
+	file = fopen(path, "r");
+	if (!file)
+		return -1;
+	while (fgets(line, sizeof(line), file)) {
+		char *pos = strstr(line, key);
+
+		if (pos) {
+			val = atol(pos + strlen(key));
+			break;
+		}
+	}
+	fclose(file);
+	return val;
+}
+
+static int thp_disabled(void)
+{
+	char mode[128] = "";
+	FILE *file = fopen("/sys/kernel/mm/transparent_hugepage/enabled", "r");
+
+	if (!file)
+		return 1;
+	if (!fgets(mode, sizeof(mode), file))
+		mode[0] = '\0';
+	fclose(file);
+	return strstr(mode, "[never]") != NULL;
+}
+
+/*
+ * Reclaim through @path splits partially unmapped THPs on a private node,
+ * returning the unmapped subpages.
+ */
+static int thp_split_reclaimed(int nid, const char *path)
+{
+	size_t len = NR_THPS * huge_len;
+	char stat[256], *map, *buf;
+	long before, partial;
+	FILE *file;
+	int i;
+
+	if (!huge_len)
+		return SKIP;
+	snprintf(stat, sizeof(stat),
+		 "/sys/kernel/mm/transparent_hugepage/hugepages-%zukB/stats/nr_anon_partially_mapped",
+		 huge_len >> 10);
+	before = read_long(stat);
+	if (before < 0)
+		return SKIP;
+	map = anon_map(len + huge_len);
+	if (!map)
+		return FAIL;
+	buf = (char *)(((unsigned long)map + huge_len - 1) & ~(huge_len - 1));
+	if (madvise(buf, len, MADV_HUGEPAGE) || bind_private(buf, len, nid)) {
+		munmap(map, len + huge_len);
+		return SKIP;
+	}
+	memset(buf, PATTERN, len);
+	if (pages_on_node(buf, len / page_size, nid) !=
+	    (long)(len / page_size)) {
+		munmap(map, len + huge_len);
+		return FAIL;
+	}
+	for (i = 0; i < NR_THPS; i++)
+		madvise(buf + i * huge_len + huge_len / 2, huge_len / 2,
+			MADV_DONTNEED);
+
+	/* With THP enabled, a private binding must get its THPs. */
+	partial = read_long(stat) - before;
+	if (partial < NR_THPS) {
+		munmap(map, len + huge_len);
+		return thp_disabled() ? SKIP : FAIL;
+	}
+	file = fopen(path, "w");
+	if (file) {
+		fputs("64M", file);
+		fclose(file);
+	}
+	partial = read_long(stat) - before;
+	munmap(map, len + huge_len);
+	return partial <= NR_THPS / 4 ? PASS : FAIL;
+}
+
+static int swap_active(void)
+{
+	char line[256];
+	FILE *file = fopen("/proc/swaps", "r");
+	int lines = 0;
+
+	if (!file)
+		return 0;
+	while (fgets(line, sizeof(line), file))
+		lines++;
+	fclose(file);
+	return lines > 1;
+}
+
+/* Reclaim advice pages out private memory, given active swap. */
+static int pageout_acts(void *addr, size_t len, int nid)
+{
+	if (!swap_active())
+		return SKIP;
+	if (bind_private(addr, len, nid))
+		return FAIL;
+	memset(addr, PATTERN, len);
+	if (pages_on_node(addr, NR_PAGES, nid) != NR_PAGES ||
+	    madvise(addr, len, MADV_PAGEOUT))
+		return FAIL;
+	/* Reclaim may skip a few pages, for example ones still in a batch. */
+	return pages_on_node(addr, NR_PAGES, nid) <= NR_PAGES / 4 ? PASS : FAIL;
+}
+
+/* Find memory.reclaim of the non-root cgroup this task runs in. */
+static int memcg_reclaim_path(char *path, size_t size)
+{
+	/* Short enough that the memory.reclaim path always fits @path. */
+	char line[2048], *cgroup = NULL;
+	FILE *file = fopen("/proc/self/cgroup", "r");
+
+	if (!file)
+		return 0;
+	while (fgets(line, sizeof(line), file)) {
+		if (!strncmp(line, "0::/", 4)) {
+			line[strcspn(line, "\n")] = 0;
+			cgroup = line + 3;
+			break;
+		}
+	}
+	fclose(file);
+	if (!cgroup || !strcmp(cgroup, "/"))
+		return 0;
+	snprintf(path, size, "/sys/fs/cgroup%s/memory.reclaim", cgroup);
+	return !access(path, W_OK);
+}
+
+/*
+ * A relative or static policy whose mask names the private node must still
+ * place memory on common nodes, and keep the user's mask.
+ */
+static int common_policy(void *addr, size_t len, int nid, int requested_mode,
+			 unsigned long mask, int task_policy)
+{
+	unsigned long reported = 0;
+	int mode = 0;
+	long rc;
+
+	if (task_policy) {
+		if (syscall(SYS_mbind, addr, len, MPOL_DEFAULT, NULL, 0UL, 0UL))
+			return FAIL;
+		rc = syscall(SYS_set_mempolicy, requested_mode, &mask, MAXNODE);
+	} else {
+		rc = mbind_mask(addr, len, requested_mode, mask);
+	}
+	if (rc)
+		return FAIL;
+
+	rc = syscall(SYS_get_mempolicy, &mode, &reported, MAXNODE,
+		     task_policy ? NULL : addr, task_policy ? 0 : MPOL_F_ADDR);
+	if (task_policy)
+		syscall(SYS_set_mempolicy, MPOL_DEFAULT, NULL, 0UL);
+	if (rc || mode != requested_mode || reported != mask ||
+	    madvise(addr, len, MADV_DONTNEED))
+		return FAIL;
+	memset(addr, PATTERN, len);
+	return pages_on_node(addr, NR_PAGES, nid) == 0 ? PASS : FAIL;
+}
+
+/* The flag binds exactly one private node and excludes the other modes. */
+static int private_flag_validated(void *addr, size_t len,
+				  unsigned long private_mask,
+				  unsigned long common_mask)
+{
+	const struct {
+		int mode;
+		unsigned long mask;
+	} cases[] = {
+		{ MPOL_BIND | MPOL_F_PRIVATE_NODES | MPOL_F_STATIC_NODES,
+		  private_mask },
+		{ MPOL_BIND | MPOL_F_PRIVATE_NODES | MPOL_F_RELATIVE_NODES,
+		  private_mask },
+		{ MPOL_BIND | MPOL_F_PRIVATE_NODES | MPOL_F_NUMA_BALANCING,
+		  private_mask },
+		{ MPOL_PREFERRED | MPOL_F_PRIVATE_NODES, private_mask },
+		{ MPOL_BIND | MPOL_F_PRIVATE_NODES, common_mask },
+		{ MPOL_BIND | MPOL_F_PRIVATE_NODES, private_mask | common_mask },
+	};
+	size_t i;
+
+	for (i = 0; i < ARRAY_SIZE(cases); i++) {
+		errno = 0;
+		if (!rejected(mbind_mask(addr, len, cases[i].mode,
+					 cases[i].mask)))
+			return FAIL;
+	}
+	return PASS;
+}
+
+/* Run @fn in a child, so its effects on this process do not leak. */
+static int in_child(int (*fn)(int), int nid)
+{
+	int status;
+	pid_t pid = fork();
+
+	if (pid < 0)
+		return FAIL;
+	if (!pid)
+		_exit(fn(nid));
+	if (waitpid(pid, &status, 0) != pid || !WIFEXITED(status))
+		return FAIL;
+	return WEXITSTATUS(status);
+}
+
+/* migrate_pages(2) moves a task's pages onto the private node. */
+static int migrate_to_private(int nid)
+{
+	unsigned long old_nodes, new_nodes = 1UL << nid;
+	char *addr = anon_map(NR_PAGES * page_size);
+	void *page;
+	int status;
+
+	if (!addr)
+		return FAIL;
+	memset(addr, PATTERN, NR_PAGES * page_size);
+	page = addr;
+	if (syscall(SYS_move_pages, 0, 1UL, &page, NULL, &status, 0UL) ||
+	    status < 0 || status == nid)
+		return FAIL;
+	old_nodes = 1UL << status;
+	if (syscall(SYS_migrate_pages, 0, MAXNODE, &old_nodes, &new_nodes) < 0)
+		return FAIL;
+	return pages_on_node(addr, NR_PAGES, nid) >= NR_PAGES * 3 / 4 ?
+	       PASS : FAIL;
+}
+
+static double now(void)
+{
+	struct timespec ts;
+
+	clock_gettime(CLOCK_MONOTONIC, &ts);
+	return ts.tv_sec + ts.tv_nsec / 1e9;
+}
+
+/*
+ * Fork a child that faults @kb of locked memory bound to the private node,
+ * so that reclaim cannot make room, then writes to @ready and sleeps.
+ */
+static pid_t start_faulter(int nid, long kb, int ready)
+{
+	size_t len = (size_t)kb << 10, off;
+	char *addr;
+	pid_t pid;
+
+	pid = fork();
+	if (pid)
+		return pid;
+	addr = mmap(NULL, len, PROT_READ | PROT_WRITE,
+		    MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
+	if (addr == MAP_FAILED || bind_private(addr, len, nid) ||
+	    madvise(addr, len, MADV_NOHUGEPAGE) ||
+	    syscall(SYS_mlock2, addr, len, MLOCK_ONFAULT))
+		_exit(2);
+	for (off = 0; off < len; off += page_size)
+		addr[off] = 1;
+	if (write(ready, "", 1) != 1)
+		_exit(2);
+	pause();
+	_exit(0);
+}
+
+/* Wait up to @secs for a faulter to write to @ready. */
+static int faulter_ready(int ready, int secs)
+{
+	struct pollfd pfd = { .fd = ready, .events = POLLIN };
+	char byte;
+
+	return poll(&pfd, 1, secs * 1000) == 1 && read(ready, &byte, 1) == 1;
+}
+
+/* Wait up to @secs for @pid to exit and return its status, or -1. */
+static int wait_exit(pid_t pid, double secs)
+{
+	double end = now() + secs;
+	int status;
+
+	do {
+		if (waitpid(pid, &status, WNOHANG) == pid)
+			return status;
+		usleep(100000);
+	} while (now() < end);
+	return -1;
+}
+
+static int alive(pid_t pid)
+{
+	return waitpid(pid, NULL, WNOHANG) == 0;
+}
+
+static void stop(pid_t pid)
+{
+	kill(pid, SIGKILL);
+	waitpid(pid, NULL, 0);
+}
+
+/*
+ * Exhausting private memory fails the fault with SIGBUS, as an exhausted
+ * HugeTLB pool does, and leaves other tasks on the node alone.
+ */
+static void private_exhaustion(int nid)
+{
+	const char *name = "exhausting private memory fails the fault with SIGBUS";
+	long free_kb = node_meminfo(nid, "MemFree");
+	long total_kb = node_meminfo(nid, "MemTotal");
+	int pipefd[2], status = -1, result = FAIL;
+	pid_t holder, faulter;
+
+	/* Strict overcommit refuses the oversized mapping before it faults. */
+	if (read_long("/proc/sys/vm/overcommit_memory") == 2) {
+		report(SKIP, name);
+		return;
+	}
+	if (free_kb <= 0 || total_kb <= 0 || pipe(pipefd)) {
+		report(FAIL, name);
+		return;
+	}
+
+	/* Another task holding memory on the node must be left alone. */
+	holder = start_faulter(nid, free_kb * 6 / 10, pipefd[1]);
+	if (holder > 0 && faulter_ready(pipefd[0], 60)) {
+		faulter = start_faulter(nid, total_kb * 2, pipefd[1]);
+		if (faulter > 0) {
+			status = wait_exit(faulter, 60);
+			if (status == -1)
+				stop(faulter);
+		}
+		if (status != -1 && WIFSIGNALED(status) &&
+		    WTERMSIG(status) == SIGBUS && alive(holder))
+			result = PASS;
+	}
+	report(result, name);
+
+	if (holder > 0)
+		stop(holder);
+	close(pipefd[0]);
+	close(pipefd[1]);
+}
+
+int main(int argc, char **argv)
+{
+	unsigned long private_mask, common_mask, mixed_mask, allowed = 0;
+	void *ordinary, *bound, *probe, *mixed, *paged, *huge;
+	int nid, common, memless = -1, mode, status, result;
+	char path[4096];
+	void *pages[1];
+	int nodes[1];
+	long len, rc;
+
+	if (argc != 3 && argc != 4)
+		ksft_exit_fail_msg("usage: %s <private-nid> <common-nid> [memoryless-nid]\n",
+				   argv[0]);
+	nid = atoi(argv[1]);
+	common = atoi(argv[2]);
+	if (argc == 4)
+		memless = atoi(argv[3]);
+
+	page_size = sysconf(_SC_PAGESIZE);
+	rc = read_long("/sys/kernel/mm/transparent_hugepage/hpage_pmd_size");
+	huge_len = rc > 0 ? rc : 0;
+	len = NR_PAGES * page_size;
+	private_mask = 1UL << nid;
+	common_mask = 1UL << common;
+	mixed_mask = private_mask | common_mask;
+
+	ordinary = anon_map(len);
+	bound = anon_map(len);
+	probe = anon_map(len);
+	mixed = anon_map(len);
+	paged = anon_map(len);
+	if (!ordinary || !bound || !probe || !mixed || !paged)
+		ksft_exit_fail_msg("mmap failed\n");
+
+	ksft_set_plan(20);
+
+	memset(ordinary, PATTERN, len);
+	report(pages_on_node(ordinary, NR_PAGES, nid) == 0 ? PASS : FAIL,
+	       "ordinary allocation stays off private memory");
+
+	rc = syscall(SYS_get_mempolicy, &mode, &allowed, MAXNODE, NULL,
+		     MPOL_F_MEMS_ALLOWED);
+	report(!rc && (allowed & private_mask) ? PASS : FAIL,
+	       "mems_allowed reports the private node");
+
+	errno = 0;
+	rc = syscall(SYS_set_mempolicy, MPOL_BIND | MPOL_F_PRIVATE_NODES,
+		     &private_mask, MAXNODE);
+	report(rejected(rc) ? PASS : FAIL,
+	       "set_mempolicy() rejects MPOL_F_PRIVATE_NODES");
+	syscall(SYS_set_mempolicy, MPOL_DEFAULT, NULL, 0UL);
+
+	rc = bind_private(bound, len, nid);
+	memset(bound, PATTERN, len);
+	report(!rc && pages_on_node(bound, NR_PAGES, nid) == NR_PAGES &&
+	       pages_on_node(bound, NR_PAGES, common) == 0 ? PASS : FAIL,
+	       "a private binding places memory on the private node");
+
+	mode = 0;
+	rc = syscall(SYS_get_mempolicy, &mode, NULL, 0UL, bound, MPOL_F_ADDR);
+	report(!rc && mode == (MPOL_BIND | MPOL_F_PRIVATE_NODES) ? PASS : FAIL,
+	       "get_mempolicy() reports MPOL_F_PRIVATE_NODES");
+
+	/* A mixed mask is an ordinary binding narrowed to common memory. */
+	rc = mbind_mask(mixed, len, MPOL_BIND, mixed_mask);
+	memset(mixed, PATTERN, len);
+	report(!rc && pages_on_node(mixed, NR_PAGES, common) == NR_PAGES ?
+	       PASS : FAIL,
+	       "an unflagged mixed mask uses only common memory");
+
+	/* Without the flag, a private-only mask has no usable node. */
+	errno = 0;
+	report(rejected(mbind_mask(probe, len, MPOL_BIND, private_mask)) ?
+	       PASS : FAIL, "an unflagged private-only mask is rejected");
+
+	report(private_flag_validated(probe, len, private_mask, common_mask),
+	       "MPOL_F_PRIVATE_NODES rejects other modes, flags and masks");
+
+	/* Adding a memoryless node to a private binding must fail. */
+	if (memless < 0) {
+		result = SKIP;
+	} else {
+		errno = 0;
+		result = rejected(mbind_mask(probe, len,
+					     MPOL_BIND | MPOL_F_PRIVATE_NODES,
+					     private_mask | (1UL << memless))) ?
+			 PASS : FAIL;
+	}
+	report(result, "a private binding names exactly one node");
+
+	/* Private nodes cannot hold HugeTLB pages. */
+	huge = huge_len ? mmap(NULL, huge_len, PROT_READ | PROT_WRITE,
+			       MAP_PRIVATE | MAP_ANONYMOUS | MAP_HUGETLB |
+			       MAP_NORESERVE, -1, 0) : MAP_FAILED;
+	if (huge == MAP_FAILED) {
+		result = SKIP;
+	} else {
+		errno = 0;
+		result = rejected(bind_private(huge, huge_len, nid)) ?
+			 PASS : FAIL;
+		munmap(huge, huge_len);
+	}
+	report(result, "a private binding on HugeTLB memory is rejected");
+
+	/* Relative bits are positions in the common-node set, not node IDs. */
+	report(common_policy(probe, len, nid, MPOL_BIND | MPOL_F_RELATIVE_NODES,
+			     private_mask, 1),
+	       "a relative task policy stays on common memory");
+	report(common_policy(probe, len, nid, MPOL_BIND | MPOL_F_RELATIVE_NODES,
+			     private_mask, 0),
+	       "a relative binding stays on common memory");
+	/* Filtering the effective policy must not alter its user mask. */
+	report(common_policy(probe, len, nid, MPOL_BIND | MPOL_F_STATIC_NODES,
+			     mixed_mask, 1),
+	       "a static task policy keeps its mask and uses common memory");
+
+	pages[0] = ordinary;
+	nodes[0] = nid;
+	rc = syscall(SYS_move_pages, 0, 1UL, pages, nodes, &status,
+		     MPOL_MF_MOVE);
+	report(!rc && pages_on_node(ordinary, NR_PAGES, nid) == 1 ? PASS : FAIL,
+	       "move_pages() moves a page to the private node");
+
+	pages[0] = bound;
+	nodes[0] = common;
+	rc = syscall(SYS_move_pages, 0, 1UL, pages, nodes, &status,
+		     MPOL_MF_MOVE);
+	report(!rc && pages_on_node(bound, NR_PAGES, common) == 1 ? PASS : FAIL,
+	       "move_pages() moves a private page to common memory");
+
+	report(in_child(migrate_to_private, nid),
+	       "migrate_pages() moves pages to the private node");
+
+	report(pageout_acts(paged, len, nid),
+	       "MADV_PAGEOUT pages out private memory");
+
+	snprintf(path, sizeof(path), "/sys/devices/system/node/node%d/reclaim",
+		 nid);
+	report(thp_split_reclaimed(nid, path),
+	       "node reclaim splits partially mapped private THPs");
+
+	/* memcg reclaim may page out the mappings above, so it runs late. */
+	report(memcg_reclaim_path(path, sizeof(path)) ?
+	       thp_split_reclaimed(nid, path) : SKIP,
+	       "memcg reclaim splits partially mapped private THPs");
+
+	munmap(paged, len);
+	munmap(probe, len);
+	munmap(mixed, len);
+	munmap(bound, len);
+	munmap(ordinary, len);
+
+	private_exhaustion(nid);
+
+	ksft_finished();
+}
diff --git a/tools/testing/selftests/dax/private_node_common.sh b/tools/testing/selftests/dax/private_node_common.sh
index 57c5231e768b..cd03d9489822 100644
--- a/tools/testing/selftests/dax/private_node_common.sh
+++ b/tools/testing/selftests/dax/private_node_common.sh
@@ -12,6 +12,7 @@
 
 DAX_BASE=/sys/bus/dax/devices
 NODE_BASE=/sys/devices/system/node
+CGROOT=/sys/fs/cgroup
 
 # Whether nodelist $1 (e.g. "0-2,4") contains node $2.
 pn_nodelist_has()
@@ -206,3 +207,30 @@ pn_setup()
 	done
 	pn_skip_or_fail "no private kmem device"
 }
+
+# Set COMMON to the first $1 nodes with common memory.
+pn_find_common_nodes()
+{
+	local node nid
+
+	COMMON=()
+	for node in "$NODE_BASE"/node[0-9]*; do
+		nid=${node##*node}
+		pn_node_in "$nid" has_common_memory || continue
+		COMMON+=("$nid")
+		[ "${#COMMON[@]}" = "$1" ] && return 0
+	done
+	pn_skip "requires $1 common memory node(s)"
+}
+
+# The helper tools pass node masks as a single unsigned long.
+pn_require_mask_nodes()
+{
+	local nid bits
+
+	bits=$(getconf LONG_BIT)
+	for nid in "$@"; do
+		[ "$nid" -lt "$bits" ] ||
+			pn_skip "node $nid does not fit the helper node mask"
+	done
+}
diff --git a/tools/testing/selftests/dax/settings b/tools/testing/selftests/dax/settings
index ba4d85f74cd6..694d70710ff0 100644
--- a/tools/testing/selftests/dax/settings
+++ b/tools/testing/selftests/dax/settings
@@ -1 +1 @@
-timeout=90
+timeout=300

-- 
2.56.1

