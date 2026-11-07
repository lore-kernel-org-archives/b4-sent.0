From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:51 -0800
Subject: [PATCH RFC v3 17/88] KVM: selftests: Test guest execution with
 tmpfs-backed guest_memfd
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-17-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=2755;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=fr8rPkSzXLy1+7CQ4/dHoHPzEtH6SGICpYGF16TSzqc=;
 b=K4Phfaq4Qdgv8seGNPs3X+5Qw5d2T5Sa4NEyiI9XKn3pL0SWjZvjc8r3+b4a+mTomWCACaDzQ
 D8e2EDdfzkXAPLOc3KPgJwp9uTi2kMeJyUw0cg+ragVcNp6ain34P8n
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test that a guest vCPU can execute instructions and read/write memory
mapped into a guest_memfd instance that is backed by a tmpfs resource
pool descriptor.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 56 ++++++++++++++++++++++++++
 1 file changed, 56 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 20de24ad535f1..8e9261db23354 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -799,6 +799,61 @@ static void test_guest_memfd_guest(void)
 	kvm_vm_free(vm);
 }
 
+static void test_guest_memfd_guest_resource(void)
+{
+	const gpa_t gpa = SZ_4G;
+	const int slot = 1;
+	struct kvm_vcpu *vcpu;
+	struct kvm_vm *vm;
+	int pool_fd, fd, i;
+	size_t size;
+	u8 *mem;
+
+	if (!kvm_check_cap(KVM_CAP_GUEST_MEMFD_FLAGS))
+		return;
+
+	pool_fd = create_tmpfs_pool_fd("never", true, page_size);
+	if (pool_fd < 0)
+		TEST_REQUIRE(false);
+
+	vm = __vm_create_shape_with_one_vcpu(VM_SHAPE_DEFAULT, &vcpu, 1, guest_code);
+
+	TEST_ASSERT(vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS) & GUEST_MEMFD_FLAG_MMAP,
+		    "Default VM type should support MMAP, supported flags = 0x%x",
+		    vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS));
+	TEST_ASSERT(vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS) & GUEST_MEMFD_FLAG_INIT_SHARED,
+		    "Default VM type should support INIT_SHARED, supported flags = 0x%x",
+		    vm_check_cap(vm, KVM_CAP_GUEST_MEMFD_FLAGS));
+
+	size = max_t(size_t, vm->page_size, page_size);
+	fd = __vm_create_guest_memfd_resource(vm, size,
+					      GUEST_MEMFD_FLAG_MMAP |
+					      GUEST_MEMFD_FLAG_INIT_SHARED |
+					      GUEST_MEMFD_FLAG_USE_RESOURCE,
+					      pool_fd);
+	TEST_ASSERT(fd >= 0, "guest_memfd with tmpfs pool should succeed");
+
+	vm_set_user_memory_region2(vm, slot, KVM_MEM_GUEST_MEMFD, gpa, size, NULL, fd, 0);
+
+	mem = kvm_mmap(size, PROT_READ | PROT_WRITE, MAP_SHARED, fd);
+	memset(mem, 0xaa, size);
+	kvm_munmap(mem, size);
+
+	virt_map(vm, gpa, gpa, size / vm->page_size);
+	vcpu_args_set(vcpu, 2, gpa, size);
+	vcpu_run(vcpu);
+
+	TEST_ASSERT_EQ(get_ucall(vcpu, NULL), UCALL_DONE);
+
+	mem = kvm_mmap(size, PROT_READ | PROT_WRITE, MAP_SHARED, fd);
+	for (i = 0; i < size; i++)
+		TEST_ASSERT_EQ(mem[i], 0xff);
+
+	close(fd);
+	close(pool_fd);
+	kvm_vm_free(vm);
+}
+
 int main(int argc, char *argv[])
 {
 	unsigned long vm_types, vm_type;
@@ -819,4 +874,5 @@ int main(int argc, char *argv[])
 		test_guest_memfd(vm_type);
 
 	test_guest_memfd_guest();
+	test_guest_memfd_guest_resource();
 }

-- 
2.56.0.455.g6c5a503b38-goog

