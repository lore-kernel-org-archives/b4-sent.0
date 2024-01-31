From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:28 +0100
Subject: [PATCH v3 06/12] rust: str: move SAFETY comment in front of unsafe
 block
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240131-doc-fixes-v3-v3-6-0c8af94ed7de@valentinobst.de>
References: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
In-Reply-To: <20240131-doc-fixes-v3-v3-0-0c8af94ed7de@valentinobst.de>
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Valentin Obst <kernel@valentinobst.de>, Trevor Gross <tmgross@umich.edu>, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1018;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=DDoG48Qq56LKmbADR58N8ly1qfgI3wpt9bk2atcwP2I=;
 b=MZe2Hxv9roGYl7lqeSTsKZTqoSJKgkFsgca/PD3aFOr4ulKBTBblhv38PbvagOpZGWXWbWtyj
 YNvZipM8WUGDw3pFzMQXX3OxChgETuOQVPLM3td+l4AGy5t/ZaHB/O5
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SAFETY comments should immediately precede the unsafe block they
justify. Move assignment to `bar` past comment as it is safe.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/str.rs | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/rust/kernel/str.rs b/rust/kernel/str.rs
index 843ffeec9b3e..fec5c4314758 100644
--- a/rust/kernel/str.rs
+++ b/rust/kernel/str.rs
@@ -191,9 +191,9 @@ pub fn to_str(&self) -> Result<&str, core::str::Utf8Error> {
     /// ```
     /// # use kernel::c_str;
     /// # use kernel::str::CStr;
+    /// let bar = c_str!("ツ");
     /// // SAFETY: String literals are guaranteed to be valid UTF-8
     /// // by the Rust compiler.
-    /// let bar = c_str!("ツ");
     /// assert_eq!(unsafe { bar.as_str_unchecked() }, "ツ");
     /// ```
     #[inline]

-- 
2.43.0

