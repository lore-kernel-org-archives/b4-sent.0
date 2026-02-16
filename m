From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v6 0/3] rust: alloc: add KVVec shrinking method
Date: Mon, 16 Feb 2026 19:39:54 +0530
Message-Id: <20260216-binder-shrink-vec-v3-v6-0-ece8e8593e53@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADIlk2kC/4XNQQ7CIBCF4as0rMUALVRdeQ/josAgExUMGKI2v
 bu0K10Yl/9L5puRZEgImeyakSQomDGGGmrVEOOHcAKKtjYRTCgmuKAag4VEs08YzrSAoaWlZmM
 4bzk47XpST28JHD4W9nCs7THfY3ouX0o3r3/A0lFGtWXCMaWdMHb/ij5eB7ysMZCZLPKTkT8YW
 RkFEqSyatsr9c1M0/QGGSYO5AEBAAA=
X-Change-ID: 20260212-binder-shrink-vec-v3-c8c1131efbf7
To: Danilo Krummrich <dakr@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Vlastimil Babka <vbabka@suse.cz>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Uladzislau Rezki <urezki@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771251022; l=6048;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=QL+b5jDczE7VfFTAK6oksb/a4JLOHdQtkdc0bZAliTc=;
 b=rVWY/BAaKC24BNpW0P95s9QCQwCmQkM9AMe/Ed/ko95ETCq802Ht1J+l9Xl4uYbKx47Fh4Qv2
 SsMXnaAF9yzAREPwZvkGdGYjOBY9L4hKtTCM6S+HyNFBWVsEnKSo+e3
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds a shrink_to() method to KVVec to allow explicit
capacity reduction for memory reclamation.

Problem:
When elements are removed from a KVVec, the allocated capacity is not
reduced. The underlying C allocators (krealloc/kvrealloc) don't shrink
memory in-place. This can cause significant memory waste in scenarios
with variable workloads.

Solution:
- Patch 1: Implements shrink_to(min_capacity, flags) method specifically
  for KVVec (Vec<T, KVmalloc>). For kmalloc allocations, the method
  delegates to realloc(), letting the allocator decide whether shrinking
  is worthwhile. For vmalloc allocations (detected via is_vmalloc_addr),
  shrinking only occurs if at least one page of memory can be freed,
  using an explicit alloc+copy+free (deep copy) since vrealloc does not
  yet support in-place shrinking. A TODO comment marks this for future
  replacement with a generic implementation using A::realloc() once
  allocators properly support shrinking.
- Patch 2: Adds KUnit tests for the new shrink_to method, verifying
  page-based shrinking, empty vector handling, no-op behavior, and
  min_capacity respect.
- Patch 3: Uses shrink_to() in the Rust binder driver to reclaim memory
  when processes are deregistered. Uses a conservative shrinking
  strategy (trigger at len < cap / 4, shrink to len * 2) to avoid
  shrink-then-regrow oscillation while equalizing capacity more
  aggressively when it diverges far from usage.

Testing:
- KUnit tests pass (rust_kvec test suite).
- Kernel boots successfully in QEMU with CONFIG_ANDROID_BINDER_IPC_RUST=y.

Changes since v5:
- Used `u8` in KUnit tests for simplicity, removing elements_per_page
  calculations. (Danilo Krummrich)
- Changed assert in empty shrink test to verify capacity == 0 instead
  of just less than initial. (Danilo Krummrich)

Changes since v4:
- Added is_vmalloc_addr() check: kmalloc allocations now delegate to
  realloc() directly, keeping semantics as close as possible to the
  future generic implementation. Only vmalloc allocations use the
  page-threshold + deep copy path. (Danilo Krummrich)
- Updated doc comment to describe kmalloc vs vmalloc behavior
  separately: kmalloc delegates to realloc(), vmalloc only shrinks if
  at least one page can be freed via deep copy. (Danilo Krummrich)
