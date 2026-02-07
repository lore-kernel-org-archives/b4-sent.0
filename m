From: Shivam Kalra <shivamklr@cock.li>
Subject: [PATCH v3 0/4] rust: alloc: add Vec shrinking methods
Date: Sat, 07 Feb 2026 17:02:46 +0530
Message-Id: <20260207-binder-shrink-vec-v3-v3-0-8ff388563427@cock.li>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN8ih2kC/x3MMQqAMAxA0auUzAZCqxa8ijhYGzUIVVIognh3i
 +Mb/n8gswpnGMwDykWynKnCNQaWfU4bo8RqsGR7suQxSIqsmHeVdGDhBYvDrqW2i94HYg81vZR
 Xuf/tOL3vB0wNex9mAAAA
X-Change-ID: 20260207-binder-shrink-vec-v3-54045d77b0e7
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
 Shivam Kalra <shivamklr@cock.li>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770464219; l=3163;
 i=shivamklr@cock.li; s=20260206; h=from:subject:message-id;
 bh=eH8P3luXJow3f4Sscg7g8kVmMaP2GpouRTc5nqbiE74=;
 b=Pn2AmBL/pIMTm18HamnRx0tEmXtA9rx2/AgFaKiCYzM2GrskmEjFtixxEOLAN2IeIBEcw0MIv
 TvoW9tj0pAhDC8eGX96FRlVu4TgMmnN/5Ea+uf7hjDQYC3uT01rsXbw
X-Developer-Key: i=shivamklr@cock.li; a=ed25519;
 pk=vMC4wm7HuB8IdkiHldCdtuViW0NTnShcRaMF50MWRFQ=
X-Endpoint-Received: by B4 Relay for shivamklr@cock.li/20260206 with auth_id=628
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds shrink_to() and shrink_to_fit() methods to Vec<T, A>
(and by extension KVVec, KVec, VVec) to allow explicit capacity
reduction for memory reclamation.

Problem:
When elements are removed from a KVVec, the allocated capacity is not
reduced. The underlying C allocators (krealloc/kvrealloc) don't shrink
memory in-place. This can cause significant memory waste in scenarios
with variable workloads.

Solution:
- Patch 1: Introduces the `Shrinkable` marker trait to identify allocators
  that can meaningfully reclaim memory when shrinking (e.g., Vmalloc but
  not Kmalloc, since Kmalloc uses fixed-size buckets).
- Patch 2: Implements shrink_to(min_capacity, flags) and
  shrink_to_fit(flags)  methods. Shrinking only occurs when
  the allocator is shrinkable AND the operation would free at least
  one page of memory.
- Patch 3: Adds KUnit tests for the new methods across different allocator
  backends (Vmalloc and KVmalloc).
- Patch 4: Uses shrink_to() in the Rust binder driver to reclaim memory
  when processes are deregistered. Shrinking is triggered only when the
  vector capacity exceeds 128 elements and less than half is used.

Testing:
- KUnit tests pass (rust_kvec test suite).
- Kernel boots successfully in QEMU with CONFIG_ANDROID_BINDER_IPC_RUST=y.

Changes since v2:
- Introduced new `Shrinkable` marker trait to distinguish allocators that
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

Signed-off-by: Shivam Kalra <shivamklr@cock.li>
---
Shivam Kalra (4):
      rust: alloc: introduce Shrinkable trait
      rust: kvec: implement shrink_to and shrink_to_fit for Vec
      rust: alloc: add KUnit tests for Vec shrink operations
      rust: binder: shrink all_procs when deregistering processes

 drivers/android/binder/context.rs |  10 ++
 rust/kernel/alloc/allocator.rs    |  48 +++++++
 rust/kernel/alloc/kvec.rs         | 296 +++++++++++++++++++++++++++++++++++++-
 3 files changed, 352 insertions(+), 2 deletions(-)
---
base-commit: 3c4ae63073d84abee5d81ce46d86a94e9dae9c89
change-id: 20260207-binder-shrink-vec-v3-54045d77b0e7

Best regards,
-- 
Shivam Kalra <shivamklr@cock.li>

