From: Ke Sun <sunke@kylinos.cn>
Date: Mon, 09 Nov 2026 08:36:44 +0800
Subject: [PATCH v6 01/10] rust: sizes: add SZ_4G constant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261109-tyr-ioctls-v6-1-b2896bf2b3c9@kylinos.cn>
References: <20261109-tyr-ioctls-v6-0-b2896bf2b3c9@kylinos.cn>
In-Reply-To: <20261109-tyr-ioctls-v6-0-b2896bf2b3c9@kylinos.cn>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: Sami Tolvanen <samitolvanen@google.com>, rust-for-linux@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, driver-core@lists.linux.dev, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794184620; l=1808;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=RC5TQEMWPe7CGSe6NzYoBKUAxyypO/SjxFkEThrMEs0=;
 b=Ey688Yha//lunLV9csKQAGz4CQeyX8TuAFJ5yReptrF1o5VMnWsmeaIqqNHRZj6A1K46dzhmG
 ksBtV6+Ti3eBquWFrvTK4MQQVRNj7HUo/X5T+SbTq4k71Bu7TvfsYqY
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

SZ_4G is used by Tyr when splitting the GPU VA range into
user and kernel regions. Add a LargeSizeConstants trait, implemented
for u64 since SizeConstants only covers sizes that fit in a u32.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
Reviewed-by: Daniel Almeida <daniel.almeida@collabora.com>
Reviewed-by: Gary Guo <gary@garyguo.net>
Acked-by: Miguel Ojeda <ojeda@kernel.org>
---
 rust/bindings/bindings_helper.h |  1 +
 rust/kernel/sizes.rs            | 12 ++++++++++++
 2 files changed, 13 insertions(+)

diff --git a/rust/bindings/bindings_helper.h b/rust/bindings/bindings_helper.h
index 3791af0aadc73..fd39cc954eaba 100644
--- a/rust/bindings/bindings_helper.h
+++ b/rust/bindings/bindings_helper.h
@@ -116,6 +116,7 @@ const size_t RUST_CONST_HELPER_ARCH_SLAB_MINALIGN = ARCH_SLAB_MINALIGN;
 const size_t RUST_CONST_HELPER_ARCH_KMALLOC_MINALIGN = ARCH_KMALLOC_MINALIGN;
 const size_t RUST_CONST_HELPER_PAGE_SIZE = PAGE_SIZE;
 const size_t RUST_CONST_HELPER_GENLMSG_DEFAULT_SIZE = GENLMSG_DEFAULT_SIZE;
+const unsigned long long RUST_CONST_HELPER_SZ_4G = SZ_4G;
 const gfp_t RUST_CONST_HELPER_GFP_ATOMIC = GFP_ATOMIC;
 const gfp_t RUST_CONST_HELPER_GFP_KERNEL = GFP_KERNEL;
 const gfp_t RUST_CONST_HELPER_GFP_KERNEL_ACCOUNT = GFP_KERNEL_ACCOUNT;
diff --git a/rust/kernel/sizes.rs b/rust/kernel/sizes.rs
index 188e00c2b8b46..760d26ebe6ff6 100644
--- a/rust/kernel/sizes.rs
+++ b/rust/kernel/sizes.rs
@@ -177,3 +177,15 @@ impl SizeConstants for $first {
 }
 
 define_sizes!(u32, u64, usize);
+
+/// Large size constants (≥ 4 GiB).
+///
+/// Only implemented for [`u64`].
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

