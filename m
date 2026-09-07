From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 08 Sep 2026 00:47:49 +0800
Subject: [PATCH v2 2/9] rust: mm: add `task_size` helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-tyr-ioctls-v2-2-88bea777df67@kylinos.cn>
References: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
In-Reply-To: <20260908-tyr-ioctls-v2-0-88bea777df67@kylinos.cn>
To: rust-for-linux@vger.kernel.org
Cc: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Lyude Paul <lyude@redhat.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, dri-devel@lists.freedesktop.org, 
 Ke Sun <sunke@kylinos.cn>, Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788799692; l=951;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=JO+2MVB8/0ZEX96oFL0eP1mAOKrIibNCaD5F9FcB8NY=;
 b=y55dyR98tdQkyQvRS1h0SbEjSI3cnaIDdg85SX7ZIaWbhXm+f+ZDU47osQZU2PcPwf9rjlhF1
 PmbRd8EcCmSC8RgKm7nNWPDYFWRTaPzPs62nL8aNDxU+XaJ2TT4eU/T
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

Expose the task's address space size. It is used by the Tyr driver
for splitting a VM's GPU address space into user and kernel regions.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
Reviewed-by: Daniel Almeida <daniel.almeida@collabora.com>
---
 rust/kernel/mm.rs | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/rust/kernel/mm.rs b/rust/kernel/mm.rs
index 4764d7b68f2a7..d2dfbb7d43972 100644
--- a/rust/kernel/mm.rs
+++ b/rust/kernel/mm.rs
@@ -149,6 +149,13 @@ pub fn mmget_not_zero(&self) -> Option<ARef<MmWithUser>> {
             None
         }
     }
+
+    /// The size of the process virtual address space.
+    #[inline]
+    pub fn task_size(&self) -> usize {
+        // SAFETY: `self.as_raw()` is a valid pointer to an `mm_struct` per the type invariants.
+        unsafe { (*self.as_raw()).__bindgen_anon_1.task_size }
+    }
 }
 
 // These methods require `mm_users` to be non-zero.

-- 
2.43.0

