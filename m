From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:52:56 +0800
Subject: [PATCH 03/13] rust: sync: set_once: Rename InitError variants to
 fix clippy warning
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-3-074badd18716@linux.dev>
References: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
In-Reply-To: <20260326-b4-tyr-debugfs-v1-0-074badd18716@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Sumit Semwal <sumit.semwal@linaro.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>
Cc: rust-for-linux@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=1849;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=tUYRpEsjcJwgFiDLyfqu8+WsQSC+51o7zeiWV2WwdXg=;
 b=LejMass/PgiXRGEVCIMUZhQoqRvFp8dZ+rFdyHpwf6Fsnq4qYQsRzZHZilPaqI0LL/f9CBaJ0
 H+g0I5DQj3MAWlxgNapRhv0mnILfZyGSs/JRHNM6EezDqVAUdxlF/lC
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes clippy warning:
warning: all variants have the same postfix: `Init`
  --> rust/kernel/sync/set_once.rs:68:1

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/sync/set_once.rs | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/rust/kernel/sync/set_once.rs b/rust/kernel/sync/set_once.rs
index db9c5423fade3..3af5538aae1d4 100644
--- a/rust/kernel/sync/set_once.rs
+++ b/rust/kernel/sync/set_once.rs
@@ -67,17 +67,17 @@ fn default() -> Self {
 #[derive(Debug)]
 pub enum InitError<E> {
     /// The `Once` has already been initialized.
-    AlreadyInit,
+    Already,
     /// The `Once` is being raced to initialize by another thread.
-    RacedInit,
+    Raced,
     /// Error occurs during initialization.
-    DuringInit(E),
+    Inner(E),
 }
 
 impl<E> From<E> for InitError<E> {
     #[inline]
     fn from(err: E) -> Self {
-        InitError::DuringInit(err)
+        InitError::Inner(err)
     }
 }
 
@@ -85,9 +85,9 @@ impl<E: Into<Error>> From<InitError<E>> for Error {
     #[inline]
     fn from(this: InitError<E>) -> Self {
         match this {
-            InitError::AlreadyInit => EEXIST,
-            InitError::RacedInit => EBUSY,
-            InitError::DuringInit(e) => e.into(),
+            InitError::Already => EEXIST,
+            InitError::Raced => EBUSY,
+            InitError::Inner(e) => e.into(),
         }
     }
 }
@@ -155,8 +155,8 @@ pub fn init<E>(&self, init: impl Init<T, E>) -> Result<&T, InitError<E>> {
                     }
                 }
             }
-            Err(1) => Err(InitError::RacedInit),
-            Err(_) => Err(InitError::AlreadyInit),
+            Err(1) => Err(InitError::Raced),
+            Err(_) => Err(InitError::Already),
         }
     }
 

-- 
2.43.0

