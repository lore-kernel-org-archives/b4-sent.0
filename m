From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v3 0/2] mm/vmalloc: free unused pages on vrealloc() shrink
Date: Mon, 09 Mar 2026 17:25:44 +0530
Message-Id: <20260309-vmalloc-shrink-v3-0-5590fd8de2eb@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEC1rmkC/3XMQQ7CIBCF4as0rMUMU8TqynsYF7QFmVjBgCFq0
 7tLu9IYl/9L3jeyZCKZxPbVyKLJlCj4EvWqYp3T/mw49aUZAiqoAXm+6mEIHU8ukr9wkC1arZp
 GC8nK6RaNpccCHk+lHaV7iM/Fz2Je/1JZcOBS9cZaqTbt1hxewYWrpmFNns1Yxk9A/gBYAGw63
 IlegQD4BqZpegNFkO427wAAAA==
X-Change-ID: 20260302-vmalloc-shrink-04b2fa688a14
To: Andrew Morton <akpm@linux-foundation.org>, 
 Uladzislau Rezki <urezki@gmail.com>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Alice Ryhl <aliceryhl@google.com>, Danilo Krummrich <dakr@kernel.org>, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773057354; l=2366;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=jlu8U+9Fzz1mb0zaTPT4T2YTs5PlfD7vbOcNzJEvn7w=;
 b=5pgfQzbKvodieJzhPogRQRGbYfEQ4jxUYsqRmvYl16Gp94uAeLz/QVgaiz2d8T1KReTIewEJc
 x3Oe+2Rl5UwCpZL+iiw47sfuk6P0adKOWiCAqe6v0Y+zRc+tBLgwMy5
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
Changes in v3:
- Restore the comment.
- Rebase to the latest mm-new 
- Link to v2: https://lore.kernel.org/r/20260304-vmalloc-shrink-v2-0-28c291d60100@zohomail.in

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

 mm/vmalloc.c | 65 ++++++++++++++++++++++++++++++++++++++++++------------------
 1 file changed, 46 insertions(+), 19 deletions(-)
---
base-commit: f27e4dd73ee9b64177649a1490fa20288e0de94a
change-id: 20260302-vmalloc-shrink-04b2fa688a14

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

