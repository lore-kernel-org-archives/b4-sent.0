From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 18 May 2026 11:17:34 -0700
Subject: [PATCH RFC 2/5] mm: selftests: Inline {read,write}_bytes functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-port-hugetlb-selftests-v1-2-d64ba3a785fe@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=1888;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=3vqV15tnc/KP7l17CqT82I3LVdfcrBoQAIsUGRd62xc=;
 b=8wRWXv6/rOnk4l6CutfsJgow0n6eIr/AsAi5gOQiNeOSPDM5g7SuG9MmaRX7tv6dn3aqhQhb+
 PQUacAigGvODbw69xP477YxGOx0ttnT+euh7SJS2UaNIeMbKaErkZ1g
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the kselftest_harness is used in a later patch, making assertions like
ASSERT_EQ() relies on _metadata's existence at the macro site, hence using
helper functions makes it more complicated.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/mm/hugepage-mmap.c | 38 +++++++++++-------------------
 1 file changed, 14 insertions(+), 24 deletions(-)

diff --git a/tools/testing/selftests/mm/hugepage-mmap.c b/tools/testing/selftests/mm/hugepage-mmap.c
index 8c246070572f9..64f7d28a97fdf 100644
--- a/tools/testing/selftests/mm/hugepage-mmap.c
+++ b/tools/testing/selftests/mm/hugepage-mmap.c
@@ -20,31 +20,11 @@
 #define LENGTH (256UL*1024*1024)
 #define PROTECTION (PROT_READ | PROT_WRITE)
 
-static void write_bytes(char *addr)
-{
-	unsigned long i;
-
-	for (i = 0; i < LENGTH; i++)
-		*(addr + i) = (char)i;
-}
-
-static int read_bytes(char *addr)
-{
-	unsigned long i;
-
-	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
-	for (i = 0; i < LENGTH; i++)
-		if (*(addr + i) != (char)i) {
-			ksft_print_msg("Error: Mismatch at %lu\n", i);
-			return 1;
-		}
-	return 0;
-}
-
 int main(void)
 {
 	void *addr;
-	int fd, ret;
+	int fd, ret = 0;
+	unsigned long i;
 
 	ksft_print_header();
 	ksft_set_plan(1);
@@ -61,8 +41,18 @@ int main(void)
 
 	ksft_print_msg("Returned address is %p\n", addr);
 	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
-	write_bytes(addr);
-	ret = read_bytes(addr);
+
+	for (i = 0; i < LENGTH; i++)
+		*(char *)(addr + i) = (char)i;
+
+	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
+	for (i = 0; i < LENGTH; i++) {
+		if (*(char *)(addr + i) != (char)i) {
+			ksft_print_msg("Error: Mismatch at %lu\n", i);
+			ret = 1;
+			break;
+		}
+	}
 
 	munmap(addr, LENGTH);
 	close(fd);

-- 
2.54.0.563.g4f69b47b94-goog

