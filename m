From: Alvin Sun <alvin.sun@linux.dev>
Date: Fri, 17 Apr 2026 09:05:52 +0800
Subject: [PATCH 2/4] rust: mm: Add task_size() method to Mm
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260417-tyr-ioctls-deps-v1-2-41c6e9bb061c@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776388289; l=925;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=CEPawZ6sXIb2An8dSVvX8IrZi7UWboan6QZmQB4W5f4=;
 b=VhjBHoX9OG7AUX3/fgimlEwaBbhq84mQoNYpuucixnpKEzSkynw1I1YDpONyPwQb2ZxJnYiAx
 xdMwdIPQVOAAqa+DYmSyPAqlc34aXR+M1gMH67k4J5g01IGqgvkMwfx
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a task_size() method to the Mm struct to expose the process
virtual address space size. This is used by the Tyr driver's VmLayout
to determine the user VA range when VmUserSize::Auto is specified.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/mm.rs | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/rust/kernel/mm.rs b/rust/kernel/mm.rs
index 4764d7b68f2a7..c6ba4da52688b 100644
--- a/rust/kernel/mm.rs
+++ b/rust/kernel/mm.rs
@@ -149,6 +149,13 @@ pub fn mmget_not_zero(&self) -> Option<ARef<MmWithUser>> {
             None
         }
     }
+
+    /// Returns task size for this mm_struct.
+    #[inline]
+    pub fn task_size(&self) -> u64 {
+        // SAFETY: self.as_raw() is a valid pointer to an mm_struct.
+        unsafe { (*self.as_raw()).__bindgen_anon_1.task_size as u64 }
+    }
 }
 
 // These methods require `mm_users` to be non-zero.

-- 
2.43.0

