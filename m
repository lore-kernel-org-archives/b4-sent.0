From: Ackerley Tng <ackerleytng@google.com>
Date: Mon, 18 May 2026 11:17:33 -0700
Subject: [PATCH RFC 1/5] mm: selftests: Inline check_bytes() function into
 caller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260518-port-hugetlb-selftests-v1-1-d64ba3a785fe@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779128265; l=1508;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=ojhFIsSt5J/Ln9Qe8lS4lDGB7t2xMx2nI91/0IgGnFg=;
 b=aCFGbDzyqxAT6wHgkBwWRA+y1A982R53xn0sOG+7hlA8GCoWXFQxD8QyELbiTEhSynpWciYyf
 8NJ5sYUzWfbAuyRupSfrHOzNUScKBzd0pxj9IFOKrSOl1MraP43NkT/
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inline the check_bytes() function to prepare for using the kselftest
harness, where TH_LOG() relies on the variable _metadata being present in
the caller.

Instead of passing _metadata to a helper function like check_bytes(), call
TH_LOG() directly.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 tools/testing/selftests/mm/hugepage-mmap.c | 9 ++-------
 1 file changed, 2 insertions(+), 7 deletions(-)

diff --git a/tools/testing/selftests/mm/hugepage-mmap.c b/tools/testing/selftests/mm/hugepage-mmap.c
index d543419de0407..8c246070572f9 100644
--- a/tools/testing/selftests/mm/hugepage-mmap.c
+++ b/tools/testing/selftests/mm/hugepage-mmap.c
@@ -20,11 +20,6 @@
 #define LENGTH (256UL*1024*1024)
 #define PROTECTION (PROT_READ | PROT_WRITE)
 
-static void check_bytes(char *addr)
-{
-	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
-}
-
 static void write_bytes(char *addr)
 {
 	unsigned long i;
@@ -37,7 +32,7 @@ static int read_bytes(char *addr)
 {
 	unsigned long i;
 
-	check_bytes(addr);
+	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
 	for (i = 0; i < LENGTH; i++)
 		if (*(addr + i) != (char)i) {
 			ksft_print_msg("Error: Mismatch at %lu\n", i);
@@ -65,7 +60,7 @@ int main(void)
 	}
 
 	ksft_print_msg("Returned address is %p\n", addr);
-	check_bytes(addr);
+	ksft_print_msg("First hex is %x\n", *((unsigned int *)addr));
 	write_bytes(addr);
 	ret = read_bytes(addr);
 

-- 
2.54.0.563.g4f69b47b94-goog

