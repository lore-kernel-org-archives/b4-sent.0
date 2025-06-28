From: Janne Grunau <j@jannau.net>
Date: Sat, 28 Jun 2025 13:36:00 +0200
Subject: [PATCH] rust: init: Fix generics in *_init! macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250628-rust_init_trailing_comma-v1-1-2d162ae1a757@jannau.net>
X-B4-Tracking: v=1; b=H4sIAJ/TX2gC/x3MQQqDMBBG4avIrBvQYILtVUoJIY76g8YySYsgu
 bvB5bd476TEAk70ak4S/iNhjxXdo6Gw+DizwlhNutWmtXpQ8kvZISK7LB4r4uzCvm1ecT914Tk
 Y01tNNf8KTzju9ftTygUsesLIagAAAA==
X-Change-ID: 20250628-rust_init_trailing_comma-e4f1c9855462
To: Benno Lossin <lossin@kernel.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Fiona Behrens <me@kloenk.dev>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Janne Grunau <j@jannau.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2610; i=j@jannau.net;
 s=yk2024; h=from:subject:message-id;
 bh=7atD46KJRl40fGYVlD5kwQ0vw0wyITw/tnQszJMm3g8=;
 b=owGbwMvMwCW2UNrmdq9+ahrjabUkhoz4y1sb472uKUWHfsi06d7q9OLYmrlCtWIxXGKFa69ef
 /zRNEWqo5SFQYyLQVZMkSVJ+2UHw+oaxZjaB2Ewc1iZQIYwcHEKwEROvWJkeDlZyXrKCe55EoXH
 H7sIVsffV5m61YnZvEUtloHzVlWPEcP/6D4/oYbH7baCz+8fte1YeqBrT6SVSVNS3I4yJdvsDBl
 GAA==
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/yk2024 with auth_id=264
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The match pattern for a optional trailing comma in the list of generics
is erroneously repeated in the code block resulting in following error:

| error: attempted to repeat an expression containing no syntax variables matched as repeating at this depth
|    --> rust/kernel/init.rs:301:73
|     |
| 301 |         ::pin_init::try_pin_init!($(&$this in)? $t $(::<$($generics),* $(,)?>)? {
|     |                                                                         ^^^

Remove "$(,)?" from all code blocks in the try_init! and try_pin_init!
definitions.

Fixes: 578eb8b6db13 ("rust: pin-init: move the default error behavior of `try_[pin_]init`")
Signed-off-by: Janne Grunau <j@jannau.net>
---
 rust/kernel/init.rs | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/rust/kernel/init.rs b/rust/kernel/init.rs
index 8d228c23795445e379b40f662e1c355a934cbd13..21ef202ab0dbfa3cb28cd20d29d9bfdba4f1f97f 100644
--- a/rust/kernel/init.rs
+++ b/rust/kernel/init.rs
@@ -231,14 +231,14 @@ macro_rules! try_init {
     ($(&$this:ident in)? $t:ident $(::<$($generics:ty),* $(,)?>)? {
         $($fields:tt)*
     }) => {
-        ::pin_init::try_init!($(&$this in)? $t $(::<$($generics),* $(,)?>)? {
+        ::pin_init::try_init!($(&$this in)? $t $(::<$($generics),*>)? {
             $($fields)*
         }? $crate::error::Error)
     };
     ($(&$this:ident in)? $t:ident $(::<$($generics:ty),* $(,)?>)? {
         $($fields:tt)*
     }? $err:ty) => {
-        ::pin_init::try_init!($(&$this in)? $t $(::<$($generics),* $(,)?>)? {
+        ::pin_init::try_init!($(&$this in)? $t $(::<$($generics),*>)? {
             $($fields)*
         }? $err)
     };
@@ -291,14 +291,14 @@ macro_rules! try_pin_init {
     ($(&$this:ident in)? $t:ident $(::<$($generics:ty),* $(,)?>)? {
         $($fields:tt)*
     }) => {
-        ::pin_init::try_pin_init!($(&$this in)? $t $(::<$($generics),* $(,)?>)? {
+        ::pin_init::try_pin_init!($(&$this in)? $t $(::<$($generics),*>)? {
             $($fields)*
         }? $crate::error::Error)
     };
     ($(&$this:ident in)? $t:ident $(::<$($generics:ty),* $(,)?>)? {
         $($fields:tt)*
     }? $err:ty) => {
-        ::pin_init::try_pin_init!($(&$this in)? $t $(::<$($generics),* $(,)?>)? {
+        ::pin_init::try_pin_init!($(&$this in)? $t $(::<$($generics),*>)? {
             $($fields)*
         }? $err)
     };

---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250628-rust_init_trailing_comma-e4f1c9855462

Best regards,
-- 
Janne Grunau <j@jannau.net>