- Fixed import style to follow kernel coding guidelines (multi-line
  block import for page::{AsPageIter, PAGE_SIZE}). (Danilo Krummrich)
- Dropped duplicate TODO comment inside shrink_to() body; the TODO
  above the impl block already covers this. (Danilo Krummrich)
- Structured SAFETY comments as lists when justifying multiple
  conditions. (Danilo Krummrich)
- Moved semicolons outside unsafe blocks per kernel style.
  (Danilo Krummrich)
- Changed binder shrink target from cap / 2 to len * 2, so that
  capacity equalizes to usage more aggressively when it has diverged
  far from the length. (Alice Ryhl)

Changes since v3:
- Dropped the Shrinkable trait entirely - it was not needed for the
  KVVec-specific implementation. (Danilo Krummrich)
- Removed shrink_to_fit() method. Only shrink_to() is implemented.
  (Danilo Krummrich)
- Implemented shrink_to() only for KVVec (impl<T> Vec<T, KVmalloc>)
  instead of as a generic method, since that covers the actual use
  case in binder. (Danilo Krummrich, Alice Ryhl)
- Added TODO comment explaining this is a temporary KVVec-specific
  implementation that should be replaced with a generic
  Vec<T, A>::shrink_to() calling A::realloc() once the underlying
  allocators properly support shrinking via realloc. (Danilo Krummrich)
- Changed binder shrink strategy to be less aggressive to avoid
  shrink-then-regrow oscillation: now triggers when len < cap / 4 and
  shrinks to cap / 2. (Alice Ryhl)
- Removed the cap > 128 threshold check in binder. (Alice Ryhl)
- Fixed commit prefix from "rust: binder:" to "rust_binder:".
  (Alice Ryhl)
- Updated test suite to focus on KVVec-specific behavior.

Changes since v2:
- Introduced new Shrinkable marker trait to distinguish allocators that
  benefit from shrinking (Vmalloc) from those that don't (Kmalloc).
- Shrinking now only occurs for vmalloc-backed buffers when at least one
  page can be freed, avoiding unnecessary work for kmalloc buffers.
  (Suggested by Danilo Krummrich)
- Split into 4 patches: Shrinkable trait introduction is now a
  separate patch to improve reviewability.
- Uses explicit alloc+copy+free since vrealloc doesn't yet support
  in-place shrinking; TODO added for future optimization when vrealloc
  gains that capability. (Discussed with Danilo Krummrich)
- Fixed minor KVVec/KVec terminology (binder uses KVVec not KVec).
- Expanded KUnit tests to cover different allocator backends and
  page-boundary shrinking behavior.

Changes since v1:
- Resend with correct threading (no code changes).
- Removed base-commit.
- Added explicit lore link to dependency in cover letter.

[1] https://lore.kernel.org/lkml/20260130205424.261700-1-shivamklr@cock.li/
[2] https://lore.kernel.org/lkml/20260131154016.270385-1-shivamklr@cock.li/
[3] https://lore.kernel.org/lkml/20260207-binder-shrink-vec-v3-v3-0-8ff388563427@cock.li/
[4] https://lore.kernel.org/lkml/20260212-binder-shrink-vec-v3-v4-0-bd02f06bf2cd@zohomail.in/
[5] https://lore.kernel.org/lkml/20260215-binder-shrink-vec-v3-v5-0-6e5e56d69766@zohomail.in/

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Shivam Kalra (3):
      rust: kvec: implement shrink_to for KVVec
      rust: alloc: add KUnit tests for KVVec shrink_to
      rust_binder: shrink all_procs when deregistering processes

 drivers/android/binder/context.rs |  11 ++
 rust/kernel/alloc/kvec.rs         | 216 +++++++++++++++++++++++++++++++++++++-
 2 files changed, 226 insertions(+), 1 deletion(-)
---
base-commit: 3c4ae63073d84abee5d81ce46d86a94e9dae9c89
change-id: 20260212-binder-shrink-vec-v3-c8c1131efbf7

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

