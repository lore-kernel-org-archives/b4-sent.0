From: Younes Akhouayri <git@younes.io>
Date: Sat, 05 Sep 2026 04:17:45 +0200
Subject: [PATCH] rust: num: seal Integer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260905-feature-rust-num-seal-integer-v1-1-83096115ad64@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0Q7CIAyF4VdZuLYRcSGZr2K8ANaxGmWmBWOy7
 N2F7fJver5VCTKhqFu3KsYvCS2pxuXUqTC7FBForK2MNlYP+goTulwYgYtkSOUNgu4FlDJGZHC
 9sWacejMEq6rxYZzot/v3x9FS/BNDbmj78E4QPLsU5nZamCKl864fy237A9lWeQilAAAA
X-Change-ID: 20260903-feature-rust-num-seal-integer-a4262df429c6
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
 stable@vger.kernel.org, Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788574676; l=1759;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=bVjKmsDC3xyhPHxsbELDrHtf25N1qLrwIDkcTJtI+Hw=;
 b=tn6YSXWPvKIjGWNXFsc+QIj5PzBOLQzeokvmPUB666OHKjbnHLWLMM+YIRl87t9+YEYlqeFkH
 UOZmavqYAaJCk/4Rs0Jf1qgDYBfLRIG6qyvjqPfVMPOiB4TA55gUurs
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bounded relies on Integer implementations to describe primitive integer
semantics correctly. In particular, it uses Integer::BITS and Signedness
to justify unchecked operations.

Integer is currently safe and externally implementable, so an
implementation can violate those assumptions and make safe Bounded
operations reach undefined behavior.

Seal Integer so only the primitive implementations provided by the
kernel crate can satisfy it.

Fixes: 01e345e82ec3 ("rust: num: add Bounded integer wrapping type")
Closes: https://lore.kernel.org/rust-for-linux/CANiq72mOfR33s4y+Ueivd5NrC5yre+Pcp57ZOBz0msw9A4AP1Q@mail.gmail.com/
Cc: stable@vger.kernel.org
Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/num.rs | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/num.rs b/rust/kernel/num.rs
index dbe848e30efe..de589792a77a 100644
--- a/rust/kernel/num.rs
+++ b/rust/kernel/num.rs
@@ -15,9 +15,14 @@ pub enum Unsigned {}
 /// Designates signed primitive types.
 pub enum Signed {}
 
+mod private {
+    pub trait Sealed {}
+}
+
 /// Describes core properties of integer types.
 pub trait Integer:
-    Sized
+    private::Sealed
+    + Sized
     + Copy
     + Clone
     + PartialEq
@@ -56,6 +61,8 @@ pub trait Integer:
 macro_rules! impl_integer {
     ($($type:ty: $signedness:ty), *) => {
         $(
+        impl private::Sealed for $type {}
+
         impl Integer for $type {
             type Signedness = $signedness;
 

---
base-commit: e510334fbaeaa016ac76d80b4c5f47611c5f7860
change-id: 20260903-feature-rust-num-seal-integer-a4262df429c6

Best regards,
--  
Younes Akhouayri <git@younes.io>

