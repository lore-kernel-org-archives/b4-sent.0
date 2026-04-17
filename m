From: Alvin Sun <alvin.sun@linux.dev>
Subject: [PATCH 0/4] rust: Add helper functions and constants for Tyr
 driver
Date: Fri, 17 Apr 2026 09:05:50 +0800
Message-Id: <20260417-tyr-ioctls-deps-v1-0-41c6e9bb061c@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG6H4WkC/yXMSw6DIBSF4a0Yxr0GUNSYpuk+GgcUri2xggW1D
 +PeS3X4n+R8CwnoDQZSJwvxOJtgnI3BDglRd2lvCEbHJpzyguasgPHjwTg1PgJoHAJwUVGBqNs
 s4yS+Bo+teW/ipdnb43OK8LiPpMcQ5AbXyTG6glFasCKjPE9ZlZcZMHg5352dnbz7dtKmGufTH
 7/KgKBc35uxTuYypeCVIM26/gC2CSe8yAAAAA==
X-Change-ID: 20260416-tyr-ioctls-deps-25805eedf332
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Tamir Duberstein <tamird@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776388289; l=1591;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=/Cf9gBkTGs0FZ5AznLGhdvS5YDnnQwX3P349kNzrw9s=;
 b=i4mDcseJKhSLM3Wmo9o5QqvFYc2hmQPNSFKc/Hhd8iVYttVa+fm9NC9L6xLaF8ihLeg6DcVOi
 +KGN4DjLo8ZDsRxgNHYvGPC4gGPODD9s7OEi1gcNG4F/w2qfUi/eLj+
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset provides helper functions and constants that will be used
by the Tyr driver's VM and BO related ioctl implementations.

These patches add:
- SZ_4G constant for VA layout calculations
- A task_size() method to Mm for determining process VA space size
- Updated StoreError comments for alloc() usage
- Guard::find() helper for finding the first present entry in XArray

This patchset depends on Onur's xa_alloc implementation [1].

The complete patchset, including the Tyr driver ioctl implementations
can be found at [2].

Link: https://lore.kernel.org/rust-for-linux/20251006163024.18473-1-work@onurozkan.dev/ [1]
Link: https://gitlab.freedesktop.org/panfrost/linux/-/merge_requests/64 [2]
Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
Alvin Sun (4):
      rust: sizes: add SZ_4G constant
      rust: mm: Add task_size() method to Mm
      rust: xarray: Update StoreError comments for alloc()
      rust: xarray: Add Guard::find() helper

 rust/kernel/mm.rs     |  7 +++++++
 rust/kernel/sizes.rs  |  2 ++
 rust/kernel/xarray.rs | 28 +++++++++++++++++++++++++---
 3 files changed, 34 insertions(+), 3 deletions(-)
---
base-commit: d1d81e9d1a4dd846aee9ae77ff9ecc2800d72148
change-id: 20260416-tyr-ioctls-deps-25805eedf332
prerequisite-message-id: <20251006163024.18473-1-work@onurozkan.dev>
prerequisite-patch-id: c472a9548969ac774d36fead73378961a0d0489c
prerequisite-patch-id: 63890b91e911cf96cb42308c056d639580ac0fa0
prerequisite-patch-id: 337eb93db35359c611abe9cba299e6ab0525a2b5

Best regards,
-- 
Alvin Sun <alvin.sun@linux.dev>

