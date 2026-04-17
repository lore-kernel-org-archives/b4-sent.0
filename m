From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 17 Apr 2026 09:05:54 +0800
Subject: [PATCH 4/4] rust: xarray: Add Guard::find() helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-tyr-ioctls-deps-v1-4-41c6e9bb061c@linux.dev>
References: <20260417-tyr-ioctls-deps-v1-0-41c6e9bb061c@linux.dev>
In-Reply-To: <20260417-tyr-ioctls-deps-v1-0-41c6e9bb061c@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Tamir Duberstein <tamird@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776388289; l=1408;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=HK2c+z8dRuFsYNATe7JRBa5cKQyu3FlazejUuvyOuq8=;
 b=c/lPoOZ1Arte0C/QoYrkBDlhgjCZ5b99pHUmEM6OFrj/WdCEt52K0YfvGN8Z06RSSMFQgpDdo
 JBKPQrDSNehAxdqNGVcwXaYyiVDut1xvEu8f1PV1IxWItviywlhjFt6
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a helper to find the first present entry in the XArray.

Returns the index of the first present entry, or None if the array
is empty.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/xarray.rs | 22 ++++++++++++++++++++++
 1 file changed, 22 insertions(+)

diff --git a/rust/kernel/xarray.rs b/rust/kernel/xarray.rs
index 235fda0e394ba..e43129d032d9d 100644
--- a/rust/kernel/xarray.rs
+++ b/rust/kernel/xarray.rs
@@ -217,6 +217,28 @@ pub fn remove(&mut self, index: usize) -> Option<T> {
         unsafe { T::try_from_foreign(ptr) }
     }
 
+    /// Finds the first present entry.
+    ///
+    /// Returns the index of the first present entry, or `None` if the array is empty.
+    pub fn find(&mut self) -> Option<usize> {
+        let mut index = 0usize;
+        // SAFETY: `self.xa.xa` is always valid by the type invariant, and we hold the lock.
+        let ptr = unsafe {
+            bindings::xa_find(
+                self.xa.xa.get(),
+                &mut index,
+                usize::MAX,
+                bindings::XA_PRESENT,
+            )
+        };
+
+        if ptr.is_null() {
+            None
+        } else {
+            Some(index)
+        }
+    }
+
     /// Stores an element at the given index.
     ///
     /// May drop the lock if needed to allocate memory, and then reacquire it afterwards.

-- 
2.43.0

