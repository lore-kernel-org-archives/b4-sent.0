From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Sun, 28 Jun 2026 17:10:14 +0000
Subject: [PATCH RFC 1/4] rust: transmute: add
 `impl_transmute_via_zerocopy!` macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260628-dma-zerocopy-bridge-v1-1-9a2895ebe30d@gmail.com>
References: <20260628-dma-zerocopy-bridge-v1-0-9a2895ebe30d@gmail.com>
In-Reply-To: <20260628-dma-zerocopy-bridge-v1-0-9a2895ebe30d@gmail.com>
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
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 nova-gpu@lists.linux.dev, dri-devel@lists.freedesktop.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782666615; l=2891;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=LXChnJ7p62He8Ts8ziph6RXUwlMDpuOOjkatwstqfkA=;
 b=vxK1wBU87NEi9SKYdoUiW1+9mEw4aAM22XMOB+XGyA6TxcOU8QnSCIocKOmOe/Bc4sHwli3ei
 fBxxCN1DzOMDTIlHtoXx4qsoKoPS+ykCgIf0TBY7LoieR6EbbrS0DgS
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DMA-coherent allocation APIs (`CoherentAllocation`, `Coherent`,
`dma::Pool`) bound their element type on
`transmute::{AsBytes, FromBytes}`, which a `zerocopy`-deriving type cannot
satisfy. A blanket bridge impl is rejected by coherence, as it overlaps
every existing concrete `transmute` impl.

Add a per-type bridge macro that emits the `transmute` impls for a
`zerocopy`-derived type. A compile-time assertion fails the build unless
the type is `zerocopy::{FromBytes, IntoBytes, Immutable}`, which subsumes
the `transmute::{FromBytes, AsBytes}` contracts, so the emitted unsafe
impls are machine-checked. This lets DMA structures adopt `zerocopy`
incrementally without flipping the DMA bound.

Assisted-by: Claude-Code:claude-opus-4-8
Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
 rust/kernel/transmute.rs | 35 +++++++++++++++++++++++++++++++++++
 1 file changed, 35 insertions(+)

diff --git a/rust/kernel/transmute.rs b/rust/kernel/transmute.rs
index 654b5ede2fe2..d9881f84dc62 100644
--- a/rust/kernel/transmute.rs
+++ b/rust/kernel/transmute.rs
@@ -227,3 +227,38 @@ macro_rules! impl_asbytes {
     {<T: AsBytes>} [T],
     {<T: AsBytes, const N: usize>} [T; N],
 }
+
+/// Implements the kernel's `FromBytes` and `AsBytes` byte-safety traits for a type
+/// that already derives the equivalent `zerocopy` traits.
+///
+/// This lets a `zerocopy`-derived type satisfy the bounds required by the
+/// DMA-coherent allocation APIs (`CoherentAllocation`, `Coherent`, `dma::Pool`)
+/// without a hand-audited `unsafe`: the macro fails to compile unless `$t`
+/// implements `zerocopy::FromBytes`, `zerocopy::IntoBytes` and `zerocopy::Immutable`,
+/// which together subsume the safety contracts of [`FromBytes`] and [`AsBytes`].
+#[macro_export]
+macro_rules! impl_transmute_via_zerocopy {
+    ($t:ty) => {
+        const _: () = {
+            // Compile-time proof: fails to build unless `$t` carries the `zerocopy`
+            // byte-safety proofs.
+            fn assert_zerocopy<
+                T: ::zerocopy::FromBytes + ::zerocopy::IntoBytes + ::zerocopy::Immutable,
+            >() {
+            }
+            fn check() {
+                assert_zerocopy::<$t>();
+            }
+        };
+
+        // SAFETY: `$t: zerocopy::FromBytes` guarantees that all bit patterns are valid
+        // and `zerocopy::Immutable` that it has no interior mutability, which is exactly
+        // the contract of `FromBytes`.
+        unsafe impl $crate::transmute::FromBytes for $t {}
+
+        // SAFETY: `$t: zerocopy::IntoBytes` guarantees that it has no uninitialized
+        // (padding) bytes and `zerocopy::Immutable` that it has no interior mutability,
+        // which is exactly the contract of `AsBytes`.
+        unsafe impl $crate::transmute::AsBytes for $t {}
+    };
+}

-- 
2.54.0

