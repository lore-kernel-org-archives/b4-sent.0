From: Jens Korinth <jens.korinth@tuta.io>
Date: Thu, 07 Nov 2024 00:28:33 +0100
Subject: [PATCH v2 3/3] rust: error: Replace pr_warn by pr_warn_once
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241107-pr_once_macros-v2-3-dc0317ff301e@tuta.io>
References: <20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io>
In-Reply-To: <20241107-pr_once_macros-v2-0-dc0317ff301e@tuta.io>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>
Cc: rust-for-linux@vger.kernel.org, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Dirk Behme <dirk.behme@gmail.com>, Jens Korinth <jens.korinth@tuta.io>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1730935742; l=871;
 i=jens.korinth@tuta.io; s=20241107; h=from:subject:message-id;
 bh=bZLBDxudHxGsVw5ADGygZHTwpiRJkVukaGhfv2uAfCU=;
 b=rCRDNFVHsl6EvjGErsf96ETgFVTCOcgf4A4s1Q94yDktDaDqLW5xgq2wU1C+7PZ1M+OLqzIUn
 gWNdGWRyyC3ClY9JuqFHxUaOnMkg6sZjn22Py0ggrsz2uQYA881j02Z
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
index 7cd3bbab52f208961390de03a255446950e9eb04..fe1b31506b30fba0ec9d5339d80c2a7fa76ce7c7 100644
--- a/rust/kernel/error.rs
+++ b/rust/kernel/error.rs
@@ -102,8 +102,7 @@ impl Error {
     /// be returned in such a case.
     pub fn from_errno(errno: core::ffi::c_int) -> Error {
         if errno < -(bindings::MAX_ERRNO as i32) || errno >= 0 {
-            // TODO: Make it a `WARN_ONCE` once available.
-            crate::pr_warn!(
+            crate::pr_warn_once!(
                 "attempted to create `Error` with out of range `errno`: {}",
                 errno
             );

-- 
2.44.1

