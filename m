From: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
Date: Wed, 28 May 2025 15:15:39 +0100
Subject: [PATCH] tools/testing/vma: add missing function stub
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250528-fix-vma-test-v1-1-c8a5f533b38f@oracle.com>
X-B4-Tracking: v=1; b=H4sIAIoaN2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDUyML3bTMCt2y3ETdktTiEl1T8yRDY4s0I4s0EzMloJaColSgPNi46Nj
 aWgBi0eRgXgAAAA==
X-Change-ID: 20250528-fix-vma-test-57b138f28f46
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@suse.cz>, Jann Horn <jannh@google.com>, 
 Pedro Falcato <pfalcato@suse.de>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1135;
 i=lorenzo.stoakes@oracle.com; h=from:subject:message-id;
 bh=/hWcNyu2zzVdPtWKaUfZnsHVgBszi7eCqsh7pAsYZzg=;
 b=owGbwMvMwCUmzHegU0pdXZrxtFoSQ4a51Iwc4TXuqSqOcrbiiccWGMd4nwi7cCZ+zctrbQE/v
 ldHFU/sKGVhEONikBVTZDlcaRzdE7ii7ojXo0yYOaxMIEMYuDgFYCLbNzEyrLyw98zFvw9i+V4G
 vqiOOf/6x7RIl2cvmMVWS8k0nG179IGR4Z/AucNunizR/YtdqrsjOWUl3s0703VzacOL3RIxQnb
 z+QE=
X-Developer-Key: i=lorenzo.stoakes@oracle.com; a=openpgp;
 fpr=5BEF5562908102FB56727B7CC52D7AFE85F25509
X-Endpoint-Received: by B4 Relay for lorenzo.stoakes@oracle.com/default with auth_id=414
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hugetlb fix introduced in commit ee40c9920ac2 ("mm: fix copy_vma()
error handling for hugetlb mappings") mistakenly did not provide a stub for
the VMA userland testing, which results in a compile error when trying to
build this.

Provide this stub to resolve the issue.

---
Signed-off-by: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
---
 tools/testing/vma/vma_internal.h | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/tools/testing/vma/vma_internal.h b/tools/testing/vma/vma_internal.h
index f6e45e62da3a6ee007b7431573f27ef5c2533865..441feb21aa5a92b7edddb07258c7f368171de15b 100644
--- a/tools/testing/vma/vma_internal.h
+++ b/tools/testing/vma/vma_internal.h
@@ -1461,4 +1461,9 @@ static inline int __call_mmap_prepare(struct file *file,
 	return file->f_op->mmap_prepare(desc);
 }
 
+static inline void fixup_hugetlb_reservations(struct vm_area_struct *vma)
+{
+	(void)vma;
+}
+
 #endif	/* __MM_VMA_INTERNAL_H */

---
base-commit: 1637eadc7fdf2fa4069a149b1e836656a3b64150
change-id: 20250528-fix-vma-test-57b138f28f46

Best regards,
-- 
Lorenzo Stoakes <lorenzo.stoakes@oracle.com>

