From: Ackerley Tng <ackerleytng@google.com>
Date: Tue, 28 Apr 2026 16:25:42 -0700
Subject: [PATCH RFC v5 47/53] KVM: selftests: Provide common function to
 set memory attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-gmem-inplace-conversion-v5-47-d8608ccfca22@google.com>
References: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
In-Reply-To: <20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, Paolo Bonzini <pbonzini@redhat.com>, 
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
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <bhe@redhat.com>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Youngjun Park <youngjun.park@lge.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777418714; l=5499;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=x8WxP9zvytzuqL5tzXmnvDO35wF0Bk1eLqxImWMw/aQ=;
 b=iV5e1pQisdMevCU5CiJtojdosppLVl1PRMIYiUBBT/pi9FZox4TCPglLIzytx0XkHy9Ph9bsO
 xFjPgwK5wRvAwZzt6Lx1VOzRt2Hz4eVHfIO3i7PgOCUXg601spXNW2d
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Introduce vm_mem_set_memory_attributes(), which handles setting of memory
attributes for a range of guest physical addresses, regardless of whether
the attributes should be set via guest_memfd or via the memory attributes
at the VM level.

Refactor existing vm_mem_set_{shared,private} functions to use the new
function. Opportunistically update the size parameter to use size_t instead
of u64.

Update existing caller of vm_mem_set_private().

Signed-off-by: Sean Christopherson <seanjc@google.com>
Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/include/kvm_util.h     | 47 ++++++++++++++++------
 tools/testing/selftests/kvm/lib/x86/sev.c          |  2 +-
 .../testing/selftests/kvm/pre_fault_memory_test.c  |  2 +-
 .../selftests/kvm/x86/private_mem_kvm_exits_test.c |  4 +-
 4 files changed, 39 insertions(+), 16 deletions(-)

diff --git a/tools/testing/selftests/kvm/include/kvm_util.h b/tools/testing/selftests/kvm/include/kvm_util.h
index 7de88cbdfd2b8..c9dba44ce6bf9 100644
--- a/tools/testing/selftests/kvm/include/kvm_util.h
+++ b/tools/testing/selftests/kvm/include/kvm_util.h
@@ -454,18 +454,6 @@ static inline void vm_set_memory_attributes(struct kvm_vm *vm, gpa_t gpa,
 	vm_ioctl(vm, KVM_SET_MEMORY_ATTRIBUTES, &attr);
 }
 
