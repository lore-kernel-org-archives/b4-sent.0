From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:28:16 -0700
Subject: [PATCH RFC v2 44/50] KVM: selftests: Test flag dependency of
 PFN_MODE on USE_RESOURCE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-44-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711665; l=2495;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=hW848+QLjOl269a7jTABrUtgNNZFcVVtDQ3JXHLCB+w=;
 b=fU28rqS9xlt6ezgnpahjWog+2P1ewPQlBSE+tyB8TuF5+17PJac6BxJaoiYMYysn333j5bn6N
 TnDkxIkJYU5ALgLLw+3zeLxvcsKbeB38GL6yfutX+0WrdXscM2rsPom
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Creating a guest_memfd with GUEST_MEMFD_FLAG_PFN_MODE requires
GUEST_MEMFD_FLAG_USE_RESOURCE.

Skip testing GUEST_MEMFD_FLAG_PFN_MODE as an isolated flag in
test_guest_memfd_flags() because creating a guest_memfd with PFN_MODE
alone without USE_RESOURCE is rejected by KVM with EINVAL.

In test_resource_fd_invalid(), verify that attempting to create a
guest_memfd with GUEST_MEMFD_FLAG_PFN_MODE without
GUEST_MEMFD_FLAG_USE_RESOURCE fails with EINVAL.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/include/uapi/linux/kvm.h                 | 1 +
 tools/testing/selftests/kvm/guest_memfd_test.c | 8 +++++++-
 2 files changed, 8 insertions(+), 1 deletion(-)

diff --git a/tools/include/uapi/linux/kvm.h b/tools/include/uapi/linux/kvm.h
index 66c1f40b50c29..3ef7bc37a7070 100644
--- a/tools/include/uapi/linux/kvm.h
+++ b/tools/include/uapi/linux/kvm.h
@@ -1655,6 +1655,7 @@ struct kvm_memory_attributes {
 #define GUEST_MEMFD_FLAG_MMAP		(1ULL << 0)
 #define GUEST_MEMFD_FLAG_INIT_SHARED	(1ULL << 1)
 #define GUEST_MEMFD_FLAG_USE_RESOURCE	(1ULL << 2)
+#define GUEST_MEMFD_FLAG_PFN_MODE	(1ULL << 3)
 
 struct kvm_create_guest_memfd {
 	__u64 size;
diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index cbc2f309664b2..fb9d50be2e3b6 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -407,7 +407,8 @@ static void test_guest_memfd_flags(struct kvm_vm *vm)
 	int fd;
 
 	for (flag = BIT(0); flag; flag <<= 1) {
-		if (flag == GUEST_MEMFD_FLAG_USE_RESOURCE)
+		if (flag == GUEST_MEMFD_FLAG_USE_RESOURCE ||
+		    flag == GUEST_MEMFD_FLAG_PFN_MODE)
 			continue;
 		fd = __vm_create_guest_memfd(vm, page_size, flag);
 		if (flag & valid_flags) {
@@ -432,6 +433,11 @@ static void test_resource_fd_invalid(struct kvm_vm *vm)
 	TEST_ASSERT(fd < 0, "guest_memfd with resource_fd but without flag should fail");
 	TEST_ASSERT_EQ(errno, EINVAL);
 
+	/* PFN_MODE without GUEST_MEMFD_FLAG_USE_RESOURCE fails */
+	fd = __vm_create_guest_memfd(vm, page_size, GUEST_MEMFD_FLAG_PFN_MODE);
+	TEST_ASSERT(fd < 0, "guest_memfd with PFN_MODE without USE_RESOURCE should fail");
+	TEST_ASSERT_EQ(errno, EINVAL);
+
 	/* Bad file descriptor with GUEST_MEMFD_FLAG_USE_RESOURCE fails */
 	fd = __vm_create_guest_memfd_resource(vm, page_size,
 					      GUEST_MEMFD_FLAG_USE_RESOURCE, -1);

-- 
2.56.0.257.gf7497c7d27-goog

