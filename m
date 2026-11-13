From: Kairui Song <kasong@tencent.com>
Date: Sat, 14 Nov 2026 05:26:17 +0800
Subject: [PATCH RFC 1/8] mm: add folio_prev()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261114-swap-thp-split-v1-1-dfa8d4fa448d@tencent.com>
References: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
In-Reply-To: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
To: linux-mm@kvack.org
Cc: David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Matthew Wilcox <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Zi Yan <ziy@nvidia.com>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=2033;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=8U+vChwHY7bImKDhKYpDCcJf0GyjeC844R7WWMIwhQE=;
 b=bwhRW6oU8F0MtgXSJAnvYmhFawAQqpNqSAeZ2CULRpOAFzH0mFOKzLo2F/+QLfhx2XXIX4rwT
 ElUU4af3Wo1CMV9aLfBV4At7whxEIEoMjum5LCSYHN1XJI4QoArc9Pf
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is similar to folio_next(). But to get the head of the previous
folio, the compound info of the current folio isn't helpful. So here just
retrieve the previous page frame's compound info instead.

This creates a nice side effect that we don't require the current folio
to be still valid as we don't need any info from it and @folio is never
dereferenced, just pointer arithmetic.

The caller has to ensure the previous folio is legal though, as there
is no reliable way to tell from @folio whether one exists.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
 include/linux/mm.h | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/include/linux/mm.h b/include/linux/mm.h
index 77b5d450fe45..5b529bc6624f 100644
--- a/include/linux/mm.h
+++ b/include/linux/mm.h
@@ -3076,6 +3076,29 @@ static inline struct folio *folio_next(struct folio *folio)
 	return (struct folio *)folio_page(folio, folio_nr_pages(folio));
 }
 
+/**
+ * folio_prev - Move to the previous physical folio.
+ * @folio: The folio we're currently operating on.
+ *
+ * The inverse of folio_next().  Use it to move from one folio to the
+ * previous one in physically contiguous memory which may span more than
+ * one folio.  Do not use it if the memory is only virtually contiguous.
+ * This is the folio equivalent to writing ``page--``.
+ *
+ * The caller has to ensure the previous folio is legal; there is no way
+ * to tell from @folio whether one exists.  @folio itself is never
+ * dereferenced, only the page preceding it, so it may be a sentinel
+ * pointer instead of a folio.
+ *
+ * Context: We assume that the folios are refcounted and/or locked at a
+ * higher level and do not adjust the reference counts.
+ * Return: The previous struct folio.
+ */
+static inline struct folio *folio_prev(struct folio *folio)
+{
+	return page_folio(&folio->page - 1);
+}
+
 /**
  * folio_shift - The size of the memory described by this folio.
  * @folio: The folio.

-- 
2.56.1

