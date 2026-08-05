From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Wed, 05 Aug 2026 16:48:26 +0530
Subject: [PATCH 3/3] selftests/mm: test hwpoison recovery of mappingless
 swapcache THPs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-b4-mappingless-swapcache-v1-3-b1d78ba257ca@zohomail.in>
References: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
In-Reply-To: <20260805-b4-mappingless-swapcache-v1-0-b1d78ba257ca@zohomail.in>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Zi Yan <ziy@nvidia.com>, Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Barry Song <baohua@kernel.org>, 
 Lance Yang <lance.yang@linux.dev>, Usama Arif <usama.arif@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Shuah Khan <shuah@kernel.org>, Nico Pache <nico.pache@linux.dev>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785928706; l=11838;
 i=shivamkalra98@zohomail.in; s=20260402; h=from:subject:message-id;
 bh=fXyTWQ7RHulDRN52CXEgZSMCHIqkhJ6VQwjeCoCiP+M=;
 b=CNrFXdSVKLRfA/IsbpuHXTHssZsGOcmCVLpBjZ+t9wedKuPDagGPyNcDBjMYYs4dIEGWANPgR
 uGGodd2i/C4AaJSWdbVwA3hcsUkWYgyVtxx6H2T7k6y7WCQswhX3ZOE
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=U8kQSxcte8P8iZ6zB7phIj+Yl+i/5ntifBGuclgypx8=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260402 with auth_id=716
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exercise memory_failure() on a tail page of a shmem THP after MADV_PAGEOUT
has made it a mappingless swapcache folio. Verify that the folio is split,
only the target PFN is poisoned, and the remaining mapping can be faulted
back in with its original data.

Use a temporary loop-backed swap device so the test also works when the
kselftest directory is on 9p or NFS. Register the wrapper in the
memory-failure test suite and clean up the loop device and swap file on
every exit path.

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 tools/testing/selftests/mm/Makefile                |   2 +
 tools/testing/selftests/mm/run_vmtests.sh          |   1 +
 .../selftests/mm/split_hwpoison_swapcache.sh       |  57 +++++
 .../selftests/mm/split_hwpoison_swapcache_test.c   | 261 +++++++++++++++++++++
 4 files changed, 321 insertions(+)

diff --git a/tools/testing/selftests/mm/Makefile b/tools/testing/selftests/mm/Makefile
index 2d5366196e30..f0ae0b5685a6 100644
--- a/tools/testing/selftests/mm/Makefile
+++ b/tools/testing/selftests/mm/Makefile
@@ -93,6 +93,7 @@ TEST_GEN_FILES += uffd-stress
 TEST_GEN_FILES += uffd-unit-tests
 TEST_GEN_FILES += uffd-wp-mremap
 TEST_GEN_FILES += split_huge_page_test
+TEST_GEN_FILES += split_hwpoison_swapcache_test
 TEST_GEN_FILES += ksm_tests
 TEST_GEN_FILES += ksm_functional_tests
 TEST_GEN_FILES += mdwe_test
@@ -177,6 +178,7 @@ TEST_PROGS += ksft_vmalloc.sh
 TEST_FILES := test_vmalloc.sh
 TEST_FILES += test_hmm.sh
 TEST_FILES += va_high_addr_switch.sh
+TEST_FILES += split_hwpoison_swapcache.sh
 TEST_FILES += charge_reserved_hugetlb.sh
 TEST_FILES += hugetlb_reparenting_test.sh
 TEST_FILES += test_page_frag.sh
diff --git a/tools/testing/selftests/mm/run_vmtests.sh b/tools/testing/selftests/mm/run_vmtests.sh
index 687d115e3bd8..39c8cf92ccc1 100755
--- a/tools/testing/selftests/mm/run_vmtests.sh
+++ b/tools/testing/selftests/mm/run_vmtests.sh
@@ -459,6 +459,7 @@ CATEGORY="page_frag" run_test ./test_page_frag.sh nonaligned
 CATEGORY="rmap" run_test ./rmap
 
 CATEGORY="memory-failure" run_test ./memory-failure
+CATEGORY="memory-failure" run_test ./split_hwpoison_swapcache.sh
 
 echo "SUMMARY: PASS=${count_pass} SKIP=${count_skip} FAIL=${count_fail}" | tap_prefix
 echo "1..${count_total}" | tap_output
