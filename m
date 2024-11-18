From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 18 Nov 2024 20:07:00 +0530
Subject: [PATCH v3 3/3] rust: macros: simplify Result<()> in function
 returns
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241118-simplify-result-v3-3-6b1566a77eab@iiitd.ac.in>
References: <20241118-simplify-result-v3-0-6b1566a77eab@iiitd.ac.in>
In-Reply-To: <20241118-simplify-result-v3-0-6b1566a77eab@iiitd.ac.in>
To: FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Trevor Gross <tmgross@umich.edu>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, Alice Ryhl <aliceryhl@google.com>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Anup Sharma <anupnewsmail@gmail.com>, netdev@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-block@vger.kernel.org, Manas <manas18244@iiitd.ac.in>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731940618; l=1445;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=NTTuXPWy5AUeqCEPojOUwO8gX5t/CAh+3ZZpchSjGSw=;
 b=TvZk+POq6esMzkJ39tL4CXbkwnxgKtAKjrW1VbhsNzlmzrcikgodE1xGSsj5SBJ+2ZWv8+42z
 ALzxsGbc1aoAJxPiSudyRmYmI22IvW9BpJV5IlEEHGn2VbgFrdfC6y+
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Functions foo and bar in doctests return `Result<()>` type. This type
can be simply written as `Result` as default type parameters are unit
`()` and `Error` types. Thus keep the usage of `Result` consistent.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1128
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
 rust/macros/lib.rs | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/rust/macros/lib.rs b/rust/macros/lib.rs
index 4ab94e44adfe3206faad159e81417ea41a35815b..463920353ca9c408f5d69e2626c13a173bae98d7 100644
--- a/rust/macros/lib.rs
+++ b/rust/macros/lib.rs
@@ -144,11 +144,11 @@ pub fn module(ts: TokenStream) -> TokenStream {
 /// // Declares a `#[vtable]` trait
 /// #[vtable]
 /// pub trait Operations: Send + Sync + Sized {
-///     fn foo(&self) -> Result<()> {
+///     fn foo(&self) -> Result {
 ///         kernel::build_error(VTABLE_DEFAULT_ERROR)
 ///     }
 ///
-///     fn bar(&self) -> Result<()> {
+///     fn bar(&self) -> Result {
 ///         kernel::build_error(VTABLE_DEFAULT_ERROR)
 ///     }
 /// }
@@ -158,7 +158,7 @@ pub fn module(ts: TokenStream) -> TokenStream {
 /// // Implements the `#[vtable]` trait
 /// #[vtable]
 /// impl Operations for Foo {
-///     fn foo(&self) -> Result<()> {
+///     fn foo(&self) -> Result {
 /// #        Err(EINVAL)
 ///         // ...
 ///     }

-- 
2.47.0

