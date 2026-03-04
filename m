From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v2 0/2] mm/vmalloc: free unused pages on vrealloc() shrink
Date: Wed, 04 Mar 2026 20:23:14 +0530
Message-Id: <20260304-vmalloc-shrink-v2-0-28c291d60100@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFpHqGkC/3XMQQ7CIBCF4as0sxYDiNi48h6mC9oOMpGCAUPUh
 ruL3bv8X/K+FTImwgznboWEhTLF0ELuOpicCTdkNLcGyaXmBy5ZWYz3cWLZJQp3xtUordF9b4S
 CdnoktPTawOvQ2lF+xvTe/CJ+61+qCMaZ0jNaq/RxPOHlE11cDPk9BRhqrV+Po5ObrgAAAA==
X-Change-ID: 20260302-vmalloc-shrink-04b2fa688a14
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772636006; l=2197;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=nhkia8GqDvxaObq8yMuYcab15Z0X2JGKN5fmCCeEHrM=;
 b=WokF0sCgUwyf1aDiiT0AE891J1ZLYuVqXissd55LWAov7k9BR1j+SMo2VdZ0ze6Hwq0leaQhK
 ys1hGxddy3SBn5kuFAbwLyxOyRHbo5m+9x1ed7E0F2AHRMsWk8GZhbr
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series implements the TODO in vrealloc() to unmap and free unused
pages when shrinking across a page boundary.

Problem:
When vrealloc() shrinks an allocation, it updates bookkeeping
(requested_size, KASAN shadow) but does not free the underlying physical
pages. This wastes memory for the lifetime of the allocation.

Solution:
- Patch 1: Extracts a vmalloc_free_pages(vm, start, end) helper from
  vfree() that frees a range of pages with memcg and nr_vmalloc_pages
  accounting. Pure refactor, no functional change.
- Patch 2: Uses the helper to free tail pages when vrealloc() shrinks
  across a page boundary. Skips huge page allocations (page_order > 0)
  since compound pages cannot be partially freed. Also fixes the
  grow-in-place path to check vm->nr_pages instead of
  get_vm_area_size(), which reflects the virtual reservation and does
  not change on shrink.
The virtual address reservation is kept intact to preserve the range
for potential future grow-in-place support.
A concrete user is the Rust binder driver's KVVec::shrink_to [1], which
performs explicit vrealloc() shrinks for memory reclamation.

Tested:
- KASAN KUnit (vmalloc_oob passes)
- lib/test_vmalloc stress tests (3/3, 1M iterations each)
- checkpatch, sparse, W=1, allmodconfig, coccicheck clean

[1] https://lore.kernel.org/all/20260216-binder-shrink-vec-v3-v6-0-ece8e8593e53@zohomail.in/

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Changes in v2:
- Updated the base-commit to mm-new
- Fix conflicts after rebase
- Ran `clang-format` on the changes made
- Use a single `kasan_vrealloc` (Alice Ryhl)
- Link to v1: https://lore.kernel.org/r/20260302-vmalloc-shrink-v1-0-46deff465b7e@zohomail.in

---
Shivam Kalra (2):
      mm/vmalloc: extract vmalloc_free_pages() helper from vfree()
      mm/vmalloc: free unused pages on vrealloc() shrink

 mm/vmalloc.c | 61 +++++++++++++++++++++++++++++++++++++++++-------------------
 1 file changed, 42 insertions(+), 19 deletions(-)
---
base-commit: 2bff1816949a0849a384ed3cc66c8385d9590861
change-id: 20260302-vmalloc-shrink-04b2fa688a14

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

