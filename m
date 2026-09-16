From: Younes Akhouayri <git@younes.io>
Date: Wed, 16 Sep 2026 17:10:38 +0200
Subject: [PATCH v3] rust: num: document why Integer is sealed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260916-docs-rust-num-integer-sealing-safety-v3-1-00f950426c85@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/5WOQW7CMBBFr4K87lDHhsRh1XtULBxnSKYqNvI4E
 RHK3bHDhmW7fKM/7/+HYIyELE67h4g4E1PwGfTHTrjR+gGB+sxCSVXLVtbQB8cQJ07gpyuQTzh
 gBEb7S34AthdMC2grUbV1Y9uDEVl1i3ih+1bzfX4xT90PulTcJdFZRuii9W4spxBpIP+59bw+c
 2YkTiEu29a5Kq5/zporqKAx8tjottJSua8lTB55T0GUWbN6l5o/SlWWonH1UelD3xn1Ll3X9Qn
 nTQh2YwEAAA==
X-Change-ID: 20260906-docs-rust-num-integer-sealing-safety-3a0e2967a948
To: Alexandre Courbot <acourbot@nvidia.com>, 
 Yury Norov <yury.norov@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789571453; l=7870;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=6EBGJ4a6/ShfQ/6ynR/rskrjn3ZQAYYZNFuSE3dWtm8=;
 b=6TmRtiwtGmVkccHklAtYYJopUGxnctI2PmWwSUaGmimoD5HX1Ikr+iTGieknagyKCoG9/LlAA
 KjGvj31yH77AFdLRUSbVVBZU/hKdmzILPOrn1aVcyxX2Ad22nFSNd2G
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bounded relies on Integer implementations to provide primitive integer
semantics when justifying unchecked operations.

Explain why Integer is sealed next to its private supertrait. Document
the dependency inside fits_within, so callers can rely on its result
without repeating that explanation. Mention sealing in safety comments
that directly rely on integer metadata, shifts or conversions.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Suggested-by: Gary Guo <gary@garyguo.net>
Suggested-by: Alexandre Courbot <acourbot@nvidia.com>
Link: https://lore.kernel.org/all/CANiq72m8kycbfQ1teyne-OtB5d5TsUcX_WW0FCkWB3Ayyg-qWw@mail.gmail.com/
Link: https://lore.kernel.org/all/DL88SQWYU15W.2CVZB5NVSSJGK@garyguo.net/
Link: https://lore.kernel.org/all/CANiq72kx-YPPEruOFdu-Dp7GX+8=Et6svG+sQtqEmmF7kpnVyQ@mail.gmail.com/
Link: https://lore.kernel.org/all/DLDSZ09SM8HI.3PHPYGLV2YZBX@nvidia.com/
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Changes in v3:
- Document the sealing dependency inside fits_within and restore its
  callers' original safety comments, following Alexandre's feedback.
- Restore extend's invariant-based comment and remove the repeated
  sealing explanation from the second cast safety comment.
- Link to v2: https://patch.msgid.link/20260908-docs-rust-num-integer-sealing-safety-v2-1-e8c65234db82@younes.io

Changes in v2:
- Shorten the comment explaining why `Integer` is sealed.
- Mention the seal in the `SAFETY` comments that rely on it.
- Link to v1: https://patch.msgid.link/20260906-docs-rust-num-integer-sealing-safety-v1-1-78057391302c@younes.io

To: Alexandre Courbot <acourbot@nvidia.com>
To: Yury Norov <yury.norov@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>
To: Boqun Feng <boqun@kernel.org>
To: Gary Guo <gary@garyguo.net>
To: Björn Roy Baron <bjorn3_gh@protonmail.com>
To: Benno Lossin <lossin@kernel.org>
To: Andreas Hindborg <a.hindborg@kernel.org>
To: Alice Ryhl <aliceryhl@google.com>
To: Trevor Gross <tmgross@umich.edu>
To: Danilo Krummrich <dakr@kernel.org>
To: Daniel Almeida <daniel.almeida@collabora.com>
To: Tamir Duberstein <tamird@kernel.org>
To: Onur Özkan <work@onurozkan.dev>
Cc: rust-for-linux@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
---
 rust/kernel/num.rs         |  1 +
 rust/kernel/num/bounded.rs | 32 +++++++++++++++++++-------------
 2 files changed, 20 insertions(+), 13 deletions(-)

diff --git a/rust/kernel/num.rs b/rust/kernel/num.rs
index de589792a77a..0449e84a384a 100644
--- a/rust/kernel/num.rs
+++ b/rust/kernel/num.rs
@@ -21,6 +21,7 @@ pub trait Sealed {}
 
 /// Describes core properties of integer types.
 pub trait Integer:
+    // Sealed so that unsafe code can rely on the correctness of its implementations.
     private::Sealed
     + Sized
     + Copy
