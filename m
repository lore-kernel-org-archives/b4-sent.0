From: Daniil Detkov <d4n11l@proton.me>
Date: Wed, 05 Aug 2026 17:50:56 +0500
Subject: [PATCH] rust_binder: enforce delivered death process ownership
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260805-fix-rust-binder-death-ownership-v1-1-a89594c3b5db@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNSw7CMAwFr1J5jUVoBUJcBbFwUqfxxqns8pGq3
 p1QliPNm7eCswk73LoVjF/iUrXB6dBBKqQTo4yNoQ/9JVzDGbN80J6+YBQd2XBkWgrWt7J5kRk
 pZ0pD5jxQhFaZjdtkf7g/Gkdyxmikqfy61WQSPe7Fv7dtX2eaOmCVAAAA
X-Change-ID: 20260805-fix-rust-binder-death-ownership-affac3fef3ab
To: Todd Kjos <tkjos@android.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Carlos Llamas <cmllamas@google.com>, Alice Ryhl <aliceryhl@google.com>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Christian Brauner <brauner@kernel.org>
Cc: Daniel Almeida <daniel.almeida@collabora.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 Andreas Hindborg <a.hindborg@kernel.org>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Alexandre Courbot <acourbot@nvidia.com>, 
 rust-for-linux@vger.kernel.org, Danilo Krummrich <dakr@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785934267; l=3577;
 i=d4n11l@proton.me; s=20260805; h=from:subject:message-id;
 bh=IWSU6zQf1qTqHaWNUN2CFAVgjNV4N27WuU++TwUxhgc=;
 b=ud4r7edXqNZXOmk2DSHsp9/stTop420f/c4+I0ku20ojT0dVVU8HGsdOwkeW5vczmdwvw3ovE
 jB7AHsxhOeDB30rTkYo+fl44fVEEgRgkDrd9sNwN+V6AV9XjWtNqw4+
X-Developer-Key: i=d4n11l@proton.me; a=ed25519;
 pk=lhWhUROF4Ygx4xYQrngLRbK6h4QpiHWk++S1vtq/s+A=
X-Endpoint-Received: by B4 Relay for d4n11l@proton.me/20260805 with auth_id=921
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The delivered_links field of NodeDeath may only be linked into the
delivered_deaths list owned by NodeDeath::process. The existing safe
ProcessInner::death_delivered method does not enforce that relationship,
so safe Rust can violate the invariant relied on by a later unsafe list
removal.

Move the insertion boundary to Process and validate both the supplied
guard and the NodeDeath owner before mutating the list. Keep the existing
lock order and duplicate-insertion behavior unchanged.

Fixes: eafedbc7c050 ("rust_binder: add Rust Binder driver")
Closes: https://github.com/Rust-for-Linux/linux/issues/1238
Assisted-by: Codex:5.6-Sol
Signed-off-by: Daniil Detkov <d4n11l@proton.me>
---
 drivers/android/binder/node.rs    |  6 +++++-
 drivers/android/binder/process.rs | 23 +++++++++++++++--------
 2 files changed, 20 insertions(+), 9 deletions(-)

diff --git a/drivers/android/binder/node.rs b/drivers/android/binder/node.rs
index c10148e90..813718486 100644
--- a/drivers/android/binder/node.rs
+++ b/drivers/android/binder/node.rs
@@ -978,6 +978,10 @@ pub(crate) fn new(
         ))
     }
 
+    pub(crate) fn belongs_to_process(&self, process: &Process) -> bool {
+        core::ptr::eq(&*self.process, process)
+    }
+
     /// Sets the cleared flag to `true`.
     ///
     /// It removes `self` from the node's death notification list if needed.
@@ -1103,7 +1107,7 @@ fn do_work(
             }
             // We're still holding the inner lock, so it cannot be aborted while we insert it into
             // the delivered list.
-            process_inner.death_delivered(self.clone());
+            process.death_delivered(&mut process_inner, self.clone());
             BR_DEAD_BINDER
         };
 
diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index cdd1a9079..5c5ce7c01 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -309,14 +309,6 @@ fn pull_delivered_death(&mut self, cookie: u64) -> Option<DArc<NodeDeath>> {
         None
     }
 
-    pub(crate) fn death_delivered(&mut self, death: DArc<NodeDeath>) {
-        if let Some(death) = ListArc::try_from_arc_or_drop(death) {
-            self.delivered_deaths.push_back(death);
-        } else {
-            pr_warn!("Notification added to `delivered_deaths` twice.");
-        }
-    }
-
     pub(crate) fn add_outstanding_txn(&mut self) {
         self.outstanding_txns += 1;
     }
@@ -920,6 +912,21 @@ pub(crate) fn get_node_from_handle(&self, handle: u32, strong: bool) -> Result<N
             .clone(strong)
     }
 
+    pub(crate) fn death_delivered(
+        &self,
+        inner: &mut Guard<'_, ProcessInner, SpinLockBackend>,
+        death: DArc<NodeDeath>,
+    ) {
+        assert!(core::ptr::eq(&self.inner, inner.lock_ref()));
+        assert!(death.belongs_to_process(self));
+
+        if let Some(death) = ListArc::try_from_arc_or_drop(death) {
+            inner.delivered_deaths.push_back(death);
+        } else {
+            pr_warn!("Notification added to `delivered_deaths` twice.");
+        }
+    }
+
     pub(crate) fn remove_from_delivered_deaths(&self, death: &DArc<NodeDeath>) {
         let mut inner = self.inner.lock();
         // SAFETY: By the invariant on the `delivered_links` field, this is the right linked list.

---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260805-fix-rust-binder-death-ownership-affac3fef3ab

Best regards,
-- 
Daniil Detkov <d4n11l@proton.me>

