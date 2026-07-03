From: Jahnavi MN <jahnavimn@google.com>
Date: Fri, 03 Jul 2026 15:29:26 +0000
Subject: [PATCH 5/7] rust_binder: Implement the
 BINDER_DEBUG_FAILED_TRANSACTION logging mask for transaction parsing and
 routing failures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260703-rust_binder_debug_mask-v1-5-9bdf12b5325c@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783092563; l=3866;
 i=jahnavimn@google.com; s=20260702; h=from:subject:message-id;
 bh=lhDwr5z2mnm33UNmF+M4c23cZnU/CATsdD2Yk/m7PNc=;
 b=6BMbdtWnti5RyUjf1XQ7kTBHHQOposUDX1b0Wz267ejokT8u+c8FyQu0nwtB8A+7pbDRGGjFz
 ePqcrCX7aiFBOotN2ZX9iJJ6nJk26D/Z1urJzdCFqSaCLq1M7RwCUgw
X-Developer-Key: i=jahnavimn@google.com; a=ed25519;
 pk=9aLfw3FepTOJwTS7jRXm7pDH87eBeZMXBPrqwU0//RE=
X-Endpoint-Received: by B4 Relay for jahnavimn@google.com/20260702 with auth_id=849
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds dynamic debug logs for:
- Failed replies, target process deaths, and error code deliveries.
- Detailed transaction failure diagnostics (including sender/receiver
  PIDs, TIDs, transaction IDs, buffer sizes, and error codes).
- File descriptor (FD) array validation and translation errors.

Signed-off-by: Jahnavi MN <jahnavimn@google.com>
---
 drivers/android/binder/thread.rs      | 40 +++++++++++++++++++++++++++++++----
 drivers/android/binder/transaction.rs |  5 +++++
 2 files changed, 41 insertions(+), 4 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index ecf05cebcb3e..1656e0c70fef 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -1191,6 +1191,11 @@ fn deliver_single_reply(
             }
 
             if inner.is_dead {
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_FAILED_TRANSACTION,
+                    "send failed reply for transaction {}, target dead",
+                    transaction.debug_id
+                );
                 return true;
             }
 
@@ -1198,7 +1203,18 @@ fn deliver_single_reply(
                 Ok(work) => {
                     inner.push_work(work);
                 }
-                Err(code) => inner.push_reply_work(code),
+                Err(code) => {
+                    if code == BR_FAILED_REPLY || code == BR_DEAD_REPLY {
+                        binder_debug!(
+                            crate::debug::BINDER_DEBUG_FAILED_TRANSACTION,
+                            "send failed reply for transaction {} to {}:{}",
+                            transaction.debug_id,
+                            self.process.task.pid(),
+                            self.task.pid()
+                        );
+                    }
+                    inner.push_reply_work(code)
+                }
             }
         }
 
@@ -1297,11 +1313,27 @@ fn transaction(self: &Arc<Self>, cmd: u32, reader: &mut UserSliceReader) -> Resu
                     ee.param = source.to_errno();
                 }
 
-                pr_warn!(
-                    "{}:{} transaction to {} failed: {source:?}",
+                binder_debug!(
+                    crate::debug::BINDER_DEBUG_FAILED_TRANSACTION,
+                    "{}:{} transaction {} to {}:{} failed {}/{}/{}, code {} size {}-{} line {}",
                     info.from_pid,
                     info.from_tid,
-                    info.to_pid
+                    if info.is_reply {
+                        "reply"
+                    } else if info.is_oneway() {
+                        "async"
+                    } else {
+                        "call"
+                    },
+                    info.to_pid,
+                    info.to_tid,
+                    info.debug_id,
+                    err.reply,
+                    info.errno,
+                    info.code,
+                    info.data_size,
+                    info.offsets_size,
+                    line!()
                 );
             }
         }
diff --git a/drivers/android/binder/transaction.rs b/drivers/android/binder/transaction.rs
index f9285eb93fc0..f8756c5dfba4 100644
--- a/drivers/android/binder/transaction.rs
+++ b/drivers/android/binder/transaction.rs
@@ -405,6 +405,11 @@ fn do_work(
         } else {
             // On failure to process the list, we send a reply back to the sender and ignore the
             // transaction on the recipient.
+            binder_debug!(
+                crate::debug::BINDER_DEBUG_FAILED_TRANSACTION,
+                "transaction {} fd fixups failed",
+                self.debug_id
+            );
             return Ok(true);
         };
 

-- 
2.55.0.rc0.799.gd6f94ed593-goog