diff --git a/rust/kernel/num/bounded.rs b/rust/kernel/num/bounded.rs
index 2a2b0a4bca5e..aff35e2eb616 100644
--- a/rust/kernel/num/bounded.rs
+++ b/rust/kernel/num/bounded.rs
@@ -40,6 +40,8 @@ macro_rules! fits_within {
 /// Returns `true` if `value` can be represented with at most `N` bits in a `T`.
 #[inline(always)]
 fn fits_within<T: Integer>(value: T, num_bits: u32) -> bool {
+    // `Integer` is sealed, so the bit width, shifts and equality have primitive integer semantics.
+    // Unsafe code relies on this function correctly checking whether `value` fits.
     fits_within!(value, T, num_bits)
 }
 
@@ -472,8 +474,9 @@ pub fn cast<U>(self) -> Bounded<U, N>
         T: Integer,
         U: Integer<Signedness = T::Signedness>,
     {
-        // SAFETY: The converted value is represented using `N` bits, `U` can contain `N` bits, and
-        // `U` and `T` have the same sign, hence this conversion cannot fail.
+        // SAFETY: `Integer` is sealed, so the bit widths and signedness are correct. The converted
+        // value is represented using `N` bits, `U` can contain `N` bits, and `U` and `T` have the
+        // same sign, hence this conversion cannot fail.
         let value = unsafe { U::try_from(self.get()).unwrap_unchecked() };
 
         // SAFETY: Although the backing type has changed, the value is still represented within
@@ -498,8 +501,9 @@ pub fn shr<const SHIFT: u32, const RES: u32>(self) -> Bounded<T, RES> {
         const_assert!(SHIFT < T::BITS);
         const_assert!(RES + SHIFT >= N);
 
-        // SAFETY: We shift the value right by `SHIFT`, reducing the number of bits needed to
-        // represent the shifted value by as much, and just asserted that `RES >= N - SHIFT`.
+        // SAFETY: `Integer` is sealed, so the shift has primitive integer semantics. We reduce the
+        // number of bits needed to represent the shifted value by `SHIFT`, and just asserted that
+        // `RES >= N - SHIFT`.
         unsafe { Bounded::__new(self.0 >> SHIFT) }
     }
 
@@ -550,8 +554,9 @@ pub fn shr_exact<const SHIFT: u32, const RES: u32>(self) -> Option<Bounded<T, RE
     pub fn shl<const SHIFT: u32, const RES: u32>(self) -> Bounded<T, RES> {
         const_assert!(RES >= N + SHIFT);
 
-        // SAFETY: We shift the value left by `SHIFT`, augmenting the number of bits needed to
-        // represent the shifted value by as much, and just asserted that `RES >= N + SHIFT`.
+        // SAFETY: `Integer` is sealed, so the shift has primitive integer semantics. We augment
+        // the number of bits needed to represent the shifted value by `SHIFT`, and just asserted
+        // that `RES >= N + SHIFT`.
         unsafe { Bounded::__new(self.0 << SHIFT) }
     }
 }
@@ -1028,8 +1033,9 @@ impl<T, const N: u32> From<$type> for Bounded<T, N>
             Self: AtLeastXBits<{ <$type as Integer>::BITS as usize }>,
         {
             fn from(value: $type) -> Self {
-                // SAFETY: The trait bound on `Self` guarantees that `N` bits is
-                // enough to hold any value of the source type.
+                // SAFETY: `Integer` is sealed, so the bit widths and signedness are correct. The
+                // trait bound on `Self` guarantees that `N` bits is enough to hold any value of
+                // the source type.
                 unsafe { Self::__new(T::from(value)) }
             }
         }
@@ -1104,9 +1110,9 @@ impl<T, const N: u32> From<Bounded<T, N>> for $type
             Bounded<T, N>: FitsInXBits<{ <$type as Integer>::BITS as usize }>,
         {
             fn from(value: Bounded<T, N>) -> $type {
-                // SAFETY: The trait bound on `Bounded` ensures that any value it holds (which
-                // is constrained to `N` bits) can fit into the destination type, so this
-                // conversion cannot fail.
+                // SAFETY: `Integer` is sealed, so the bit widths and signedness are correct. The
+                // trait bound on `Bounded` ensures that any value it holds (which is constrained
+                // to `N` bits) can fit into the destination type, so this conversion cannot fail.
                 unsafe { <$type>::try_from(value.get()).unwrap_unchecked() }
             }
         }
@@ -1137,8 +1143,8 @@ impl<T, const N: u32> From<bool> for Bounded<T, N>
     T: Integer<Signedness = Unsigned> + From<bool>,
 {
     fn from(value: bool) -> Self {
-        // SAFETY: A boolean is represented by `0` or `1`, so it fits within any valid unsigned
-        // `Bounded` width.
+        // SAFETY: `Integer` is sealed, so `T` is a primitive unsigned integer. A boolean is
+        // represented by `0` or `1`, so it fits within any valid unsigned `Bounded` width.
         unsafe { Self::__new(T::from(value)) }
     }
 }

---
base-commit: c6709d5e14072d0e3d02f291daee46a199e5dad3
change-id: 20260906-docs-rust-num-integer-sealing-safety-3a0e2967a948

Best regards,
--  
Younes Akhouayri <git@younes.io>

