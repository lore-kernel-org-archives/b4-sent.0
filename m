From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 03 Jul 2026 15:29:27 +0000
Subject: [PATCH 6/7] rust_binder: Implement BINDER_DEBUG_FAILED_TRANSACTION
 logging for death notification allocation failures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-rust_binder_debug_mask-v1-6-9bdf12b5325c@google.com>
References: <20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com>
In-Reply-To: <20260703-rust_binder_debug_mask-v1-0-9bdf12b5325c@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783092563; l=1150;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=pN1rgHesVhztljUkcVdGtMP5EXBjpUqDWIIh6dRhEyo=;
 b=1CbHGorrLuhNkfnl/SCiLISTOnU/UdNXrZjmx50pgY+1/xuxBYVFuGjkwAWjx+cPWnXtXLUGy
 qxb4rqivUJNAxKBT2g7P2SkXVCg8rzwRm06AagR0aCh0cV9QFHTQXmD
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Memory allocation failures when registering process death
  notifications due to out-of-memory (OOM) conditions.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/process.rs | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/android/binder/process.rs b/drivers/android/binder/process.rs
index db929cc35585..4c200d3d5604 100644
--- a/drivers/android/binder/process.rs
+++ b/drivers/android/binder/process.rs
@@ -1238,6 +1238,11 @@ pub(crate) fn request_death(
         // Queue BR_ERROR if we can't allocate memory for the death notification.
         let death = UniqueArc::new_uninit(GFP_KERNEL).inspect_err(|_| {
             thread.push_return_work(BR_ERROR);
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_FAILED_TRANSACTION,
+                "process {} BC_REQUEST_DEATH_NOTIFICATION failed",
+                self.pid_in_current_ns()
+            );
         })?;
         let mut refs = self.node_refs.lock();
         let Some(info) = refs.by_handle.get_mut(&handle) else {

-- 
2.55.0.rc0.799.gd6f94ed593-goog

