From: Alvin Sun <alvin.sun@linux.dev>
Date: Thu, 26 Mar 2026 14:53:03 +0800
Subject: [PATCH 10/13] drm/tyr: expose Vm gpuvm_core, gpuvm and va_range as
 pub(crate)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260326-b4-tyr-debugfs-v1-10-074badd18716@linux.dev>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774508149; l=1015;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=l+K9zW15YdA7Rr803fNe8iacgAff7Ccyrsy1728ZtCA=;
 b=Z2102NPJrLYhjTFTHtNjxbwByB2im8luathC5tg30XFDs7fqzPxHYQxaYNfs9Gnk4ze5VU0OU
 m7Np+bRkkAnAIFgr0///hHaP/vbwssLEI4Z2Gx0ewURZ8c5KWShSpXS
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow the debugfs module to read VM and GPU VA state for the gpuvas file.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 drivers/gpu/drm/tyr/vm.rs | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/gpu/drm/tyr/vm.rs b/drivers/gpu/drm/tyr/vm.rs
index 936c3049812b3..ccf4493065a49 100644
--- a/drivers/gpu/drm/tyr/vm.rs
+++ b/drivers/gpu/drm/tyr/vm.rs
@@ -306,12 +306,12 @@ pub(crate) struct Vm {
     pdev: ARef<platform::Device>,
     /// DRM GPUVM core for managing virtual address space.
     #[pin]
-    gpuvm_core: Mutex<GpuVmCore<GpuVmData>>,
+    pub(crate) gpuvm_core: Mutex<GpuVmCore<GpuVmData>>,
     /// Non-core part of the GPUVM. Can be used for stuff that doesn't modify the
     /// internal mapping tree, like GpuVm::obtain()
-    gpuvm: ARef<GpuVm<GpuVmData>>,
+    pub(crate) gpuvm: ARef<GpuVm<GpuVmData>>,
     /// VA range for this VM.
-    va_range: Range<u64>,
+    pub(crate) va_range: Range<u64>,
 }
 
 impl Vm {

-- 
2.43.0

