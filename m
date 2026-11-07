From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:52 -0800
Subject: [PATCH RFC v3 18/88] KVM: selftests: Document testing TODOs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-18-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1090;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=r1ZmFiR1qPCCBxX8ciGCFcsvJLc5HDkv8vhs7vVOKUw=;
 b=6pZvfbTvHbGzO6Z9YIneIq3T90JrEFZL7fDyOhT8/iiNQMcWLUJ/EJt5W2PPBe1GU4JzzYZmE
 4L1rjvsT8X5BB33CyQAYR6oIMcuTNN3d2fOXsyT2kk5AxXVOgIZJjzF
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remind myself about all the tests (A)I did not write.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 8e9261db23354..fd249445ce3cc 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -701,6 +701,16 @@ static void test_guest_memfd(unsigned long vm_type)
 
 	test_guest_memfd_flags(vm);
 
+	/*
+	 * TODO: Test that guest_memfd creation rejects a read-only tmpfs mount
+	 * (e.g. MOUNT_ATTR_RDONLY) with EROFS.
+	 *
+	 * TODO: Test that guest_memfd creation rejects an ID-mapped tmpfs mount
+	 * (e.g. MOUNT_ATTR_IDMAP) lacking write or execute/search permissions
+	 * with EACCES.
+	 *
+	 * TODO: Test mpol fallback to mount config.
+	 */
 	test_resource_fd_invalid(vm);
 	test_resource_fd_unsupported_fs(vm);
 	test_resource_fd_memfd(vm);

-- 
2.56.0.455.g6c5a503b38-goog

