From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:01 -0800
Subject: [PATCH RFC v3 27/88] KVM: selftests: Test marking page ranges
 read-only
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-27-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=3249;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=XtGmSBvwOq6lpm/Qp7pMrqoe2YFfpDhrMdOnKzGerIY=;
 b=RXpFZ/blAE/3OlyVi7XMW2Xei66nvIUzHHFOSfE75D2vfh85PBi5IfkkJ+1wpMS4aYJ6CUKUq
 34KHhBOxIVrCRV7i1xAF5/fCYc/JXC3BQwLYdYffAjRGjZyv6UyUMx4
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test dynamically marking page ranges read-only and writable via the
sample memory provider interface.

Verify changing page write permissions and ensure that read-only page
counts in statistics reflect each change accurately.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/mem_provider_sample_test.c       | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/tools/testing/selftests/kvm/mem_provider_sample_test.c b/tools/testing/selftests/kvm/mem_provider_sample_test.c
index 8fe634b0b4f2e..942c0519836de 100644
--- a/tools/testing/selftests/kvm/mem_provider_sample_test.c
+++ b/tools/testing/selftests/kvm/mem_provider_sample_test.c
@@ -136,6 +136,70 @@ static void test_set_present(int dev_fd)
 	close(fd);
 }
 
+static void test_set_readonly(int dev_fd)
+{
+	size_t page_size = getpagesize();
+	uint64_t nr_pages = 4;
+	uint64_t file_size = nr_pages * page_size;
+	struct mp_set_readonly sr;
+	struct mp_stats st;
+	int ret, fd;
+
+	fd = create_provider_file(dev_fd, file_size);
+
+	/* Initially all pages are writable */
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.readonly_pages == 0,
+		    "Initial readonly_pages mismatch: expected 0, got %llu",
+		    st.readonly_pages);
+
+	/* Mark page 1 read-only */
+	memset(&sr, 0, sizeof(sr));
+	sr.value = 1;
+	sr.offset = page_size;
+	sr.len = page_size;
+	ret = ioctl(fd, MP_SET_READONLY, &sr);
+	TEST_ASSERT(!ret, "MP_SET_READONLY (read-only) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.size == file_size,
+		    "size changed unexpectedly: 0x%llx", st.size);
+	TEST_ASSERT(st.readonly_pages == 1,
+		    "readonly_pages mismatch after read-only: expected 1, got %llu",
+		    st.readonly_pages);
+
+	/* Mark page 1 back to writable */
+	sr.value = 0;
+	ret = ioctl(fd, MP_SET_READONLY, &sr);
+	TEST_ASSERT(!ret, "MP_SET_READONLY (writable) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.readonly_pages == 0,
+		    "readonly_pages mismatch after writable: expected 0, got %llu",
+		    st.readonly_pages);
+
+	/* Mark all pages read-only */
+	sr.value = 1;
+	sr.offset = 0;
+	sr.len = file_size;
+	ret = ioctl(fd, MP_SET_READONLY, &sr);
+	TEST_ASSERT(!ret, "MP_SET_READONLY (all read-only) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.readonly_pages == nr_pages,
+		    "readonly_pages mismatch after all read-only: expected %lu, got %llu",
+		    nr_pages, st.readonly_pages);
+
+	close(fd);
+}
+
 int main(int argc, char *argv[])
 {
 	int dev_fd;
@@ -144,6 +208,7 @@ int main(int argc, char *argv[])
 
 	test_lifecycle_and_creation(dev_fd);
 	test_set_present(dev_fd);
+	test_set_readonly(dev_fd);
 
 	close(dev_fd);
 	return 0;

-- 
2.56.0.455.g6c5a503b38-goog

