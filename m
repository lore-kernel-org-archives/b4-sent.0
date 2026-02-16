From: Shivam Kalra <shivamkalra98@zohomail.in>
Date: Mon, 16 Feb 2026 19:39:56 +0530
Subject: [PATCH v6 2/3] rust: alloc: add KUnit tests for KVVec shrink_to
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260216-binder-shrink-vec-v3-v6-2-ece8e8593e53@zohomail.in>
References: <20260216-binder-shrink-vec-v3-v6-0-ece8e8593e53@zohomail.in>
In-Reply-To: <20260216-binder-shrink-vec-v3-v6-0-ece8e8593e53@zohomail.in>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771251023; l=4392;
 i=shivamkalra98@zohomail.in; s=20260212; h=from:subject:message-id;
 bh=2yjjFzKFJiIABUmHBwniBs7X17u+zlrGDX69Rd2mee4=;
 b=4B/+UE094N6Ev8RZfcW5pUCLgo9qywLj+dRf1EV0eLBXb14bdk7WE6MCepfDBCO24f40jSGVn
 M1Z0OF06Rb1AIZWwypz+s7o8+9GO9Dw3V914lMW83QPt9XXSl4+a/QE
X-Developer-Key: i=shivamkalra98@zohomail.in; a=ed25519;
 pk=9Q+S1LD/xjbjL7bEaLIlwRADBwU/6LJq7lYm8LFrkQE=
X-Endpoint-Received: by B4 Relay for shivamkalra98@zohomail.in/20260212 with auth_id=633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add comprehensive KUnit tests for the shrink_to method for KVVec.
The tests verify:
- Basic shrinking from multiple pages to fewer pages with data integrity
  preservation
- Empty vector shrinking to zero capacity
- No-op behavior when shrinking to a larger capacity than current
- Respect for min_capacity parameter when larger than vector length
These tests ensure that the shrinking logic correctly identifies when
memory can be reclaimed (by freeing at least one page) and that data
integrity is maintained throughout shrink operations.

Reviewed-by: Alice Ryhl <aliceryhl@google.com>
Acked-by: Danilo Krummrich <dakr@kernel.org>
Signed-off-by: Shivam Kalra <shivamkalra98@zohomail.in>
---
 rust/kernel/alloc/kvec.rs | 102 ++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 102 insertions(+)

diff --git a/rust/kernel/alloc/kvec.rs b/rust/kernel/alloc/kvec.rs
index e7bc439538e4..6438385e4322 100644
--- a/rust/kernel/alloc/kvec.rs
+++ b/rust/kernel/alloc/kvec.rs
@@ -1510,4 +1510,106 @@ fn add(value: &mut [bool]) {
             func.push_within_capacity(false).unwrap();
         }
     }
+
+    #[test]
+    fn test_kvvec_shrink_to() {
+        use crate::page::PAGE_SIZE;
+
+        // Create a vector with capacity spanning multiple pages.
+        let mut v = KVVec::<u8>::with_capacity(PAGE_SIZE * 4, GFP_KERNEL).unwrap();
+
+        // Add a few elements.
+        v.push(1, GFP_KERNEL).unwrap();
+        v.push(2, GFP_KERNEL).unwrap();
+        v.push(3, GFP_KERNEL).unwrap();
+
+        let initial_capacity = v.capacity();
+        assert!(initial_capacity >= PAGE_SIZE * 4);
+
+        // Shrink to a capacity that would free at least one page.
+        v.shrink_to(PAGE_SIZE, GFP_KERNEL).unwrap();
+
+        // Capacity should have been reduced.
+        assert!(v.capacity() < initial_capacity);
+        assert!(v.capacity() >= PAGE_SIZE);
+
+        // Elements should be preserved.
+        assert_eq!(v.len(), 3);
+        assert_eq!(v[0], 1);
+        assert_eq!(v[1], 2);
+        assert_eq!(v[2], 3);
+
+        // Shrink to zero (should shrink to len).
+        v.shrink_to(0, GFP_KERNEL).unwrap();
+
+        // Capacity should be at least the length.
+        assert!(v.capacity() >= v.len());
+
+        // Elements should still be preserved.
+        assert_eq!(v.len(), 3);
+        assert_eq!(v[0], 1);
+        assert_eq!(v[1], 2);
+        assert_eq!(v[2], 3);
+    }
+
+    #[test]
+    fn test_kvvec_shrink_to_empty() {
+        use crate::page::PAGE_SIZE;
+
+        // Create a vector with large capacity but no elements.
+        let mut v = KVVec::<u8>::with_capacity(PAGE_SIZE * 4, GFP_KERNEL).unwrap();
+
+        assert!(v.is_empty());
+
+        // Shrink empty vector to zero.
+        v.shrink_to(0, GFP_KERNEL).unwrap();
+
+        // Should have freed the allocation.
+        assert_eq!(v.capacity(), 0);
+        assert!(v.is_empty());
+    }
+
+    #[test]
+    fn test_kvvec_shrink_to_no_op() {
+        use crate::page::PAGE_SIZE;
+
+        // Create a small vector.
+        let mut v = KVVec::<u8>::with_capacity(PAGE_SIZE, GFP_KERNEL).unwrap();
+        v.push(1, GFP_KERNEL).unwrap();
+
+        let capacity_before = v.capacity();
+
+        // Try to shrink to a capacity larger than current - should be no-op.
+        v.shrink_to(capacity_before + 100, GFP_KERNEL).unwrap();
+
+        assert_eq!(v.capacity(), capacity_before);
+        assert_eq!(v.len(), 1);
+        assert_eq!(v[0], 1);
+    }
+
+    #[test]
+    fn test_kvvec_shrink_to_respects_min_capacity() {
+        use crate::page::PAGE_SIZE;
+
+        // Create a vector with large capacity.
+        let mut v = KVVec::<u8>::with_capacity(PAGE_SIZE * 4, GFP_KERNEL).unwrap();
+
+        // Add some elements.
+        for i in 0..10u8 {
+            v.push(i, GFP_KERNEL).unwrap();
+        }
+
+        // Shrink to a min_capacity larger than length.
+        let min_cap = PAGE_SIZE * 2;
+        v.shrink_to(min_cap, GFP_KERNEL).unwrap();
+
+        // Capacity should be at least min_capacity.
+        assert!(v.capacity() >= min_cap);
+
+        // All elements preserved.
+        assert_eq!(v.len(), 10);
+        for i in 0..10u8 {
+            assert_eq!(v[i as usize], i);
+        }
+    }
 }

-- 
2.43.0

