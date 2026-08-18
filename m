From: Younes Akhouayri <git@younes.io>
Date: Tue, 18 Aug 2026 10:11:17 +0200
Subject: [PATCH] rust: configfs: skip unregister after failed registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-fix-rust-configfs-registration-state-v1-v1-1-c929990bc8ef@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQ6DMAwEv4J8rlUgErT9StVDSJ3gHkJlG4SE+
 HsDPc5qZ3cDJWFSeFQbCC2sPOUCzaWCMPqcCPldGNq67epb02PkFWVWwzDlyCkqCiVWE29FRTV
 vhEuD0TsXQ+juXe+grH2Fino+PV9/1nn4ULBj/mgMXgkH8TmMRzQJJ87X8yvTarDvP9+ThG2uA
 AAA
X-Change-ID: 20260817-fix-rust-configfs-registration-state-v1-fa33fcc69673
To: Andreas Hindborg <a.hindborg@kernel.org>, 
 Breno Leitao <leitao@debian.org>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787040714; l=2784;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=fq9IhNazzdfraRSzrziDpi6hbbRXKdNjCvoUNURPKos=;
 b=GI0DFAXw+vFW5/eeEye07BF7E519j/ErwhdwR2Ban8NVu3mUZartkupJXHtpZeDlh088lHXYw
 JizTNA0Nm2dAOqqxelUAR8qGSrwhy0LcpNZxGhpOkkYiiBMLEGpmZPF
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Subsystem::new() calls configfs_register_subsystem() from a fallible
pin_chain callback. If registration fails, ChainPinInit drops the
already initialized Subsystem. Its PinnedDrop currently calls
configfs_unregister_subsystem() unconditionally.

configfs_unregister_subsystem() requires registration to have completed
and immediately dereferences the subsystem dentry. Registering a
duplicate subsystem name returns -EEXIST before installing that dentry,
so the cleanup path dereferences NULL and panics the kernel.

Track successful registration explicitly and only unregister in that
state. Keep mutex destruction unconditional because it is initialized
before registration.

Fixes: 446cafc295bf ("rust: configfs: introduce rust support for configfs")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 rust/kernel/configfs.rs | 14 ++++++++++----
 1 file changed, 10 insertions(+), 4 deletions(-)

diff --git a/rust/kernel/configfs.rs b/rust/kernel/configfs.rs
index cd082b83e9e7..f358e227ce09 100644
--- a/rust/kernel/configfs.rs
+++ b/rust/kernel/configfs.rs
@@ -130,6 +130,7 @@ pub struct Subsystem<Data> {
     subsystem: Opaque<bindings::configfs_subsystem>,
     #[pin]
     data: Data,
+    registered: bool,
 }
 
 // SAFETY: We do not provide any operations on `Subsystem`.
@@ -173,12 +174,15 @@ pub fn new(
                 }
             ),
             data <- data,
+            registered: false,
         })
-        .pin_chain(|this| {
+        .pin_chain(|mut this| {
             crate::error::to_result(
                 // SAFETY: We initialized `this.subsystem` according to C API contract above.
                 unsafe { bindings::configfs_register_subsystem(this.subsystem.get()) },
-            )
+            )?;
+            *this.as_mut().project().registered = true;
+            Ok(())
         })
     }
 }
@@ -186,8 +190,10 @@ pub fn new(
 #[pinned_drop]
 impl<Data> PinnedDrop for Subsystem<Data> {
     fn drop(self: Pin<&mut Self>) {
-        // SAFETY: We registered `self.subsystem` in the initializer returned by `Self::new`.
-        unsafe { bindings::configfs_unregister_subsystem(self.subsystem.get()) };
+        if self.registered {
+            // SAFETY: `registered` is only set after `self.subsystem` was registered.
+            unsafe { bindings::configfs_unregister_subsystem(self.subsystem.get()) };
+        }
         // SAFETY: We initialized the mutex in `Subsystem::new`.
         unsafe { bindings::mutex_destroy(&raw mut (*self.subsystem.get()).su_mutex) };
     }

---
base-commit: 47f27155f17498fccb1f222f79089642337498a9
change-id: 20260817-fix-rust-configfs-registration-state-v1-fa33fcc69673

Best regards,
--  
Younes Akhouayri <git@younes.io>

