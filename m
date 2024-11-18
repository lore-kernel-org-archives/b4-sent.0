From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 18 Nov 2024 20:06:59 +0530
Subject: [PATCH v3 2/3] rust: uaccess: simplify Result<()> in bytes_add_one
 return
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241118-simplify-result-v3-2-6b1566a77eab@iiitd.ac.in>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731940618; l=1055;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=fXvE4MWPDfjFqc2bAWbwVy1YZ0cGmhfaa/pikK8HjcQ=;
 b=dhrh/6LCfnO2UT0ozqsoiea4r/886wFuhiNyyVGrEQk7OM3yTE7VnC+d5S+BD0WyItpc+9Ym2
 9oa/fIrsgD8BQ0JeiQ8iANowMjk3Z+XKsMHs9JDXmzRiKXAEEGXMGzz
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bytes_add_one returns `Result<()>`, a result over unit type. This can be
simplified to `Result` as default type parameters are unit `()` and
`Error` types. Thus keep the usage of `Result` consistent throughout
codebase.

Suggested-by: Miguel Ojeda <ojeda@kernel.org>
Link: https://github.com/Rust-for-Linux/linux/issues/1128
Signed-off-by: Manas <manas18244@iiitd.ac.in>
---
 rust/kernel/uaccess.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/uaccess.rs b/rust/kernel/uaccess.rs
index 05b0b8d13b10da731af62be03e1c2c13ced3f706..7c21304344ccd943816e38119a5be2ccf8d8e154 100644
--- a/rust/kernel/uaccess.rs
+++ b/rust/kernel/uaccess.rs
@@ -49,7 +49,7 @@
 /// use kernel::error::Result;
 /// use kernel::uaccess::{UserPtr, UserSlice};
 ///
-/// fn bytes_add_one(uptr: UserPtr, len: usize) -> Result<()> {
+/// fn bytes_add_one(uptr: UserPtr, len: usize) -> Result {
 ///     let (read, mut write) = UserSlice::new(uptr, len).reader_writer();
 ///
 ///     let mut buf = KVec::new();

-- 
2.47.0

