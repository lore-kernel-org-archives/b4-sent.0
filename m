From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Jul 2026 17:35:28 -0700
Subject: [PATCH v9 29/41] KVM: selftests: Test conversion precision in
 guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-gmem-inplace-conversion-v9-29-35f9aec2aed2@google.com>
References: <20260728-gmem-inplace-conversion-v9-0-35f9aec2aed2@google.com>
In-Reply-To: <20260728-gmem-inplace-conversion-v9-0-35f9aec2aed2@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, tabba@google.com, willy@infradead.org, 
 wyihan@google.com, yan.y.zhao@intel.com, forkloop@google.com, 
 pratyush@kernel.org, suzuki.poulose@arm.com, aneesh.kumar@kernel.org, 
 liam@infradead.org, Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Youngjun Park <youngjun.park@lge.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Kiryl Shutsemau <kas@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Jason Gunthorpe <jgg@ziepe.ca>, John Hubbard <jhubbard@nvidia.com>, 
 Peter Xu <peterx@redhat.com>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Vlastimil Babka <vbabka@kernel.org>, Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785285305; l=4501;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=knW3oEUmnPUSo1gpuqMigsR+t1Q/MFkz7O8GozByUvU=;
 b=fUXw40FC3/ChFHnmqc3VbvieVKq/kEnvWrEo0D03rJCacRFc8ThJ7uLfQzZnHhE22ixPpJhQc
 O27XDvaqfvxBLbgtpjqXv7wxaeb8V+TWRBvfzxuPcZKtdRwums97nOV
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing guest_memfd conversion tests only use single-page memory
regions. This provides no coverage for multi-page guest_memfd objects,
specifically whether KVM correctly handles the page index for conversion
operations. An incorrect implementation could, for example, always operate
on the first page regardless of the index provided.

Add a new test case to verify that conversions between private and shared
memory correctly target the specified page within a multi-page guest_memfd.

This test also verifies the precision of memory conversions by converting a
single page an then iterating through all other pages ensure they remain in
their original state.

To support this test, add a new GMEM_CONVERSION_MULTIPAGE_TEST_INIT_SHARED
macro that handles setting up and tearing down the VM for each page
iteration. The teardown logic is adjusted to prevent a double-free in this
new scenario.

Co-developed-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Sean Christopherson <seanjc@google.com>
Reviewed-by: Fuad Tabba <tabba@google.com>
Tested-by: Shivank Garg <shivankg@amd.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../kvm/x86/guest_memfd_conversions_test.c         | 66 ++++++++++++++++++++++
 1 file changed, 66 insertions(+)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
index 5b070d3374eae..8e17d5c08aeb8 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
@@ -61,8 +61,13 @@ static void gmem_conversions_do_setup(test_data_t *t, int nr_pages,
 
 static void gmem_conversions_do_teardown(test_data_t *t)
 {
+	/* Use NULL to avoid second free in FIXTURE_TEARDOWN (multipage tests). */
+	if (!t->vcpu)
+		return;
+
 	/* No need to close gmem_fd, it's owned by the VM structure. */
 	kvm_vm_free(t->vcpu->vm);
+	t->vcpu = NULL;
 }
 
 FIXTURE_TEARDOWN(gmem_conversions)
@@ -101,6 +106,29 @@ static void __gmem_conversions_##test(test_data_t *t, int nr_pages)		\
 #define GMEM_CONVERSION_TEST_INIT_SHARED(test)					\
 	__GMEM_CONVERSION_TEST_INIT_SHARED(test, 1)
 
+/*
+ * Repeats test over nr_pages in a guest_memfd of size nr_pages, providing each
+ * test iteration with test_page, the index of the page under test in
+ * guest_memfd. test_page takes values 0..(nr_pages - 1) inclusive.
+ */
+#define GMEM_CONVERSION_MULTIPAGE_TEST_INIT_SHARED(test, __nr_pages)		\
+static void __gmem_conversions_multipage_##test(test_data_t *t, int nr_pages,	\
+						const int test_page);		\
+										\
+TEST_F(gmem_conversions, test)							\
+{										\
+	const u64 flags = GUEST_MEMFD_FLAG_MMAP | GUEST_MEMFD_FLAG_INIT_SHARED; \
+	int i;									\
+										\
+	for (i = 0; i < __nr_pages; ++i) {					\
+		gmem_conversions_do_setup(self, __nr_pages, flags);		\
+		__gmem_conversions_multipage_##test(self, __nr_pages, i);	\
+		gmem_conversions_do_teardown(self);				\
+	}									\
+}										\
+static void __gmem_conversions_multipage_##test(test_data_t *t, int nr_pages,	\
+						const int test_page)
+
 struct guest_check_data {
 	void *mem;
 	char expected_val;
@@ -199,6 +227,44 @@ GMEM_CONVERSION_TEST_INIT_SHARED(init_shared)
 	test_convert_to_shared(t, 0, 'C', 'D', 'E');
 }
 
+GMEM_CONVERSION_MULTIPAGE_TEST_INIT_SHARED(indexing, 4)
+{
+	int i;
+
+	/* Get a char that varies with both i and n. */
+#define combine(x, n) ((x << 4) + (n))
+#define i_(n) (combine(i, n))
+#define t_(n) (combine(test_page, n))
+
+	/*
+	 * Start with the highest index, to catch any errors when, perhaps, the
+	 * first page is returned even for the last index.
+	 */
+	for (i = nr_pages - 1; i >= 0; --i)
+		test_shared(t, i, 0, i_(0), i_(2));
+
+	test_convert_to_private(t, test_page, t_(2), t_(3));
+
+	for (i = 0; i < nr_pages; ++i) {
+		if (i == test_page)
+			test_private(t, test_page, t_(3), t_(4));
+		else
+			test_shared(t, i, i_(2), i_(3), i_(4));
+	}
+
+	test_convert_to_shared(t, test_page, t_(4), t_(5), t_(6));
+
+	for (i = 0; i < nr_pages; ++i) {
+		char expected = i == test_page ? t_(6) : i_(4);
+
+		test_shared(t, i, expected, i_(7), i_(8));
+	}
+
+#undef t_
+#undef i_
+#undef combine
+}
+
 int main(int argc, char *argv[])
 {
 	TEST_REQUIRE(kvm_check_cap(KVM_CAP_VM_TYPES) & BIT(KVM_X86_SW_PROTECTED_VM));

-- 
2.55.0.508.g3f0d502094-goog

