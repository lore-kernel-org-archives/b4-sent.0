From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:50 -0800
Subject: [PATCH RFC v3 16/88] KVM: selftests: Test that shared tmpfs
 resource pool size limit is respected
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-16-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=1067;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=NSNZp2TvUElTKQXMVaHgiSKEMn4WansSyP3qnP7lAE4=;
 b=TzAIr6cJe10IhPRtWsxgFp+NaYLpK7zef9IbjbEjVnmlhCYeSKRyS2vMmwoTfTHH/N/TeLBqI
 KF1EnJPBXCABQ4b8FSTXK49EUlCJHblKHNv0GHCSAiZkoYJ+Zw2o9za
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verify that allocating memory across guest_memfd instances sharing a
tmpfs resource pool fails with ENOSPC when the total allocation exceeds
the pool capacity.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/kvm/guest_memfd_test.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/tools/testing/selftests/kvm/guest_memfd_test.c b/tools/testing/selftests/kvm/guest_memfd_test.c
index 639b1b0c204ed..20de24ad535f1 100644
--- a/tools/testing/selftests/kvm/guest_memfd_test.c
+++ b/tools/testing/selftests/kvm/guest_memfd_test.c
@@ -604,6 +604,10 @@ static void test_resource_fd_tmpfs_shared_pool(struct kvm_vm *vm)
 	TEST_ASSERT(!fstatvfs(pool_fd, &svfs), "fstatvfs on pool_fd should succeed");
 	TEST_ASSERT_EQ(svfs.f_blocks - svfs.f_bfree, 2);
 
+	ret = fallocate(fd2, FALLOC_FL_KEEP_SIZE, page_size, page_size);
+	TEST_ASSERT(ret < 0, "fallocate exceeding pool capacity should fail");
+	TEST_ASSERT_EQ(errno, ENOSPC);
+
 	close(fd2);
 	close(fd1);
 	close(pool_fd);

-- 
2.56.0.455.g6c5a503b38-goog

