From: Younes Akhouayri <git@younes.io>
Date: Sun, 06 Sep 2026 09:40:53 +0200
Subject: [PATCH] rust: num: document why Integer is sealed
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-docs-rust-num-integer-sealing-safety-v1-1-78057391302c@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNSw7CMAxEr1JljUUIqFCugli4qZsagYvsFIGq3
 p1+lm8082Z0Rspk7lqMTunDxr3McNgVLnYoiYCbmV3wofSVL6Hpo4EOlkGGF7BkSqRghE+WBIY
 t5R8c0VOoyjNWp4ubVW+llr/rze2+sQ31g2Je3EujRiOoFSV2S9QrJ5b9+rMtp+kPvosgoKwAA
 AA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788680463; l=1364;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=toyc2RIIIaJbEQPl2zcDj4AAt9VV1aOmVSKrcNUyvD0=;
 b=NgZNpApSLlAtQzmYTKRmaZGWYOb9/B1JL8s1nbgvApDS4vo2LedCRd6bYosnD3J/hCiO18diG
 Dbdja9+/wYwC+64T/Fa3/SUF/A94QovyNcHgfRwkiCEGsbD2ozxkZpW
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bounded relies on Integer::BITS and Integer::Signedness accurately
describing the implementing type to justify unchecked operations.
The reason external implementations are prohibited is currently recorded
only in the commit history.

Document this safety requirement on Integer itself.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://lore.kernel.org/all/CANiq72m8kycbfQ1teyne-OtB5d5TsUcX_WW0FCkWB3Ayyg-qWw@mail.gmail.com/
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/num.rs | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/rust/kernel/num.rs b/rust/kernel/num.rs
index de589792a77a..1d06395d3a63 100644
--- a/rust/kernel/num.rs
+++ b/rust/kernel/num.rs
@@ -20,6 +20,11 @@ pub trait Sealed {}
 }
 
 /// Describes core properties of integer types.
+///
+/// This trait is sealed because [`Bounded`] relies on [`Integer::BITS`] and
+/// [`Integer::Signedness`] accurately describing the implementing type to
+/// justify unchecked operations. An incorrect implementation could therefore
+/// make safe [`Bounded`] operations cause undefined behavior.
 pub trait Integer:
     private::Sealed
     + Sized

---
base-commit: c6709d5e14072d0e3d02f291daee46a199e5dad3
change-id: 20260906-docs-rust-num-integer-sealing-safety-3a0e2967a948

Best regards,
--  
Younes Akhouayri <git@younes.io>

