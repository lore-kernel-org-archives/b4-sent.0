From: Jens Korinth <jens.korinth@tuta.io>
Date: Tue, 26 Nov 2024 17:40:59 +0100
Subject: [PATCH v4 3/3] rust: error: Replace pr_warn by pr_warn_once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-pr_once_macros-v4-3-410b8ca9643e@tuta.io>
References: <20241126-pr_once_macros-v4-0-410b8ca9643e@tuta.io>
In-Reply-To: <20241126-pr_once_macros-v4-0-410b8ca9643e@tuta.io>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, linux-kernel@vger.kernel.org, 
 Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732639280; l=872;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=Ibn3wEyptEN6rItZsMxTwWDZUjDEMOkNcZSR4EQjX4M=;
 b=MnERlW0iiP5yuqZAjJpBuHzt97f3tAqsZl9SVLCPvMjRPTJAHSg/fNl90GinoaOYCJ1wtfdys
 j90U8UUchUDCAGgCqNYJEStmvh62yiv5Zit+gDB4ftZJURYincQqO8c
X-Developer-Key: i=jens.korinth@tuta.io; a=ed25519;
 pk=bG0q4Zyj3o4d/r326zKL7ym+/tXzyykcjh+U0M13iyc=
X-Endpoint-Received: by B4 Relay for jens.korinth@tuta.io/20241107 with auth_id=270
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use new pr_warn_once macro to resolve TODO in error.rs.

Signed-off-by: Jens Korinth <jens.korinth@tuta.io>
---
 rust/kernel/error.rs | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/rust/kernel/error.rs b/rust/kernel/error.rs
index 52c5024324474fc1306047f3fd7516f0023d0313..f6813dace1128b7ef91f64e79cd83bb64995bf97 100644
--- a/rust/kernel/error.rs
+++ b/rust/kernel/error.rs
@@ -102,8 +102,7 @@ impl Error {
     /// be returned in such a case.
     pub fn from_errno(errno: crate::ffi::c_int) -> Error {
         if errno < -(bindings::MAX_ERRNO as i32) || errno >= 0 {
-            // TODO: Make it a `WARN_ONCE` once available.
-            crate::pr_warn!(
+            crate::pr_warn_once!(
                 "attempted to create `Error` with out of range `errno`: {}",
                 errno
             );

-- 
2.47.0

