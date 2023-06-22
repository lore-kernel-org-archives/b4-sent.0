From: =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>
Date: Thu, 22 Jun 2023 21:24:40 +0200
Subject: [PATCH] rust: alloc: Add realloc and alloc_zeroed to the
 GlobalAlloc impl
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20230622-global_alloc_methods-v1-1-3d3561593e23@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAPeflGQC/x2N0QqDMAwAf0XyvICrOMZ+ZQxJ2mgLXTuaOgTx3
 1f3eBzH7aBSgig8uh2KfIOGnBpcLx1YT2kRDK4xmN4M/c0YXGJmihPFmO30luqzUySeRx5luDs
 maCmTCnKhZP0Zl1UrJtnq6T5F5rD9l8/XcfwAwBIEP4IAAAA=
To: Miguel Ojeda <ojeda@kernel.org>, Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 Benno Lossin <benno.lossin@proton.me>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1687461921; l=1764;
 i=bjorn3_gh@protonmail.com; s=20230622; h=from:subject:message-id;
 bh=M9xHvSYYCEDVh9+hr5YwUYJxj2f5jgjrI/bZdGQDX+8=;
 b=Uc+YPwcRyWhLPWVXHVbl9sDKW/vsIauXT/uasYNYN/UJvZyOEGqrkYHZeuUTIFQQr3HioDaU7
 z60y8bv6qypAXeUx+ukjus+tQp2WW0xph9OU58grNqnqpQtUCukuqDY
X-Developer-Key: i=bjorn3_gh@protonmail.com; a=ed25519;
 pk=tXjaafs1PnnuO6sr/Z6Wl6BuT7c22k9Rf9fpX863CJs=
X-Endpoint-Received: by B4 Relay for bjorn3_gh@protonmail.com/20230622 with auth_id=55
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While there are default impls for these methods, using the respective C
api's is faster. Currently neither the existing nor these new
GlobalAlloc method implementations are actually called. Instead the
__rust_* function defined below the GlobalAlloc impl are used. With
rustc 1.71 these functions will be gone and all allocation calls will go
through the GlobalAlloc implementation.

Link: https://github.com/Rust-for-Linux/linux/issues/68
Signed-off-by: Björn Roy Baron <bjorn3_gh@protonmail.com>
---
 rust/kernel/allocator.rs | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/rust/kernel/allocator.rs b/rust/kernel/allocator.rs
index 397a3dd57a9b..e0a27b1326b5 100644
--- a/rust/kernel/allocator.rs
+++ b/rust/kernel/allocator.rs
@@ -21,6 +21,26 @@ unsafe fn dealloc(&self, ptr: *mut u8, _layout: Layout) {
             bindings::kfree(ptr as *const core::ffi::c_void);
         }
     }
+
+    unsafe fn realloc(&self, ptr: *mut u8, _layout: Layout, new_size: usize) -> *mut u8 {
+        unsafe {
+            bindings::krealloc(
+                ptr as *const core::ffi::c_void,
+                new_size,
+                bindings::GFP_KERNEL,
+            ) as *mut u8
+        }
+    }
+
+    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
+        unsafe {
+            bindings::krealloc(
+                core::ptr::null(),
+                layout.size(),
+                bindings::GFP_KERNEL | bindings::__GFP_ZERO,
+            ) as *mut u8
+        }
+    }
 }
 
 #[global_allocator]

---
base-commit: d2e3115d717197cb2bc020dd1f06b06538474ac3
change-id: 20230622-global_alloc_methods-abf5b5e38dba

Best regards,
-- 
Björn Roy Baron <bjorn3_gh@protonmail.com>

