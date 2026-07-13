From: Jahnavi MN <jahnavimn@google.com>
Date: Mon, 13 Jul 2026 12:35:28 +0000
Subject: [PATCH v3 6/7] rust_binder: Implement
 BINDER_DEBUG_DEATH_NOTIFICATION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-rust_binder_debug_mask-v3-6-0de91bbbbf69@google.com>
References: <20260713-rust_binder_debug_mask-v3-0-0de91bbbbf69@google.com>
In-Reply-To: <20260713-rust_binder_debug_mask-v3-0-0de91bbbbf69@google.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: linux-kernel@vger.kernel.org, rust-for-linux@vger.kernel.org, 
 Jahnavi MN <jahnavimn@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783946130; l=2692;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=Ac2/HhH4s3DlFi55GxIloHEGDjTqfnRwxNUHDja4HeI=;
 b=yfGc+GP3VvqjNRlJmoaDXFpEMxjfZRjbMUxz0D4asGe7UYhryD5Cbyby6Z9wSDNV7/0QvQRIx
 KRCNr1vOHtSBlM1fz8qBveTrC+nc9LL9ev3rLKSb49HhCyOobmILnN8
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Memory allocation (OOM) failures when requesting
  death notifications
- Registration and cancellation lifecycle events
  (BC_REQUEST / BC_CLEAR)
- Delivery of death notification events to userspace
  (BR_DEAD_BINDER)

Reviewed-by: Carlos Llamas <cmllamas@google.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/node.rs    |  5 +++++
 drivers/android/binder/process.rs | 14 ++++++++++++++
 2 files changed, 19 insertions(+)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index 3f0757058b84..87a2e613a816 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -1105,6 +1105,11 @@ fn do_work(
             // We're still holding the inner lock, so it cannot be aborted while we insert it into
             // the delivered list.
             process_inner.death_delivered(self.clone());
+            binder_debug!(
+                DeathNotification,
+                "sending death notification, cookie {:016x}",
+                cookie
+            );
             BR_DEAD_BINDER
         };
 
diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index 38190aaa462d..42330fd409c4 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -1239,6 +1239,10 @@ pub(crate) fn request_death(
         // Queue BR_ERROR if we can't allocate memory for the death notification.
         let death = UniqueArc::new_uninit(GFP_KERNEL).inspect_err(|_| {
             thread.push_return_work(BR_ERROR);
+            binder_debug!(
+                DeathNotification,
+                "BC_REQUEST_DEATH_NOTIFICATION failed due to memory allocation failure"
+            );
         })?;
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {
@@ -1282,6 +1286,11 @@ pub(crate) fn request_death(
                 info.node_ref().node.add_death(death, &mut owner_inner);
             }
         }
+        binder_debug!(
+            DeathNotification,
+            "BC_REQUEST_DEATH_NOTIFICATION handle {handle} cookie {:016x}",
+            cookie
+        );
         Ok(())
     }
 
@@ -1325,6 +1334,11 @@ pub(crate) fn clear_death(&self, reader: &mut UserSliceReader, thread: &Thread)
             }
         }
 
+        binder_debug!(
+            DeathNotification,
+            "BC_CLEAR_DEATH_NOTIFICATION handle {handle} cookie {:016x}",
+            cookie
+        );
         Ok(())
     }
 

-- 
2.55.0.795.g602f6c329a-goog

