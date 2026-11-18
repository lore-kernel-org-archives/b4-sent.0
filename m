From: Matthew Salsamendi <matthewsalsamendi@gmail.com>
Date: Tue, 17 Nov 2026 16:26:17 -0800
Subject: [PATCH v2 2/2] selftests/mm: cover PAGEMAP_SCAN refill and HugeTLB
 retry
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 David Hildenbrand <david@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: Chris Down <chris@chrisdown.name>, Vlastimil Babka <vbabka@kernel.org>, 
 Muhammad Usama Anjum <usama.anjum@arm.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, matthewsalsamendi@gmail.com, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, linux-kselftest@vger.kernel.org
Message-Id: <20261118-pagemap-walk-end-v2-2-94cd92d838b3@gmail.com>
In-Reply-To: <20261118-pagemap-walk-end-v2-0-94cd92d838b3@gmail.com>
References: <20261118-pagemap-walk-end-v2-0-94cd92d838b3@gmail.com>
X-Mailer: b4 0.16.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794961577; l=4010;
 i=matthewsalsamendi@gmail.com; s=b4-kernel-20261117;
 h=from:subject:message-id; bh=NjI4ckbRiDH/qj/osMQWWUKd8BFP8IcXjX/T5XOwGbg=;
 b=mrjF2WrjZGFgovurzwg8O491bymKSYiw6D8PuPvt46rgg2nazqv8TPr8dKIckqMsNpfgMOKTh
 YEQcy8h++zCCbqFtnK/w6RdNSXJy1wNYLOihLNAAODzz4YDmq/jUmr2
X-Developer-Key: i=matthewsalsamendi@gmail.com; a=ed25519;
 pk=K4Lg4pTU46IL2CPz2Nb/u30nsnWJ38MlR2/Co4n0tto=
X-Endpoint-Received: by B4 Relay for matthewsalsamendi@gmail.com/b4-kernel-20261117 with auth_id=1555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check that scanning 513 disjoint dirty pages returns every range and
sets walk_end to the end of the scan. For a written HugeTLB page, limit
the scan to one base page, then retry from walk_end and check that the
whole page is returned and write-protected.

Codex assisted with the selftests, validation and this message.

Suggested-by: Andrew Morton <akpm@linux-foundation.org>
Suggested-by: Chris Down <chris@chrisdown.name>
Signed-off-by: Matthew Salsamendi <matthewsalsamendi@gmail.com>
---
 tools/testing/selftests/mm/pagemap_ioctl.c | 61 +++++++++++++++++++++-
 1 file changed, 60 insertions(+), 1 deletion(-)

diff --git a/tools/testing/selftests/mm/pagemap_ioctl.c b/tools/testing/selftests/mm/pagemap_ioctl.c
index 03898b4f6cda..02062b178aa5 100644
--- a/tools/testing/selftests/mm/pagemap_ioctl.c
+++ b/tools/testing/selftests/mm/pagemap_ioctl.c
@@ -682,6 +682,62 @@ static int sanity_tests_sd(void)
 	return 0;
 }
 
+static void test_walk_end_after_refill(void)
+{
+	/* One more range than the internal buffer holds on x86-64. */
+	struct page_region vec[513];
+	size_t len = 2 * ARRAY_SIZE(vec) * page_size;
+	long ret, walk_end;
+	char *mem;
+	bool ok;
+	size_t i;
+
+	mem = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
+	if (mem == MAP_FAILED)
+		ksft_exit_fail_msg("mmap: %s\n", strerror(errno));
+	if (madvise(mem, len, MADV_NOHUGEPAGE) && errno != EINVAL)
+		ksft_exit_fail_msg("MADV_NOHUGEPAGE: %s\n", strerror(errno));
+
+	wp_init(mem, len);
+	for (i = 0; i < ARRAY_SIZE(vec); i++)
+		mem[2 * i * page_size] = 1;
+
+	ret = pagemap_ioc(mem, len, vec, ARRAY_SIZE(vec), 0, 0,
+			  PAGE_IS_WRITTEN, 0, 0, PAGE_IS_WRITTEN, &walk_end);
+	ok = ret == ARRAY_SIZE(vec) && walk_end == (long)(mem + len);
+	for (i = 0; ok && i < ARRAY_SIZE(vec); i++) {
+		uintptr_t addr = (uintptr_t)(mem + 2 * i * page_size);
+
+		ok = vec[i].start == addr && vec[i].end == addr + page_size;
+	}
+	ksft_test_result(ok, "PAGEMAP_SCAN walk_end after buffer refill\n");
+
+	wp_free(mem, len);
+	munmap(mem, len);
+}
+
+static void test_hugetlb_walk_end(char *mem, size_t len)
+{
+	const int flags = PM_SCAN_WP_MATCHING | PM_SCAN_CHECK_WPASYNC;
+	struct page_region range;
+	long ret, walk_end;
+	bool ok;
+
+	mem[0] = 1;
+	ret = pagemap_ioc(mem, len, &range, 1, flags, 1, PAGE_IS_WRITTEN,
+			  0, 0, PAGE_IS_WRITTEN, &walk_end);
+	ok = ret == 0 && walk_end == (long)mem &&
+	     !(pagemap_get_entry(pagemap_fd, mem) & PM_UFFD_WP);
+	if (ok) {
+		ret = pagemap_ioc((void *)walk_end, len, &range, 1, flags, len / page_size,
+				  PAGE_IS_WRITTEN, 0, 0, PAGE_IS_WRITTEN, &walk_end);
+		ok = ret == 1 && walk_end == (long)(mem + len) &&
+		     range.start == (uintptr_t)mem && range.end == (uintptr_t)(mem + len) &&
+		     (pagemap_get_entry(pagemap_fd, mem) & PM_UFFD_WP);
+	}
+	ksft_test_result(ok, "PAGEMAP_SCAN HugeTLB write-protect retry\n");
+}
+
 static int base_tests(char *prefix, char *mem, size_t mem_size, int skip)
 {
 	size_t vec_size;
@@ -1661,7 +1717,7 @@ int main(int __attribute__((unused)) argc, char *argv[])
 	if (!hugetlb_setup_default(4))
 		ksft_print_msg("HugeTLB test will be skipped\n");
 
-	ksft_set_plan(119);
+	ksft_set_plan(121);
 
 	pagemap_fd = open(PAGEMAP, O_RDONLY);
 	if (pagemap_fd < 0)
@@ -1669,6 +1725,7 @@ int main(int __attribute__((unused)) argc, char *argv[])
 
 	/* 1. Sanity testing */
 	sanity_tests_sd();
+	test_walk_end_after_refill();
 
 	/* 2. Normal page testing */
 	mem_size = 10 * page_size;
@@ -1730,10 +1787,12 @@ int main(int __attribute__((unused)) argc, char *argv[])
 		wp_addr_range(mem, mem_size);
 
 		base_tests("Hugetlb mem testing:", mem, mem_size, 0);
+		test_hugetlb_walk_end(mem, mem_size);
 
 		wp_free(mem, mem_size);
 	} else {
 		base_tests("Hugetlb mem testing:", NULL, 0, 1);
+		ksft_test_result_skip("PAGEMAP_SCAN HugeTLB write-protect retry: no huge page\n");
 	}
 
 	/* 7. File Hugetlb testing */

