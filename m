From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 18 May 2026 11:17:35 -0700
Subject: [PATCH RFC 3/5] mm: selftests: Refactor hugepage-mmap to use
 kselftest harness
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-port-hugetlb-selftests-v1-3-d64ba3a785fe@google.com>
References: <20260518-port-hugetlb-selftests-v1-0-d64ba3a785fe@google.com>
In-Reply-To: <20260518-port-hugetlb-selftests-v1-0-d64ba3a785fe@google.com>
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Shuah Khan <shuah@kernel.org>, 
 muchun.song@linux.dev, osalvador@suse.de
Cc: linux-mm@kvack.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=2847;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=+iX/sXuCWZ7Cvdfn9EiGTfuvG8jGBSzvIKiil83JdTo=;
 b=cCP3PNDbEeViZeHLywrqRCI3U02IjNAxaY6JYUaLkxHKd7lXQu1aRkOkIki96+D7u+Eg7seg3
 Ck69Pd15PnTCJdoyr6CcFCDPFOqZ+N4TulPvxistfAsTOhpiopVYqat
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Refactor hugepage-mmap.c to use the kselftest harness so that a later patch
can add a different setup flow.

Use a fixture for managing the hugetlbfs-backed memfd lifecycle (setup and
teardown).

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/mm/hugepage-mmap.c | 67 ++++++++++++++++--------------
 1 file changed, 36 insertions(+), 31 deletions(-)

diff --git a/tools/testing/selftests/mm/hugepage-mmap.c b/tools/testing/selftests/mm/hugepage-mmap.c
index 64f7d28a97fdf..9c8a0638d04b8 100644
--- a/tools/testing/selftests/mm/hugepage-mmap.c
+++ b/tools/testing/selftests/mm/hugepage-mmap.c
@@ -15,49 +15,54 @@
 #include <unistd.h>
 #include <sys/mman.h>
 #include <fcntl.h>
-#include "kselftest.h"
+#include "kselftest_harness.h"
 
 #define LENGTH (256UL*1024*1024)
 #define PROTECTION (PROT_READ | PROT_WRITE)
 
-int main(void)
+FIXTURE(hugepage_mmap)
 {
-	void *addr;
-	int fd, ret = 0;
-	unsigned long i;
-
-	ksft_print_header();
-	ksft_set_plan(1);
+	int fd;
+	char *addr;
+};
 
-	fd = memfd_create("hugepage-mmap", MFD_HUGETLB);
-	if (fd < 0)
-		ksft_exit_fail_msg("memfd_create() failed: %s\n", strerror(errno));
+FIXTURE_SETUP(hugepage_mmap)
+{
+	self->fd = memfd_create("hugepage-mmap", MFD_HUGETLB);
+	ASSERT_GE(self->fd, 0) {
+		TH_LOG("memfd_create() failed: %s", strerror(errno));
+	}
 
-	addr = mmap(NULL, LENGTH, PROTECTION, MAP_SHARED, fd, 0);
-	if (addr == MAP_FAILED) {
-		close(fd);
-		ksft_exit_fail_msg("mmap(): %s\n", strerror(errno));
+	self->addr = mmap(NULL, LENGTH, PROTECTION, MAP_SHARED, self->fd, 0);
+	ASSERT_NE(MAP_FAILED, self->addr) {
+		TH_LOG("mmap(): %s", strerror(errno));
+		close(self->fd);
 	}
+	TH_LOG("Returned address is %p", self->addr);
+}
 
-	ksft_print_msg("Returned address is %p\n", addr);
-	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
+FIXTURE_TEARDOWN(hugepage_mmap)
+{
+	munmap(self->addr, LENGTH);
+	close(self->fd);
+}
 
-	for (i = 0; i < LENGTH; i++)
-		*(char *)(addr + i) = (char)i;
+TEST_F(hugepage_mmap, read_write)
+{
+	unsigned long i;
 
-	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
-	for (i = 0; i < LENGTH; i++) {
-		if (*(char *)(addr + i) != (char)i) {
-			ksft_print_msg("Error: Mismatch at %lu\n", i);
-			ret = 1;
-			break;
-		}
-	}
+	TH_LOG("First hex is %x", *((unsigned int *)self->addr));
 
-	munmap(addr, LENGTH);
-	close(fd);
+	for (i = 0; i < LENGTH; i++)
+		self->addr[i] = (char)i;
 
-	ksft_test_result(!ret, "Read same data\n");
+	TH_LOG("First hex is %x", *((unsigned int *)self->addr));
 
-	ksft_exit(!ret);
+	for (i = 0; i < LENGTH; i++) {
+		ASSERT_EQ(self->addr[i], (char)i) {
+			TH_LOG("Error: Mismatch at %lu\n", i);
+		};
+	}
 }
+
+TEST_HARNESS_MAIN

-- 
2.54.0.563.g4f69b47b94-goog

