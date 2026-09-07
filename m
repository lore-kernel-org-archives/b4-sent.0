From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 08 Sep 2026 00:47:48 +0800
Subject: [PATCH v2 1/9] rust: sizes: add SZ_4G constant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260908-tyr-ioctls-v2-1-88bea777df67@kylinos.cn>
References: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
In-Reply-To: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
To: rust-for-linux@vger.kernel.org
Cc: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, dri-devel@lists.freedesktop.org, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788799692; l=1664;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=so+WuqU/pYd8/dKzBVqpgAsW0XebT6xqiODTucEx6fs=;
 b=w3XcLqR1VQevN3qWcQai1GYtPQNLzv+aBbIvX1piwpdczwbSyazqpxKHZg94TivRfbzcvqI1m
 qgIWbCsMq4qCZW9sotv5Hu+943CQnyirsVV6qvpcZoE6vXbrJ4Cb0t2
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

SZ_4G is used by the Tyr driver when splitting the GPU VA range into
user and kernel regions.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
Reviewed-by: Daniel Almeida <daniel.almeida@collabora.com>
Reviewed-by: Gary Guo <gary@garyguo.net>
---
 rust/bindings/bindings_helper.h |  1 +
 rust/kernel/sizes.rs            | 12 ++++++++++++
 2 files changed, 13 insertions(+)

diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index 4b31aa7f432f5..9bbe1538d7c7c 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -115,6 +115,7 @@ const size_t RUST_CONST_HELPER_ARCH_SLAB_MINALIGN = ARCH_SLAB_MINALIGN;
 const size_t RUST_CONST_HELPER_ARCH_KMALLOC_MINALIGN = ARCH_KMALLOC_MINALIGN;
 const size_t RUST_CONST_HELPER_PAGE_SIZE = PAGE_SIZE;
 const size_t RUST_CONST_HELPER_GENLMSG_DEFAULT_SIZE = GENLMSG_DEFAULT_SIZE;
+const unsigned long long RUST_CONST_HELPER_SZ_4G = SZ_4G;
 const gfp_t RUST_CONST_HELPER_GFP_ATOMIC = GFP_ATOMIC;
 const gfp_t RUST_CONST_HELPER_GFP_KERNEL = GFP_KERNEL;
 const gfp_t RUST_CONST_HELPER_GFP_KERNEL_ACCOUNT = GFP_KERNEL_ACCOUNT;
diff --git a/rust/kernel/sizes.rs b/rust/kernel/sizes.rs
index 521b2b38bfe77..b236573f0792e 100644
--- a/rust/kernel/sizes.rs
+++ b/rust/kernel/sizes.rs
@@ -132,3 +132,15 @@ impl SizeConstants for $first {
 }
 
 define_sizes!(u32, u64, usize);
+
+/// Large size constants (≥ 4 GiB).
+///
+/// Only implemented for `u64`.
+pub trait LargeSizeConstants {
+    /// `0x1_0000_0000`.
+    const SZ_4G: Self;
+}
+
+impl LargeSizeConstants for u64 {
+    const SZ_4G: Self = bindings::SZ_4G;
+}

-- 
2.43.0

