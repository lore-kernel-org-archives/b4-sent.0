From: Peder Bergan <peder.bergan@gmail.com>
Date: Tue, 24 Nov 2026 16:04:27 +0100
Subject: [PATCH] rust_binder: Reuse the thread lock in get_work_local()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-perf-binder-local-work-lock-v1-1-bd8de1a840c1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHqnBWsC/y2NwQ6CMBBEf4Xs2Y22Con+iuHQLousYCFbVBLCv
 9uqt3mTyZsVIqtwhEuxgvJLoowhgdkVQJ0LN0ZpEoM92MoYe8KJtUUvoWHFYSQ34HvUPscez8R
 lY9pjVXqCZJiUW1m+9mv94/j0d6Y5K/PCu8jo1QXqcpVx/5ene8WHRMLAywzb9gEAY4CIrAAAA
 A==
X-Change-ID: 20261124-perf-binder-local-work-lock-9ce5d1f365bc
To: Alice Ryhl <aliceryhl@google.com>, Carlos Llamas <cmllamas@google.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795532670; l=2392;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=k87ZI/+ha75fn1g5XBGLfDU1bztuNUMRFI6wDLR16zM=;
 b=Dh/KftYuXr4qIUN9KM7ma0M2n+MUTiROu6hg1VznFEVOG0WMQNP23FDNCR4pJeN0L5nkyaeYX
 bnX2104jrWpDe1rsEBESM0eVqI+ylB56Nq8K6Qyvnnean6aHQh/40IU
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

get_work_local() takes the thread lock to check looper_need_return.
When the flag is clear, it drops and retakes the lock before trying to
pop work for either a blocking or a nonblocking read.

Keep the guard across the flag check and the first pop. A blocking
read that finds no work still registers its wait before the condition
variable releases the guard, so a producer can wake the reader.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
Reusing the guard eliminated 4,013 lock acquisitions and 4,013 releases
on each of two x86-64 KVM hosts. Each trace covered setup and 1,000
synchronous Binder echo calls. Both kernels passed checks for empty
nonblocking reads, signal interruption and waking a blocked reader by
closing a duplicate Binder file descriptor.

OpenAI Codex assisted with coding and testing.
---
 drivers/android/binder/thread.rs | 11 ++++-------
 1 file changed, 4 insertions(+), 7 deletions(-)

diff --git a/drivers/android/binder/thread.rs b/drivers/android/binder/thread.rs
index 54a208caebe12..8efda6e9ded1e 100644
--- a/drivers/android/binder/thread.rs
+++ b/drivers/android/binder/thread.rs
@@ -549,20 +549,17 @@ pub(crate) fn has_current_transaction(&self) -> bool {
     // mangled symbol names.
     #[export_name = "rust_binder_waitlcl"]
     fn get_work_local(self: &Arc<Self>, wait: bool) -> Result<Option<DLArc<dyn DeliverToRead>>> {
-        {
-            let mut inner = self.inner.lock();
-            if inner.looper_need_return {
-                return Ok(inner.pop_work());
-            }
+        let mut inner = self.inner.lock();
+        if inner.looper_need_return {
+            return Ok(inner.pop_work());
         }
 
         // Try once if the caller does not want to wait.
         if !wait {
-            return self.inner.lock().pop_work().ok_or(EAGAIN).map(Some);
+            return inner.pop_work().ok_or(EAGAIN).map(Some);
         }
 
         // Loop waiting only on the local queue (i.e., not registering with the process queue).
-        let mut inner = self.inner.lock();
         loop {
             if let Some(work) = inner.pop_work() {
                 return Ok(Some(work));

---
base-commit: 917fcbf033154a6c8d83cfa6c88f012b71eb37b2
change-id: 20261124-perf-binder-local-work-lock-9ce5d1f365bc

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

