From: Peder Bergan <peder.bergan@gmail.com>
Date: Tue, 03 Nov 2026 12:50:54 +0100
Subject: [PATCH v3] rust: alloc: test drop behavior of Vec::drain_all
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-test-drain-all-drop-v3-1-5f936d67b099@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJ3K6WoC/12PTW+DMAyG/0rFeZkIHSDtNOjopnYthe6wD1VTS
 F2S8RGW0AKq+O9L2G0Xy+9r+7F9tRRIDsq6n10tCReuuKi1mN/MLMpInQPiR60tx3Y8jO05akG
 16CgJrxEpS52JBgHGbnaXYYJd29KTjYQT7yfq5+FPq3P2DbQ1KNOREQUok6SmzFiaJCiqoW9N8
 SRFhVomgUyrF8GW//hOvV2+rNnQicddWhWw2ncFS4IF+YDQ2XNRiO41jjziyTjsHirCy9t8ilR
 UBsq4aoUcpkcvjrlMg9fPHUPRV+CHDRY7d/de5JHnMGbT1SZJz3288Ya3p6UfhzhJ7ZAl/8GHc
 Rx/AStyP+VEAQAA
X-Change-ID: 20261103-test-drain-all-drop-e115b4b1a150
To: dakr@kernel.org, aliceryhl@google.com
Cc: ljs@kernel.org, vbabka@kernel.org, liam@infradead.org, urezki@gmail.com, 
 ojeda@kernel.org, boqun@kernel.org, gary@garyguo.net, 
 bjorn3_gh@protonmail.com, lossin@kernel.org, a.hindborg@kernel.org, 
 tmgross@umich.edu, daniel.almeida@collabora.com, tamird@kernel.org, 
 acourbot@nvidia.com, work@onurozkan.dev, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Miguel Ojeda <ojeda@kernel.org>, 
 Peder Bergan <peder.bergan@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793706653; l=5159;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=wr/rttULwHjMnmBYWzKteJlebu8bZItM0swWuvHRT9c=;
 b=5p3SMMkQOKo0XCI42eM0AUc1B3PVKIfyk2qbx17Q94TNLlbypZ8ylbFv9THdeHN9xFxxDavTZ
 +2knCtYHWwgAfnROMLyd8bXqluwloB+z4+TcIoTpnILDRDu41gQnFO6
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The drain_all example consumes the entire iterator and uses integers, so
it cannot detect missing drops of unconsumed values or premature drops
of values yielded to the caller.

Add KUnit tests with per-element drop counters for partially consumed,
unconsumed and exhausted drains, plus an empty-vector case. Keep a
yielded value alive after both the drain and vector are dropped to check
that its ownership stays with the caller. Also check that draining
empties the vector without changing its capacity.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
v3:
- Remove the repeated commit summary from the submission notes.
- Keep the base in git format-patch's machine-readable base-commit footer.
- Restore the original comment instead of changing it for mail transport.
- Send with b4 through the kernel.org web endpoint.

v2:
- Split a long test comment to avoid mail transport line wrapping.

Based on alloc-next. The original v1 test source is restored exactly.

Previous revision:
https://lore.kernel.org/rust-for-linux/CAKHwh-E_A7Bp1oP5PYkgE62hh0cJMQRuxOM6yXGF7OB1QR0BhQ@mail.gmail.com/

Validation on x86_64 under QEMU:

- The original rust_kvec suite passed before the change.
- All nine tests passed with the change, including a CLIPPY=1 build.
- Making DrainAll::drop temporarily empty caused exactly the partial and
  unconsumed tests to fail. Restoring it returned the suite to passing.

The tests used Rust 1.99.1, LLVM 23.1.4, bindgen 0.73.2 and QEMU 11.1.3.
The minimal configuration has an existing unused-function warning in
io/resource.rs, also seen before this change.

OpenAI Codex assisted with coding and testing this issue.
The requested work was to test Vec::drain_all ownership and destruction,
validate the tests under QEMU, and prove that they detect skipped
destruction.
---
 rust/kernel/alloc/kvec.rs | 88 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 88 insertions(+)

diff --git a/rust/kernel/alloc/kvec.rs b/rust/kernel/alloc/kvec.rs
index c7546b9da..fe113c7ff 100644
--- a/rust/kernel/alloc/kvec.rs
+++ b/rust/kernel/alloc/kvec.rs
@@ -1540,6 +1540,94 @@ fn drop(&mut self) {
 mod tests {
     use super::*;
     use crate::prelude::*;
+    use core::cell::Cell;
+
+    struct DropSpy<'a>(&'a Cell<usize>);
+
+    impl Drop for DropSpy<'_> {
+        fn drop(&mut self) {
+            self.0.set(self.0.get() + 1);
+        }
+    }
+
+    #[test]
+    fn test_kvec_drain_all_partial() -> Result {
+        let drops = [const { Cell::new(0) }; 3];
+        let mut v = KVec::new();
+        for counter in &drops {
+            v.push(DropSpy(counter), GFP_KERNEL)?;
+        }
+        let capacity = v.capacity();
+
+        let mut drain = v.drain_all();
+        let first = drain.next().ok_or(EINVAL)?;
+        drop(drain);
+
+        // The caller owns the yielded value, while the drain drops the remaining values.
+        assert_eq!(drops.each_ref().map(Cell::get), [0, 1, 1]);
+        assert!(v.is_empty());
+        assert_eq!(v.capacity(), capacity);
+
+        drop(v);
+        assert_eq!(drops.each_ref().map(Cell::get), [0, 1, 1]);
+
+        drop(first);
+        assert_eq!(drops.each_ref().map(Cell::get), [1, 1, 1]);
+        Ok(())
+    }
+
+    #[test]
+    fn test_kvec_drain_all_unconsumed() -> Result {
+        let drops = [const { Cell::new(0) }; 3];
+        let mut v = KVec::new();
+        for counter in &drops {
+            v.push(DropSpy(counter), GFP_KERNEL)?;
+        }
+        let capacity = v.capacity();
+
+        drop(v.drain_all());
+        assert_eq!(drops.each_ref().map(Cell::get), [1, 1, 1]);
+        assert!(v.is_empty());
+        assert_eq!(v.capacity(), capacity);
+
+        drop(v);
+        assert_eq!(drops.each_ref().map(Cell::get), [1, 1, 1]);
+        Ok(())
+    }
+
+    #[test]
+    fn test_kvec_drain_all_consumed() -> Result {
+        let drops = [const { Cell::new(0) }; 3];
+        let mut v = KVec::new();
+        for counter in &drops {
+            v.push(DropSpy(counter), GFP_KERNEL)?;
+        }
+        let capacity = v.capacity();
+
+        let mut drain = v.drain_all();
+        for value in drain.by_ref() {
+            drop(value);
+        }
+        assert_eq!(drops.each_ref().map(Cell::get), [1, 1, 1]);
+        drop(drain);
+        assert!(v.is_empty());
+        assert_eq!(v.capacity(), capacity);
+
+        drop(v);
+        assert_eq!(drops.each_ref().map(Cell::get), [1, 1, 1]);
+        Ok(())
+    }
+
+    #[test]
+    fn test_kvec_drain_all_empty() {
+        let mut v = KVec::<DropSpy<'_>>::new();
+        let capacity = v.capacity();
+        let mut drain = v.drain_all();
+        assert!(drain.next().is_none());
+        drop(drain);
+        assert!(v.is_empty());
+        assert_eq!(v.capacity(), capacity);
+    }
 
     #[test]
     fn test_kvec_retain() {

---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261103-test-drain-all-drop-e115b4b1a150

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

