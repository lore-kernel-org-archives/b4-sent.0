From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Sun, 15 Feb 2026 02:05:23 +0530
Subject: [PATCH v5 3/3] rust_binder: shrink all_procs when deregistering
 processes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260215-binder-shrink-vec-v3-v5-3-6e5e56d69766@zohomail.in>
References: <20260215-binder-shrink-vec-v3-v5-0-6e5e56d69766@zohomail.in>
In-Reply-To: <20260215-binder-shrink-vec-v3-v5-0-6e5e56d69766@zohomail.in>
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
 Shivam Kalra <shivamkalra98@zohomail.in>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771101329; l=2050;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=7FV6uKzz4TJqB7MKxHeO755/zc8FAEv6EPYTU8loKcE=;
 b=4//76mOxNdGg1G1UwGPMDljOwlmA6xOOV7+xCKJGo6mFMRYT7XcNYU5aCd8YSQWi8P83nsliy
 xNL9aU4Df7KA4ngR+N2CbkeGPBnxfM4uoTqtxSKoC+uYxqXdVQDfEOi
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a process is deregistered from the binder context, the all_procs
vector may have significant unused capacity. Add logic to shrink the
vector using a conservative strategy that prevents shrink-then-regrow
oscillation.

The shrinking strategy triggers when length drops below 1/4 of capacity,
and shrinks to twice the current length rather than to the exact length.
This provides hysteresis to avoid repeated reallocations when the process
count fluctuates.

The shrink operation uses GFP_KERNEL and is allowed to fail gracefully
since it is purely an optimization. The vector remains valid and
functional even if shrinking fails.

Suggested-by: Alice Ryhl <aliceryhl@google.com>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 drivers/android/binder/context.rs | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/drivers/android/binder/context.rs b/drivers/android/binder/context.rs
index 9cf437c025a20..ddddb66b35571 100644
--- a/drivers/android/binder/context.rs
+++ b/drivers/android/binder/context.rs
@@ -94,6 +94,17 @@ pub(crate) fn deregister_process(self: &Arc<Self>, proc: &Arc<Process>) {
         }
         let mut manager = self.manager.lock();
         manager.all_procs.retain(|p| !Arc::ptr_eq(p, proc));
+
+        // Shrink the vector if it has significant unused capacity to avoid memory waste,
+        // but use a conservative strategy to prevent shrink-then-regrow oscillation.
+        // Only shrink when length drops below 1/4 of capacity, and shrink to twice the length.
+        let len = manager.all_procs.len();
+        let cap = manager.all_procs.capacity();
+        if len < cap / 4 {
+            // Shrink to twice the current length. Ignore allocation failures since this
+            // is just an optimization; the vector remains valid even if shrinking fails.
+            let _ = manager.all_procs.shrink_to(len * 2, GFP_KERNEL);
+        }
     }
 
     pub(crate) fn set_manager_node(&self, node_ref: NodeRef) -> Result {

-- 
2.43.0