-static inline void vm_mem_set_private(struct kvm_vm *vm, gpa_t gpa,
-				      u64 size)
-{
-	vm_set_memory_attributes(vm, gpa, size, KVM_MEMORY_ATTRIBUTE_PRIVATE);
-}
-
-static inline void vm_mem_set_shared(struct kvm_vm *vm, gpa_t gpa,
-				     u64 size)
-{
-	vm_set_memory_attributes(vm, gpa, size, 0);
-}
-
 static inline int __gmem_set_memory_attributes(int fd, loff_t offset,
 					       size_t size, u64 attributes,
 					       loff_t *error_offset,
@@ -536,6 +524,41 @@ static inline void gmem_set_shared(int fd, loff_t offset, size_t size, u64 flags
 	gmem_set_memory_attributes(fd, offset, size, 0, flags);
 }
 
+static inline void vm_mem_set_memory_attributes(struct kvm_vm *vm, gpa_t gpa,
+						size_t size, u64 attrs, u64 flags)
+{
+	if (kvm_has_gmem_attributes) {
+		gpa_t end = gpa + size;
+		off_t fd_offset;
+		gpa_t addr;
+		size_t len;
+		int fd;
+
+		for (addr = gpa; addr < end; addr += len) {
+			fd = kvm_gpa_to_guest_memfd(vm, addr, &fd_offset, &len);
+			len = min(end - addr, len);
+
+			gmem_set_memory_attributes(fd, fd_offset, len, attrs, flags);
+		}
+	} else {
+		TEST_ASSERT(!flags, "Flags are not supported.");
+		vm_set_memory_attributes(vm, gpa, size, attrs);
+	}
+}
+
+static inline void vm_mem_set_private(struct kvm_vm *vm, gpa_t gpa,
+				      size_t size, u64 flags)
+{
+	vm_mem_set_memory_attributes(vm, gpa, size,
+				     KVM_MEMORY_ATTRIBUTE_PRIVATE, flags);
+}
+
+static inline void vm_mem_set_shared(struct kvm_vm *vm, gpa_t gpa,
+				     size_t size, u64 flags)
+{
+	vm_mem_set_memory_attributes(vm, gpa, size, 0, flags);
+}
+
 void vm_guest_mem_fallocate(struct kvm_vm *vm, gpa_t gpa, u64 size,
 			    bool punch_hole);
 
diff --git a/tools/testing/selftests/kvm/lib/x86/sev.c b/tools/testing/selftests/kvm/lib/x86/sev.c
index 93f9169034617..d0205b3299e0b 100644
--- a/tools/testing/selftests/kvm/lib/x86/sev.c
+++ b/tools/testing/selftests/kvm/lib/x86/sev.c
@@ -33,7 +33,7 @@ static void encrypt_region(struct kvm_vm *vm, struct userspace_mem_region *regio
 		const u64 offset = (i - lowest_page_in_region) * vm->page_size;
 
 		if (private)
-			vm_mem_set_private(vm, gpa_base + offset, size);
+			vm_mem_set_private(vm, gpa_base + offset, size, 0);
 
 		if (is_sev_snp_vm(vm))
 			snp_launch_update_data(vm, gpa_base + offset,
diff --git a/tools/testing/selftests/kvm/pre_fault_memory_test.c b/tools/testing/selftests/kvm/pre_fault_memory_test.c
index fcb57fd034e67..9d16a277696ce 100644
--- a/tools/testing/selftests/kvm/pre_fault_memory_test.c
+++ b/tools/testing/selftests/kvm/pre_fault_memory_test.c
@@ -184,7 +184,7 @@ static void __test_pre_fault_memory(unsigned long vm_type, bool private)
 	virt_map(vm, gva, gpa, TEST_NPAGES);
 
 	if (private)
-		vm_mem_set_private(vm, gpa, TEST_SIZE);
+		vm_mem_set_private(vm, gpa, TEST_SIZE, 0);
 
 	pre_fault_memory(vcpu, gpa, 0, SZ_2M, 0, private);
 	pre_fault_memory(vcpu, gpa, SZ_2M, PAGE_SIZE * 2, PAGE_SIZE, private);
diff --git a/tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c b/tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c
index 10db9fe6d9063..9309d67841482 100644
--- a/tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c
+++ b/tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c
@@ -63,7 +63,7 @@ static void test_private_access_memslot_deleted(void)
 	virt_map(vm, EXITS_TEST_GVA, EXITS_TEST_GPA, EXITS_TEST_NPAGES);
 
 	/* Request to access page privately */
-	vm_mem_set_private(vm, EXITS_TEST_GPA, EXITS_TEST_SIZE);
+	vm_mem_set_private(vm, EXITS_TEST_GPA, EXITS_TEST_SIZE, 0);
 
 	pthread_create(&vm_thread, NULL,
 		       (void *(*)(void *))run_vcpu_get_exit_reason,
@@ -99,7 +99,7 @@ static void test_private_access_memslot_not_private(void)
 	virt_map(vm, EXITS_TEST_GVA, EXITS_TEST_GPA, EXITS_TEST_NPAGES);
 
 	/* Request to access page privately */
-	vm_mem_set_private(vm, EXITS_TEST_GPA, EXITS_TEST_SIZE);
+	vm_mem_set_private(vm, EXITS_TEST_GPA, EXITS_TEST_SIZE, 0);
 
 	exit_reason = run_vcpu_get_exit_reason(vcpu);
 

-- 
2.54.0.545.g6539524ca2-goog

