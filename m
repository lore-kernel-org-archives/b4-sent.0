From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:53:00 +0800
Subject: [PATCH 07/13] rust: drm: add Device::primary_index()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-7-074badd18716@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=1091;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=DA84Ymbf079qCjCVvVAH/KpIbPA3jpISHviOPMVP3qo=;
 b=G376wniR4/sgouAGFGuqpemjkx7s04qm0u0u+1vYHG+/xqPwdUKq00ukzZnB5dEGw4UkQJZGf
 g2zURToulH8BusETt7LXl3Ivbf1R1oqJf4cTcIk1q+WcExHgwBW4+j/
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add primary_index() to return the primary minor index (e.g. the N in
/dev/dri/cardN). Needed by drivers to register per-device debugfs under
a unique directory name.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/drm/device.rs | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/rust/kernel/drm/device.rs b/rust/kernel/drm/device.rs
index d7bb338efb9d8..268ac02e800fd 100644
--- a/rust/kernel/drm/device.rs
+++ b/rust/kernel/drm/device.rs
@@ -336,6 +336,16 @@ pub(crate) unsafe fn assume_ctx<NewCtx: DeviceContext>(&self) -> &Device<T, NewC
     }
 }
 
+impl<T: drm::Driver> Device<T, Registered> {
+    /// Returns the primary minor index (the number in `/dev/dri/cardN`).
+    #[inline]
+    pub fn primary_index(&self) -> u32 {
+        // SAFETY: `self.as_raw()` is guaranteed to be a valid pointer to a `struct drm_device`.
+        let index = unsafe { (*(*self.as_raw()).primary).index };
+        index as u32
+    }
+}
+
 impl<T: drm::Driver> Deref for Device<T, Registered> {
     type Target = T::Data;
 

-- 
2.43.0

