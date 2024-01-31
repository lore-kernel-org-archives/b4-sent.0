From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:24 +0100
Subject: [PATCH v3 02/12] rust: error: improve unsafe code in example
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-2-0c8af94ed7de@valentinobst.de>
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
 Valentin Obst <kernel@valentinobst.de>, 
 Martin Rodriguez Reboredo <yakoyoku@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1327;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=6+MgMwYSzO387ZH/l2u1ebga1PIh0bS6tqLpjrjT2uo=;
 b=Z/KZuTuucZxrwSZ2hrvH8wBevQGTrKv8ViFSulOXQ1vFBR+NAq8VtP/cKqkH5mqutwRli950E
 awsD2FxX7uKDb2cDfX6wfRCyUn4Pjr4siGeIBadFu//Jic/rXph6dUM
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The `from_err_ptr` function is safe. There is no need for the call to it
to be inside the unsafe block.

Reword the SAFETY comment to provide a better justification of why the
FFI call is safe.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/error.rs | 10 +++-------
 1 file changed, 3 insertions(+), 7 deletions(-)

diff --git a/rust/kernel/error.rs b/rust/kernel/error.rs
index 4f0c1edd63b7..4786d3ee1e92 100644
--- a/rust/kernel/error.rs
+++ b/rust/kernel/error.rs
@@ -264,13 +264,9 @@ pub fn to_result(err: core::ffi::c_int) -> Result {
 ///     pdev: &mut PlatformDevice,
 ///     index: u32,
 /// ) -> Result<*mut core::ffi::c_void> {
-///     // SAFETY: FFI call.
-///     unsafe {
-///         from_err_ptr(bindings::devm_platform_ioremap_resource(
-///             pdev.to_ptr(),
-///             index,
-///         ))
-///     }
+///     // SAFETY: `pdev` points to a valid platform device. There are no safety requirements
+///     // on `index`.
+///     from_err_ptr(unsafe { bindings::devm_platform_ioremap_resource(pdev.to_ptr(), index) })
 /// }
 /// ```
 // TODO: Remove `dead_code` marker once an in-kernel client is available.

-- 
2.43.0

