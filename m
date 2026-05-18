From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 18 May 2026 11:17:36 -0700
Subject: [PATCH RFC 4/5] mm: selftests: Update hugepage-mmap to support
 hugetlbfs mount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-port-hugetlb-selftests-v1-4-d64ba3a785fe@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=3375;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=UohDzF0IDPJpVfS8tMj24WgpCofY5vpUdRHF24vk2iU=;
 b=5uxe5mBqfzQ1SIKIcquQms4vhqqdYB3BUyQSZlrS81kmhC9iHur6Z1P4KUT/FsGZeEPqSznpj
 duVeqsyGbkjAeZx/X2wU4RhXQfpUX9wLvfFv9lFXFBOjzJc+o3dh6gl
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Run the same write/read test for a file on a hugetlbfs mount, in addition
to a memfd.

Use FIXTURE_VARIANT for parametrized testing. Use an unlinked fd to make
save cleanup steps later.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/mm/hugepage-mmap.c | 85 ++++++++++++++++++++++++++++--
 1 file changed, 80 insertions(+), 5 deletions(-)

diff --git a/tools/testing/selftests/mm/hugepage-mmap.c b/tools/testing/selftests/mm/hugepage-mmap.c
index 9c8a0638d04b8..dd9fccb209b10 100644
--- a/tools/testing/selftests/mm/hugepage-mmap.c
+++ b/tools/testing/selftests/mm/hugepage-mmap.c
@@ -15,36 +15,111 @@
 #include <unistd.h>
 #include <sys/mman.h>
 #include <fcntl.h>
+#include <sys/mount.h>
+#include <sys/stat.h>
+#include <limits.h>
 #include "kselftest_harness.h"
 
+static int hugetlbfs_unlinked_fd(const char *mount)
+{
+	char path[PATH_MAX];
+	int fd;
+
+	snprintf(path, sizeof(path), "%s/hugepage-mmap-XXXXXX", mount);
+	fd = mkstemp(path);
+	if (fd < 0)
+		return fd;
+
+	unlink(path);
+	return fd;
+}
+
 #define LENGTH (256UL*1024*1024)
 #define PROTECTION (PROT_READ | PROT_WRITE)
 
+enum fd_kind {
+	MEMFD,
+	HUGETLBFS_FD,
+};
+
 FIXTURE(hugepage_mmap)
 {
 	int fd;
 	char *addr;
+	char mount_dir[PATH_MAX];
+};
+
+static int fd_create(struct __test_metadata *_metadata,
+		FIXTURE_DATA(hugepage_mmap) *self, enum fd_kind fd_kind)
+{
+	switch (fd_kind) {
+	case MEMFD:
+		return memfd_create("hugepage-mmap", MFD_HUGETLB);
+	case HUGETLBFS_FD: {
+		snprintf(self->mount_dir, sizeof(self->mount_dir),
+			 "/tmp/hugepage-mmap-XXXXXX");
+		ASSERT_NE(NULL, mkdtemp(self->mount_dir))
+		{
+			TH_LOG("mkdtemp() failed: %s", strerror(errno));
+		}
+		ASSERT_EQ(0, mount("none", self->mount_dir, "hugetlbfs", 0,
+				   "pagesize=2M"))
+		{
+			TH_LOG("mount() failed: %s", strerror(errno));
+		}
+		return hugetlbfs_unlinked_fd(self->mount_dir);
+	}
+	default:
+		return -1;
+	};
+}
+
+FIXTURE_VARIANT(hugepage_mmap)
+{
+	enum fd_kind fd_kind;
+};
+
+FIXTURE_VARIANT_ADD(hugepage_mmap, memfd)
+{
+	.fd_kind = MEMFD,
+};
+
+FIXTURE_VARIANT_ADD(hugepage_mmap, hugetlbfs_fd)
+{
+	.fd_kind = HUGETLBFS_FD,
 };
 
 FIXTURE_SETUP(hugepage_mmap)
 {
-	self->fd = memfd_create("hugepage-mmap", MFD_HUGETLB);
+	self->fd = -1;
+	self->addr = MAP_FAILED;
+	self->mount_dir[0] = '\0';
+	/* Enable teardown to cleanup on any assertions in FIXTURE_SETUP(). */
+	*_metadata->no_teardown = false;
+
+	self->fd = fd_create(_metadata, self, variant->fd_kind);
 	ASSERT_GE(self->fd, 0) {
-		TH_LOG("memfd_create() failed: %s", strerror(errno));
+		TH_LOG("fd creation failed: %s", strerror(errno));
 	}
 
 	self->addr = mmap(NULL, LENGTH, PROTECTION, MAP_SHARED, self->fd, 0);
 	ASSERT_NE(MAP_FAILED, self->addr) {
 		TH_LOG("mmap(): %s", strerror(errno));
-		close(self->fd);
 	}
 	TH_LOG("Returned address is %p", self->addr);
 }
 
 FIXTURE_TEARDOWN(hugepage_mmap)
 {
-	munmap(self->addr, LENGTH);
-	close(self->fd);
+	if (self->addr != MAP_FAILED)
+		munmap(self->addr, LENGTH);
+	if (self->fd >= 0)
+		close(self->fd);
+
+	if (variant->fd_kind == HUGETLBFS_FD && self->mount_dir[0]) {
+		umount(self->mount_dir);
+		rmdir(self->mount_dir);
+	}
 }
 
 TEST_F(hugepage_mmap, read_write)

-- 
2.54.0.563.g4f69b47b94-goog

