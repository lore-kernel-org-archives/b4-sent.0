From: Shivam Kalra <shivamkalra98@zohomail.in>
Subject: [PATCH v4 0/3] rust: alloc: add KVVec shrinking method
Date: Thu, 12 Feb 2026 13:47:06 +0530
Message-Id: <20260212-binder-shrink-vec-v3-v4-0-bd02f06bf2cd@zohomail.in>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIKMjWkC/x3MQQqAIBBA0avIrBtIjYquEi1KxxoCixEkCO+et
 HyL/19IJEwJJvWCUObEV6zoGgXuWONOyL4aTGv61miDG0dPgukQjidmcpgtutFpbTWFLQxQ01s
 o8PNv56WUD6fXl/FmAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770884727; l=4256;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=bKZOD/0QCyNVBBQrjHN3Q70Hx7RbUjlqHSRCGKdOX4Q=;
 b=oUzTjmE4lwxmDEfXx9BrqBlGKyqRmES21wey+36aL89hhPYY2AXLmwSrWPIaHfIGLuUkN7KHQ
 ubSw81jihuwAdiO3t14r9NQWUzn1LoTx/bZuWAQx8hAjyapIIgAz5Nh
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
  for KVVec (Vec<T, KVmalloc>). Shrinking only occurs when the operation
  would free at least one page of memory. The implementation uses
  explicit alloc+copy+free since vrealloc doesn't yet support in-place
  shrinking. A TODO comment marks this for future replacement with a
  generic implementation using A::realloc() once allocators properly
  support shrinking.
- Patch 2: Adds KUnit tests for the new shrink_to method, verifying
  page-based shrinking, empty vector handling, no-op behavior, and
  min_capacity respect.
- Patch 3: Uses shrink_to() in the Rust binder driver to reclaim memory
  when processes are deregistered. Uses a conservative shrinking
  strategy (trigger at len < cap / 4, shrink to cap / 2) to avoid
  shrink-then-regrow oscillation.

Testing:
- KUnit tests pass (rust_kvec test suite).
- Kernel boots successfully in QEMU with CONFIG_ANDROID_BINDER_IPC_RUST=y.

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

Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
Shivam Kalra (3):
      rust: kvec: implement shrink_to for KVVec
      rust: alloc: add KUnit tests for KVVec shrink_to
      rust_binder: shrink all_procs when deregistering processes

 drivers/android/binder/context.rs |  11 +++
 rust/kernel/alloc/kvec.rs         | 190 +++++++++++++++++++++++++++++++++++++-
 2 files changed, 200 insertions(+), 1 deletion(-)
---
base-commit: 3c4ae63073d84abee5d81ce46d86a94e9dae9c89
change-id: 20260212-binder-shrink-vec-v3-c8c1131efbf7

Best regards,
-- 
Shivam Kalra <shivamkalra98@zohomail.in>

