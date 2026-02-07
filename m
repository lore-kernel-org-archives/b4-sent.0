From: Shivam Kalra <shivamklr@cock.li>
Date: Sat, 07 Feb 2026 17:02:50 +0530
Subject: [PATCH v3 4/4] rust: binder: shrink all_procs when deregistering
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260207-binder-shrink-vec-v3-v3-4-8ff388563427@cock.li>
References: <20260207-binder-shrink-vec-v3-v3-0-8ff388563427@cock.li>
In-Reply-To: <20260207-binder-shrink-vec-v3-v3-0-8ff388563427@cock.li>
To: Danilo Krummrich <dakr@kernel.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 Vlastimil Babka <vbabka@suse.cz>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Uladzislau Rezki <urezki@gmail.com>, Miguel Ojeda <ojeda@kernel.org>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 =?utf-8?q?Arve_Hj=C3=B8nnev=C3=A5g?= <arve@android.com>, 
 Todd Kjos <tkjos@android.com>, Christian Brauner <brauner@kernel.org>, 
 Carlos Llamas <cmllamas@google.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shivam Kalra <shivamklr@cock.li>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770464219; l=1661;
 i=shivamklr@cock.li; s=20260206; h=from:subject:message-id;
 bh=ZiCG70HlJMmGpDrvsFHeFaXEsLxFngyMnoVpWt9UY3M=;
 b=+mvhlR0YpQsBJJfKSWLVaJRMAoHR/0B3ErKsNbSazRmVprgymHifuQS3NyA0a5x8M/GFn7Uk9
 CpOntfpgurlDbXz2ifUwmPYvl5M/7jUzN2wj2sSI+jAtS8LTt8yeszI
X-Developer-Key: i=shivamklr@cock.li; a=ed25519;
 pk=vMC4wm7HuB8IdkiHldCdtuViW0NTnShcRaMF50MWRFQ=
X-Endpoint-Received: by B4 Relay for shivamklr@cock.li/20260206 with auth_id=628
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a process is deregistered from the binder context, the all_procs
vector may have significant unused capacity. Add logic to shrink the
vector when capacity exceeds 128 and usage drops below 50%, reducing
memory overhead for long-running systems.

The shrink operation uses GFP_KERNEL and is allowed to fail gracefully
since it is purely an optimization. The vector remains valid and
functional even if shrinking fails.

Signed-off-by: Shivam Kalra <shivamklr@cock.li>
---
 drivers/android/binder/context.rs | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/android/binder/context.rs b/drivers/android/binder/context.rs
index 9cf437c025a20..f2505fbf17403 100644
--- a/drivers/android/binder/context.rs
+++ b/drivers/android/binder/context.rs
@@ -94,6 +94,16 @@ pub(crate) fn deregister_process(self: &Arc<Self>, proc: &Arc<Process>) {
         }
         let mut manager = self.manager.lock();
         manager.all_procs.retain(|p| !Arc::ptr_eq(p, proc));
+
+        // Shrink the vector if it has significant unused capacity.
+        // Only shrink if capacity > 128 to avoid repeated reallocations for small vectors.
+        let len = manager.all_procs.len();
+        let cap = manager.all_procs.capacity();
+        if cap > 128 && len < cap / 2 {
+            // Shrink to current length. Ignore allocation failures since this is just an
+            // optimization; the vector remains valid even if shrinking fails.
+            let _ = manager.all_procs.shrink_to(len, GFP_KERNEL);
+        }
     }
 
     pub(crate) fn set_manager_node(&self, node_ref: NodeRef) -> Result {

-- 
2.43.0

