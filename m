From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:26 +0100
Subject: [PATCH v3 04/12] rust: kernel: add srctree-relative doclinks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-4-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1495;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=kLgaqmllmKNEoPT8KkSdoCC7kj+DdGrDcoL6QfU76KA=;
 b=7S3b+DjY5YBQva6+YSgVQsa22uB6Rj3uPyuLUNr8VssbgZuwJb/abEN7dWypql8P+MEF2keoc
 weVwL3OLTgqDx5AquVTxmPWwyq1xxyVqvm6sbHhS8rgqT9XMEwXLPWG
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Convert existing references to C header files to make use of
Commit bc2e7d5c298a ("rust: support `srctree`-relative links").

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/lib.rs          | 2 +-
 rust/kernel/sync/condvar.rs | 2 ++
 2 files changed, 3 insertions(+), 1 deletion(-)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index b89ecf4e97a0..74581c958a6c 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -78,7 +78,7 @@ pub trait Module: Sized + Sync {
 
 /// Equivalent to `THIS_MODULE` in the C API.
 ///
-/// C header: `include/linux/export.h`
+/// C header: [`include/linux/export.h`](srctree/include/linux/export.h)
 pub struct ThisModule(*mut bindings::module);
 
 // SAFETY: `THIS_MODULE` may be used from all threads within a module.
diff --git a/rust/kernel/sync/condvar.rs b/rust/kernel/sync/condvar.rs
index 9f1d83589beb..fa1794972aa0 100644
--- a/rust/kernel/sync/condvar.rs
+++ b/rust/kernel/sync/condvar.rs
@@ -87,6 +87,8 @@ pub struct CondVar {
 
     /// A condvar needs to be pinned because it contains a [`struct list_head`] that is
     /// self-referential, so it cannot be safely moved once it is initialised.
+    ///
+    /// [`struct list_head`]: srctree/include/linux/types.h
     #[pin]
     _pin: PhantomPinned,
 }

-- 
2.43.0

