From: Valentin Obst <kernel@valentinobst.de>
Date: Wed, 31 Jan 2024 21:23:34 +0100
Subject: [PATCH v3 12/12] rust: locked_by: shorten doclink preview
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240131-doc-fixes-v3-v3-12-0c8af94ed7de@valentinobst.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706732646; l=1666;
 i=kernel@valentinobst.de; s=20240131; h=from:subject:message-id;
 bh=sqg0B5Wr1bFP5Krb6u5ZgMS6Wtgf+9jYvaOmeO5jfXs=;
 b=lQBqbaRJYx0+ptyykohvXQroXhFbdrLF8+38IIQ+Mrgzdcc4iQGLoNEXfOVgcOP4WxwiMVtZ7
 lHRemgJ/QGwD5JvssVna2L6r4kIbhLvEGdxnqRbd19Zmt64CVD0tjKM
X-Developer-Key: i=kernel@valentinobst.de; a=ed25519;
 pk=3s7U8y0mqkaiurgHSQQTYWOo2tw5HgzCg5vnJVfw37Y=
X-Endpoint-Received: by B4 Relay for kernel@valentinobst.de/20240131 with auth_id=124
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Increases readability by removing `super::` from the link preview
text.

Signed-off-by: Valentin Obst <kernel@valentinobst.de>
Reviewed-by: Trevor Gross <tmgross@umich.edu>
Reviewed-by: Martin Rodriguez Reboredo <yakoyoku@gmail.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
---
 rust/kernel/sync/locked_by.rs | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/rust/kernel/sync/locked_by.rs b/rust/kernel/sync/locked_by.rs
index b17ee5cd98f3..babc731bd5f6 100644
--- a/rust/kernel/sync/locked_by.rs
+++ b/rust/kernel/sync/locked_by.rs
@@ -9,14 +9,17 @@
 /// Allows access to some data to be serialised by a lock that does not wrap it.
 ///
 /// In most cases, data protected by a lock is wrapped by the appropriate lock type, e.g.,
-/// [`super::Mutex`] or [`super::SpinLock`]. [`LockedBy`] is meant for cases when this is not
-/// possible. For example, if a container has a lock and some data in the contained elements needs
+/// [`Mutex`] or [`SpinLock`]. [`LockedBy`] is meant for cases when this is not possible.
+/// For example, if a container has a lock and some data in the contained elements needs
 /// to be protected by the same lock.
 ///
 /// [`LockedBy`] wraps the data in lieu of another locking primitive, and only allows access to it
 /// when the caller shows evidence that the 'external' lock is locked. It panics if the evidence
 /// refers to the wrong instance of the lock.
 ///
+/// [`Mutex`]: super::Mutex
+/// [`SpinLock`]: super::SpinLock
+///
 /// # Examples
 ///
 /// The following is an example for illustrative purposes: `InnerDirectory::bytes_used` is an

-- 
2.43.0

