From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:37:00 -0800
Subject: [PATCH RFC v3 26/88] KVM: selftests: Test marking page ranges
 present and absent
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-26-8484dde66a7e@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=3215;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=7QFJFoFyo46UmZUpk/RDNGh2vejWq8fPg2Gg5WaYGKY=;
 b=ohlAxuF/ZwnJnySiSieqvLG3K3rQ2HRF2CfC9ljofHA8P0oU4N4eE4ebYlYM9FPPevFAFBfew
 2jjSIdh2dl6D92vo4evhVx/SgIK++1Q/1C6fef7z+b8ldarmKvndCR9
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Test dynamically changing page presence in provider files via the
sample memory provider interface.

Verify marking pages absent and restoring them back to present, ensuring
that absent page counts in statistics reflect each change accurately.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 .../selftests/kvm/mem_provider_sample_test.c       | 65 ++++++++++++++++++++++
 1 file changed, 65 insertions(+)

diff --git a/tools/testing/selftests/kvm/mem_provider_sample_test.c b/tools/testing/selftests/kvm/mem_provider_sample_test.c
index b39161f4933d3..8fe634b0b4f2e 100644
--- a/tools/testing/selftests/kvm/mem_provider_sample_test.c
+++ b/tools/testing/selftests/kvm/mem_provider_sample_test.c
@@ -72,6 +72,70 @@ static void test_lifecycle_and_creation(int dev_fd)
 	}
 }
 
+static void test_set_present(int dev_fd)
+{
+	size_t page_size = getpagesize();
+	uint64_t nr_pages = 4;
+	uint64_t file_size = nr_pages * page_size;
+	struct mp_set_present sp;
+	struct mp_stats st;
+	int ret, fd;
+
+	fd = create_provider_file(dev_fd, file_size);
+
+	/* Initially all pages are present */
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == 0,
+		    "Initial absent_pages mismatch: expected 0, got %llu",
+		    st.absent_pages);
+
+	/* Mark page 1 absent */
+	memset(&sp, 0, sizeof(sp));
+	sp.value = 0;
+	sp.offset = page_size;
+	sp.len = page_size;
+	ret = ioctl(fd, MP_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MP_SET_PRESENT (absent) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.size == file_size,
+		    "size changed unexpectedly: 0x%llx", st.size);
+	TEST_ASSERT(st.absent_pages == 1,
+		    "absent_pages mismatch after absent: expected 1, got %llu",
+		    st.absent_pages);
+
+	/* Mark page 1 back to present */
+	sp.value = 1;
+	ret = ioctl(fd, MP_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MP_SET_PRESENT (present) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == 0,
+		    "absent_pages mismatch after restore: expected 0, got %llu",
+		    st.absent_pages);
+
+	/* Mark all pages absent */
+	sp.value = 0;
+	sp.offset = 0;
+	sp.len = file_size;
+	ret = ioctl(fd, MP_SET_PRESENT, &sp);
+	TEST_ASSERT(!ret, "MP_SET_PRESENT (all absent) failed: %d (%s)",
+		    errno, strerror(errno));
+
+	TEST_ASSERT(!ioctl(fd, MP_GET_STATS, &st),
+		    "MP_GET_STATS failed: %d (%s)", errno, strerror(errno));
+	TEST_ASSERT(st.absent_pages == nr_pages,
+		    "absent_pages mismatch after all absent: expected %lu, got %llu",
+		    nr_pages, st.absent_pages);
+
+	close(fd);
+}
+
 int main(int argc, char *argv[])
 {
 	int dev_fd;
@@ -79,6 +143,7 @@ int main(int argc, char *argv[])
 	dev_fd = open_provider_dev();
 
 	test_lifecycle_and_creation(dev_fd);
+	test_set_present(dev_fd);
 
 	close(dev_fd);
 	return 0;

-- 
2.56.0.455.g6c5a503b38-goog

