From: Jahnavi MN <jahnavimn@google.com>
Date: Mon, 13 Jul 2026 12:35:27 +0000
Subject: [PATCH v3 5/7] rust_binder: Implement
 BINDER_DEBUG_FAILED_TRANSACTION
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260713-rust_binder_debug_mask-v3-5-0de91bbbbf69@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783946130; l=2626;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=6DwP7RPLyotGGvt0ZpfxbDZP6CqubJEwhR1a0QtfHZM=;
 b=SvGLPUdc1Ysb4rBN5h25WKNPRvYefnq2fzN3RH9Kd0Qkq/0ss1uENX0rpePhSn928G23gj3Li
 L3xt6puJRwuAg09/9LQ+ZLjYDe20LBSFiUYtdi/cEjMZQ8hWzvTIcLi
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Failed replies, target process deaths, and error code deliveries.
- Detailed transaction failure diagnostics (including sender/receiver
  PIDs, TIDs, transaction IDs, buffer sizes, and error codes).

Reviewed-by: Carlos Llamas <cmllamas@google.com>
Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/thread.rs      | 21 ++++++++++++++++-----
 drivers/android/binder/transaction.rs |  8 ++++++++
 2 files changed, 24 insertions(+), 5 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index 072cb4674172..26925d094a59 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -1254,11 +1254,22 @@ fn transaction(self: &Arc<Self>, cmd: u32, reader: &mut UserSliceReader) -> Resu
                     ee.param = source.to_errno();
                 }
 
-                pr_warn!(
-                    "{}:{} transaction to {} failed: {source:?}",
-                    info.from_pid,
-                    info.from_tid,
-                    info.to_pid
+                binder_debug!(
+                    FailedTransaction,
+                    "transaction {} to {}:{} failed {:?}, code {} size {}-{}",
+                    if info.is_reply {
+                        "reply"
+                    } else if info.is_oneway() {
+                        "async"
+                    } else {
+                        "call"
+                    },
+                    info.to_pid,
+                    info.to_tid,
+                    err,
+                    info.code,
+                    info.data_size,
+                    info.offsets_size
                 );
             }
         }
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index 38795224a784..b56dca55662d 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -405,6 +405,14 @@ fn do_work(
         } else {
             // On failure to process the list, we send a reply back to the sender and ignore the
             // transaction on the recipient.
+            binder_debug!(
+                FailedTransaction,
+                "transaction {} to {} failed, fd fixups failed, size {}-{}",
+                self.debug_id,
+                self.to.task.pid(),
+                self.data_size,
+                self.offsets_size
+            );
             return Ok(true);
         };
 

-- 
2.55.0.795.g602f6c329a-goog

