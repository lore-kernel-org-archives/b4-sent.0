From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 10 Jul 2026 14:32:57 +0000
Subject: [PATCH v2 6/7] rust_binder: Implement
 BINDER_DEBUG_DEATH_NOTIFICATION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260710-rust_binder_debug_mask-v2-6-2846410e3ae6@google.com>
References: <20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com>
In-Reply-To: <20260710-rust_binder_debug_mask-v2-0-2846410e3ae6@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783693978; l=2594;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=AtOGqyV47uTWj1HVWVVsjmE5n4vxfurKNFw6THldUO8=;
 b=giAJSkYT/xgVZhtrblO4c1b6WXZ/zQU3csQ6ylYRFzxOWxxBs0k3YU8KSXXqFRfgr7W/n4YMm
 JzBLJqZZKPMCX/qwuxtYR2L6nYUaS6SgSuw+cme9kvK3Z9/+B6yPSLo
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

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/node.rs    |  5 +++++
 drivers/android/binder/process.rs | 14 ++++++++++++++
 2 files changed, 19 insertions(+)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index dfad3697f672..898412cfddd9 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -1113,6 +1113,11 @@ fn do_work(
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
index db2b0230d19f..b1f1207ee868 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -1267,6 +1267,10 @@ pub(crate) fn request_death(
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
@@ -1310,6 +1314,11 @@ pub(crate) fn request_death(
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
 
@@ -1353,6 +1362,11 @@ pub(crate) fn clear_death(&self, reader: &mut UserSliceReader, thread: &Thread)
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

