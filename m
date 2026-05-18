From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 18 May 2026 11:17:37 -0700
Subject: [PATCH RFC 5/5] mm: selftests: Port readback test logic from
 libhugetlbfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-port-hugetlb-selftests-v1-5-d64ba3a785fe@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=1602;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=89off7URPXKpNOqQZuCiXrCqLPNnXfaicuty8kmghyM=;
 b=2EmdrC/gCQ3MioA72AfovP0JnhYZTfmTmBwAMfNu2EP7oCwZxCKgxIPZaCXufUhQE+ZEiaPpM
 EdlNF/U6uRBBLfpGgRNE33I/AxPAC835iYY/3i4b0CTZgeAgV36UEn3
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Port verification logic from libhugetlbfs' tests/readback.c.

Iterate using an unsigned int pointer instead of a char pointer, which
enables testing against a greater range of stored values beyond [0, 255].

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/mm/hugepage-mmap.c | 16 +++++++++-------
 1 file changed, 9 insertions(+), 7 deletions(-)

diff --git a/tools/testing/selftests/mm/hugepage-mmap.c b/tools/testing/selftests/mm/hugepage-mmap.c
index dd9fccb209b10..a7d4a3eba3dd7 100644
--- a/tools/testing/selftests/mm/hugepage-mmap.c
+++ b/tools/testing/selftests/mm/hugepage-mmap.c
@@ -45,7 +45,7 @@ enum fd_kind {
 FIXTURE(hugepage_mmap)
 {
 	int fd;
-	char *addr;
+	unsigned int *addr;
 	char mount_dir[PATH_MAX];
 };
 
@@ -122,19 +122,21 @@ FIXTURE_TEARDOWN(hugepage_mmap)
 	}
 }
 
+#define RANDOM_CONSTANT 0x1234ABCD
+
 TEST_F(hugepage_mmap, read_write)
 {
 	unsigned long i;
 
-	TH_LOG("First hex is %x", *((unsigned int *)self->addr));
+	TH_LOG("First hex is %x", *self->addr);
 
-	for (i = 0; i < LENGTH; i++)
-		self->addr[i] = (char)i;
+	for (i = 0; i < LENGTH / sizeof(*self->addr); i++)
+		self->addr[i] = RANDOM_CONSTANT ^ i;
 
-	TH_LOG("First hex is %x", *((unsigned int *)self->addr));
+	TH_LOG("First hex is %x", *self->addr);
 
-	for (i = 0; i < LENGTH; i++) {
-		ASSERT_EQ(self->addr[i], (char)i) {
+	for (i = 0; i < LENGTH / sizeof(*self->addr); i++) {
+		ASSERT_EQ(self->addr[i], RANDOM_CONSTANT ^ i) {
 			TH_LOG("Error: Mismatch at %lu\n", i);
 		};
 	}

-- 
2.54.0.563.g4f69b47b94-goog