diff --git a/tools/testing/selftests/mm/split_hwpoison_swapcache.sh b/tools/testing/selftests/mm/split_hwpoison_swapcache.sh
new file mode 100755
index 000000000000..fe986a09f697
--- /dev/null
+++ b/tools/testing/selftests/mm/split_hwpoison_swapcache.sh
@@ -0,0 +1,57 @@
+#!/bin/bash
+# SPDX-License-Identifier: GPL-2.0
+#
+# Setup swap and run the mappingless swapcache hwpoison split test
+
+ksft_skip=4
+swap_file=
+loop_dev=
+
+skip() {
+	echo "skip: $*"
+	exit "$ksft_skip"
+}
+
+cleanup() {
+	if [ -n "$loop_dev" ]; then
+		swapoff "$loop_dev" 2>/dev/null || true
+		losetup -d "$loop_dev" 2>/dev/null || true
+	fi
+	if [ -n "$swap_file" ]; then
+		rm -f "$swap_file"
+	fi
+}
+
+trap cleanup EXIT
+trap 'exit 1' HUP INT TERM
+
+if [ "$(id -u)" -ne 0 ]; then
+	skip "must run as root"
+fi
+
+if [ ! -w /sys/kernel/debug/hwpoison/corrupt-pfn ]; then
+	skip "hwpoison injection is not available"
+fi
+
+# Use a loop device because the kselftest directory may be on 9p or NFS.
+if ! swap_file=$(mktemp /tmp/hwpoison_swap.XXXXXX); then
+	echo "FAIL: could not create a temporary swap file"
+	exit 1
+fi
+if ! dd if=/dev/zero of="$swap_file" bs=1M count=128 status=none; then
+	echo "FAIL: could not initialize the temporary swap file"
+	exit 1
+fi
+if ! loop_dev=$(losetup --find --show "$swap_file"); then
+	skip "no loop device is available"
+fi
+if ! mkswap "$loop_dev" >/dev/null; then
+	echo "FAIL: could not initialize swap on $loop_dev"
+	exit 1
+fi
+if ! swapon "$loop_dev"; then
+	echo "FAIL: could not enable swap on $loop_dev"
+	exit 1
+fi
+
+"$(dirname "$(readlink -f "$0")")"/split_hwpoison_swapcache_test
diff --git a/tools/testing/selftests/mm/split_hwpoison_swapcache_test.c b/tools/testing/selftests/mm/split_hwpoison_swapcache_test.c
new file mode 100644
index 000000000000..2d956ae517cf
--- /dev/null
+++ b/tools/testing/selftests/mm/split_hwpoison_swapcache_test.c
@@ -0,0 +1,261 @@
+// SPDX-License-Identifier: GPL-2.0
+/*
+ * Test that memory failure can split a mappingless shmem THP in swap cache.
+ */
+
+#define _GNU_SOURCE
+#include <errno.h>
+#include <fcntl.h>
+#include <stdbool.h>
+#include <stdint.h>
+#include <stdio.h>
+#include <stdlib.h>
+#include <string.h>
+#include <sys/mman.h>
+#include <unistd.h>
+
+#include "../kselftest.h"
+#include "hugepage_settings.h"
+#include "vm_util.h"
+
+#define HWPOISON_PATH "/sys/kernel/debug/hwpoison/corrupt-pfn"
+
+#define KPF_MMAP	BIT_ULL(11)
+#define KPF_SWAPCACHE	BIT_ULL(13)
+#define KPF_SWAPBACKED	BIT_ULL(14)
+
+#define TEST_BYTE	0x5a
+#define PAGEOUT_RETRIES	100
+#define PAGEOUT_DELAY_US	100000
+
+static bool is_swapcache_thp(uint64_t flags, bool head)
+{
+	uint64_t required = KPF_SWAPCACHE | KPF_SWAPBACKED | KPF_THP;
+
+	required |= head ? KPF_COMPOUND_HEAD : KPF_COMPOUND_TAIL;
+	return (flags & required) == required && !(flags & KPF_MMAP);
+}
+
+static int wait_for_swapcache_thp(unsigned long head_pfn, unsigned long target_pfn,
+				  int kpageflags_fd)
+{
+	uint64_t head_flags = 0;
+	uint64_t target_flags = 0;
+	int i;
+
+	for (i = 0; i < PAGEOUT_RETRIES; i++) {
+		if (pageflags_get(head_pfn, kpageflags_fd, &head_flags) ||
+		    pageflags_get(target_pfn, kpageflags_fd, &target_flags))
+			return -1;
+
+		if (is_swapcache_thp(head_flags, true) &&
+		    is_swapcache_thp(target_flags, false))
+			return 0;
+
+		usleep(PAGEOUT_DELAY_US);
+	}
+
+	ksft_print_msg("Swapcache THP flags: head=%#llx target=%#llx\n",
+			(unsigned long long)head_flags,
+			(unsigned long long)target_flags);
+	return 1;
+}
+
+static bool folio_was_split(unsigned long head_pfn, unsigned long target_pfn,
+			    unsigned long nr_pages, int kpageflags_fd)
+{
+	const uint64_t compound = KPF_COMPOUND_HEAD | KPF_COMPOUND_TAIL;
+	uint64_t flags;
+	unsigned long i;
+
+	for (i = 0; i < nr_pages; i++) {
+		if (pageflags_get(head_pfn + i, kpageflags_fd, &flags))
+			return false;
+		if (flags & compound) {
+			ksft_print_msg("PFN %#lx is still compound (flags=%#llx)\n",
+					head_pfn + i,
+					(unsigned long long)flags);
+			return false;
+		}
+		if ((head_pfn + i == target_pfn) != !!(flags & KPF_HWPOISON)) {
+			ksft_print_msg(
+				"Unexpected HWPoison state at PFN %#lx (flags=%#llx)\n",
+				head_pfn + i, (unsigned long long)flags);
+			return false;
+		}
+	}
+
+	return true;
+}
+
+static bool mapping_has_expected_data(const unsigned char *addr, size_t size)
+{
+	size_t i;
+
+	for (i = 0; i < size; i++) {
+		if (addr[i] != TEST_BYTE) {
+			ksft_print_msg("Data mismatch at offset %#zx: %#x != %#x\n",
+					i, addr[i], TEST_BYTE);
+			return false;
+		}
+	}
+
+	return true;
+}
+
+static int inject_hwpoison(unsigned long pfn)
+{
+	char buf[32];
+	ssize_t written;
+	int fd;
+	int len;
+	int saved_errno;
+
+	fd = open(HWPOISON_PATH, O_WRONLY);
+	if (fd < 0)
+		return -errno;
+
+	len = snprintf(buf, sizeof(buf), "%#lx\n", pfn);
+	written = write(fd, buf, len);
+	saved_errno = errno;
+	close(fd);
+
+	if (written != len)
+		return written < 0 ? -saved_errno : -EIO;
+
+	return 0;
+}
+
+int main(void)
+{
+	struct thp_settings settings;
+	unsigned long target_pfn;
+	unsigned long head_pfn;
+	unsigned long nr_pages;
+	unsigned long page_size;
+	unsigned long pmd_size;
+	unsigned char *mapping;
+	unsigned char *addr;
+	uint64_t flags;
+	bool poisoned = false;
+	bool pass = false;
+	int kpageflags_fd = -1;
+	int pagemap_fd = -1;
+	int memfd = -1;
+	int ret;
+
+	ksft_print_header();
+	ksft_set_plan(1);
+
+	if (geteuid())
+		ksft_exit_skip("Please run the test as root\n");
+
+	pmd_size = read_pmd_pagesize();
+	if (!thp_available() || !pmd_size)
+		ksft_exit_skip("Transparent Huge Pages are not available\n");
+
+	if (access(HWPOISON_PATH, W_OK))
+		ksft_exit_skip("HWPoison injection is not available\n");
+
+	page_size = getpagesize();
+	if (pmd_size % page_size)
+		ksft_exit_fail_msg("Invalid PMD page size %#lx\n", pmd_size);
+	nr_pages = pmd_size / page_size;
+
+	thp_save_settings();
+	thp_read_settings(&settings);
+	settings.shmem_enabled = SHMEM_ADVISE;
+	thp_write_settings(&settings);
+
+	memfd = memfd_create("split_hwpoison_swapcache", MFD_CLOEXEC);
+	if (memfd < 0)
+		ksft_exit_fail_perror("memfd_create");
+	if (ftruncate(memfd, pmd_size))
+		ksft_exit_fail_perror("ftruncate");
+
+	/* Reserve enough space to obtain a PMD-aligned file mapping. */
+	mapping = mmap(NULL, 2 * pmd_size, PROT_NONE,
+		       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+	if (mapping == MAP_FAILED)
+		ksft_exit_fail_perror("mmap");
+	addr = (unsigned char *)(((uintptr_t)mapping + pmd_size - 1) &
+				 ~(pmd_size - 1));
+	if (mmap(addr, pmd_size, PROT_READ | PROT_WRITE,
+		 MAP_SHARED | MAP_FIXED, memfd, 0) == MAP_FAILED)
+		ksft_exit_fail_perror("mmap");
+
+	if (madvise(addr, pmd_size, MADV_HUGEPAGE))
+		ksft_exit_fail_perror("madvise(MADV_HUGEPAGE)");
+	memset(addr, TEST_BYTE, pmd_size);
+
+	if (!check_huge_shmem(addr, 1, pmd_size))
+		ksft_exit_skip("Failed to allocate a PMD-sized shmem THP\n");
+
+	pagemap_fd = open("/proc/self/pagemap", O_RDONLY);
+	if (pagemap_fd < 0)
+		ksft_exit_fail_perror("open(/proc/self/pagemap)");
+	kpageflags_fd = open("/proc/kpageflags", O_RDONLY);
+	if (kpageflags_fd < 0)
+		ksft_exit_fail_perror("open(/proc/kpageflags)");
+
+	head_pfn = pagemap_get_pfn(pagemap_fd, (char *)addr);
+	if (head_pfn == -1UL)
+		ksft_exit_fail_msg("Failed to obtain the shmem THP PFN\n");
+
+	/* Poison a tail page so success necessarily requires a real split. */
+	target_pfn = head_pfn + nr_pages / 2;
+	if (pageflags_get(head_pfn, kpageflags_fd, &flags) ||
+	    (flags & (KPF_THP | KPF_COMPOUND_HEAD)) !=
+		    (KPF_THP | KPF_COMPOUND_HEAD))
+		ksft_exit_fail_msg("PFN %#lx is not a THP head\n", head_pfn);
+	if (pageflags_get(target_pfn, kpageflags_fd, &flags) ||
+	    (flags & (KPF_THP | KPF_COMPOUND_TAIL)) !=
+		    (KPF_THP | KPF_COMPOUND_TAIL))
+		ksft_exit_fail_msg("PFN %#lx is not a THP tail\n", target_pfn);
+
+	if (madvise(addr, pmd_size, MADV_PAGEOUT))
+		ksft_exit_skip("madvise(MADV_PAGEOUT) failed: %s\n",
+			       strerror(errno));
+
+	ret = wait_for_swapcache_thp(head_pfn, target_pfn, kpageflags_fd);
+	if (ret < 0)
+		ksft_exit_fail_msg("Failed to read kpageflags\n");
+	if (ret > 0)
+		ksft_exit_skip("Failed to create a mappingless swapcache THP; "
+			       "is swap enabled?\n");
+
+	ksft_print_msg("Injecting HWPoison into tail PFN %#lx of THP %#lx\n",
+			target_pfn, head_pfn);
+	ret = inject_hwpoison(target_pfn);
+	poisoned = true;
+	if (ret) {
+		ksft_print_msg("HWPoison injection failed: %s\n", strerror(-ret));
+		goto out;
+	}
+
+	if (!folio_was_split(head_pfn, target_pfn, nr_pages, kpageflags_fd))
+		goto out;
+
+	/*
+	 * A clean poisoned swapcache page is discarded. Faulting the mapping
+	 * back in must recover the original data from swap.
+	 */
+	if (!mapping_has_expected_data(addr, pmd_size))
+		goto out;
+
+	pass = true;
+out:
+	if (poisoned && unpoison_memory(target_pfn)) {
+		ksft_print_msg("Failed to unpoison PFN %#lx\n", target_pfn);
+		pass = false;
+	}
+	if (kpageflags_fd >= 0)
+		close(kpageflags_fd);
+	if (pagemap_fd >= 0)
+		close(pagemap_fd);
+	munmap(mapping, 2 * pmd_size);
+	close(memfd);
+
+	ksft_test_result(pass, "memory failure splits a mappingless swapcache THP\n");
+	ksft_finished();
+}

-- 
2.43.0

