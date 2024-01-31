From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:31 +0100
Subject: [PATCH v3 09/12] rust: kernel: add blank lines in front of code
 blocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-9-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1527;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=uY1sZnb/LMfFXaWeBAwEM8DMFKBsaytN4jZN05O/ykE=;
 b=99dau8uj89rQF+Ui2JVfPI4xnHVD6+T01C8FkwBqgFe94TWEWf3h/+vqiyLPqj9bgVxIXeeWy
 Sz7HbN+z06sBam3gLTECfS+tY1SSHGwiOu6AV7FDJFKsZ4pC8ygnQKz
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Throughout the code base, blank lines are used before starting a code
block. Adapt outliers to improve consistency within the kernel crate.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/types.rs | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/rust/kernel/types.rs b/rust/kernel/types.rs
index fdb778e65d79..8aabe348b194 100644
--- a/rust/kernel/types.rs
+++ b/rust/kernel/types.rs
@@ -90,6 +90,7 @@ unsafe fn from_foreign(_: *const core::ffi::c_void) -> Self {}
 ///
 /// In the example below, we have multiple exit paths and we want to log regardless of which one is
 /// taken:
+///
 /// ```
 /// # use kernel::types::ScopeGuard;
 /// fn example1(arg: bool) {
@@ -108,6 +109,7 @@ unsafe fn from_foreign(_: *const core::ffi::c_void) -> Self {}
 ///
 /// In the example below, we want to log the same message on all early exits but a different one on
 /// the main exit path:
+///
 /// ```
 /// # use kernel::types::ScopeGuard;
 /// fn example2(arg: bool) {
@@ -129,6 +131,7 @@ unsafe fn from_foreign(_: *const core::ffi::c_void) -> Self {}
 ///
 /// In the example below, we need a mutable object (the vector) to be accessible within the log
 /// function, so we wrap it in the [`ScopeGuard`]:
+///
 /// ```
 /// # use kernel::types::ScopeGuard;
 /// fn example3(arg: bool) -> Result {

-- 
2.43.0

