From: Younes Akhouayri <git@younes.io>
Date: Tue, 18 Aug 2026 19:44:03 +0200
Subject: [PATCH v2] rust: configfs: skip unregister after failed
 registration
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260818-fix-rust-configfs-registration-state-v1-v2-1-9acedd3070f7@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OvQ7CMAyEXwVlxtAfqTRMvAfqkAanNUOC7LRqh
 fruJEXsSF7Ourvv3kqQCUVdD2/FOJNQ8ElUx4Oyo/EDAj2SVlVRNUVbXsDRAjxJBBu8o8EJMA4
 kkU1MUZBoIsJcgjN17axtdHOpVWp7MaboTrp3Xy1T/0Qbc3129EYQejbejvkVmAby553lcYnZM
 iZQ4HVfO5e56jes/XtYuhKsrrTWRW9bdLc1TB7lREF127Z9AKj1f7wTAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787075052; l=2560;
 i=git@younes.io; s=20260712; h=from:subject:message-id;
 bh=XigsFJKQzV5Pl7ZgU85X77cuEEIuQrLc6riQN8BqfPw=;
 b=x5akoYK46SUGtsHm7ObWCU7My6p3+YJmpPwukjrMVRSzJH9fMgD23KXSkJXEsqBfo3IozKeYI
 8FkigleehaFAXGqEFlga9/fGCiZZQNpx2p4cT/+2kbx41WJNCHdZra+
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=1DRfzPrQ04RQHHgGK28t+vjIAPv5oISPiAdLMU6J5dE=
X-Endpoint-Received: by B4 Relay for git@younes.io/20260712 with auth_id=866
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Subsystem::new() calls configfs_register_subsystem() in pin_chain(). If
registration returns an error, pin_chain() drops the Subsystem. PinnedDrop
then calls configfs_unregister_subsystem() even though registration failed.

Registering a duplicate name returns -EEXIST before ci_dentry is set.
configfs_unregister_subsystem() dereferences ci_dentry, causing a NULL
pointer dereference and kernel panic.

Move configfs_register_subsystem() to the end of try_pin_init!. If
registration fails, destroy su_mutex and return the error. PinnedDrop is
not called because initialization did not finish. Successful subsystems
are still unregistered by PinnedDrop.

Fixes: 446cafc295bf ("rust: configfs: introduce rust support for configfs")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Changes in v2:
- Register the subsystem at the end of try_pin_init!.
- Destroy su_mutex when registration fails.
- Remove the registered flag.
- Link to v1: https://patch.msgid.link/20260818-fix-rust-configfs-registration-state-v1-v1-1-c929990bc8ef@younes.io
---
 rust/kernel/configfs.rs | 19 +++++++++++++------
 1 file changed, 13 insertions(+), 6 deletions(-)

diff --git a/rust/kernel/configfs.rs b/rust/kernel/configfs.rs
index cd082b83e9e7..770e0a022b42 100644
--- a/rust/kernel/configfs.rs
+++ b/rust/kernel/configfs.rs
@@ -173,12 +173,19 @@ pub fn new(
                 }
             ),
             data <- data,
-        })
-        .pin_chain(|this| {
-            crate::error::to_result(
-                // SAFETY: We initialized `this.subsystem` according to C API contract above.
-                unsafe { bindings::configfs_register_subsystem(this.subsystem.get()) },
-            )
+            _: {
+                let result = crate::error::to_result(
+                    // SAFETY: We initialized `subsystem` according to the C API contract above.
+                    unsafe { bindings::configfs_register_subsystem(subsystem.get()) },
+                );
+                if result.is_err() {
+                    // SAFETY: The mutex was initialized above and registration failed.
+                    unsafe {
+                        bindings::mutex_destroy(&raw mut (*subsystem.get()).su_mutex)
+                    };
+                }
+                result?
+            }
         })
     }
 }

---
base-commit: 47f27155f17498fccb1f222f79089642337498a9
change-id: 20260817-fix-rust-configfs-registration-state-v1-fa33fcc69673

Best regards,
--  
Younes Akhouayri <git@younes.io>

