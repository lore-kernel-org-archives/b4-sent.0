From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:38:00 -0800
Subject: [PATCH RFC v3 86/88] KVM: selftests: Expect successful conversion
 on MSI-X BARs in VFIO test
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-86-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011810; l=2135;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=VzsQCzajxaq4+sy1dgFu+2FHBF/aQtRmKeEX0OOIiWI=;
 b=S4xYrV5byO8s3TboxsOXiZx6GDu3T8GX8FRcNDg51wlr8/L7ZZOzal2WSfJanjxA8BGU7KO+2
 Iju/+vhbIDtBPvAbcjUo+0kvLnJoyMJvy/myX3jkaxwU9LK9VGetSTJ
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Disallowing private mappings of MSI-X vector tables is now enforced
lazily by rejecting private fault resolution when backends report
shared-only physical frames, rather than eagerly rejecting software
attribute conversions.

Update the conversions subtest to expect successful attribute conversion
on BAR3 containing the MSI-X table, matching the lazy rejection model.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)

diff --git a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
index a520cf45fccb8..325d5e0c66026 100644
--- a/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
+++ b/tools/testing/selftests/kvm/x86/guest_memfd_vfio_test.c
@@ -798,17 +798,19 @@ TEST_F(guest_memfd_vfio, conversions)
 	ASSERT_EQ(0, ret);
 
 	/*
-	 * BAR3 contains the MSI-X vector table and PBA. Private conversion
-	 * must be rejected by check_set_attributes to prevent host kernel
-	 * writes to interrupt tables from triggering fatal protection faults.
+	 * BAR3 contains the MSI-X vector table and PBA. Disallowing private
+	 * mappings of the MSI-X table is enforced lazily via NO_PRIVATE PFN
+	 * attributes rather than eagerly rejecting software attribute conversion.
+	 * Converting BAR3 attributes to private in guest_memfd succeeds, but
+	 * attempting to fault the MSI-X page into the guest as private is
+	 * rejected with -EFAULT in kvm_gmem_get_pfn(), causing KVM to exit with
+	 * KVM_EXIT_MEMORY_FAULT.
 	 */
 	ret = __gmem_set_private(self->gmem_fd, bar3_info.offset,
 				 bar3_info.size, &err_offset);
-	ASSERT_LT(ret, 0);
-	ASSERT_EQ(EINVAL, errno);
-	ASSERT_EQ(bar3_info.offset, err_offset);
+	ASSERT_EQ(0, ret);
 
-	/* Shared conversion on BAR3 should be permitted. */
+	/* Shared conversion on BAR3 should also succeed. */
 	ret = __gmem_set_shared(self->gmem_fd, bar3_info.offset,
 				bar3_info.size, &err_offset);
 	ASSERT_EQ(0, ret);

-- 
2.56.0.455.g6c5a503b38-goog

