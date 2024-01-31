From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:27 +0100
Subject: [PATCH v3 05/12] rust: str: use `NUL` instead of 0 in doc comments
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-5-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1199;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=t90awkZOfJrNEj9Nqg9r3N76iP/cmOjmkwvkrtyw/9I=;
 b=hqfaaXwqKw/qal+VSCs0YjOz+bA68/qcnK/d1pbkLbyCibjtbc31Gxbrt1UfSfIgjGoTLjxY6
 rJEeLkBTy2EDgEhqxS22yuDkLgnRAuGmCvQBc6KePEKQf5KT1v9gKbu
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Throughout the module, bytes with the value zero are referred to as
`NUL` bytes. Adapt the only two outliers.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/str.rs | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/str.rs b/rust/kernel/str.rs
index 0a8569594fc3..843ffeec9b3e 100644
--- a/rust/kernel/str.rs
+++ b/rust/kernel/str.rs
@@ -149,13 +149,13 @@ pub const fn as_char_ptr(&self) -> *const core::ffi::c_char {
         self.0.as_ptr() as _
     }
 
-    /// Convert the string to a byte slice without the trailing 0 byte.
+    /// Convert the string to a byte slice without the trailing `NUL` byte.
     #[inline]
     pub fn as_bytes(&self) -> &[u8] {
         &self.0[..self.len()]
     }
 
-    /// Convert the string to a byte slice containing the trailing 0 byte.
+    /// Convert the string to a byte slice containing the trailing `NUL` byte.
     #[inline]
     pub const fn as_bytes_with_nul(&self) -> &[u8] {
         &self.0

-- 
2.43.0

