From: Ke Sun <sunke@kylinos.cn>
Date: Tue, 08 Sep 2026 00:47:54 +0800
Subject: [PATCH v2 7/9] drm/tyr: refactor new_dummy_object to use
 new_object
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260908-tyr-ioctls-v2-7-88bea777df67@kylinos.cn>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788799692; l=1566;
 i=sunke@kylinos.cn; s=20260317; h=from:subject:message-id;
 bh=evnUd0qm9ZwiYuhFDEcZYkjsD1f1+LG9OpRwEzX78ag=;
 b=DG8IaoiUFgNeMQe7P8OtUnLRSOFxuZi3gspovlvUFIJefp+Si1hZwHIZBN0xcP6q2w1y7skod
 SU6JBf12LKxAx8UhwZQ7btB/EOoS7CSkSoQ2zk9aUU0lIOE7Va2JyiU
X-Developer-Key: i=sunke@kylinos.cn; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for sunke@kylinos.cn/20260317 with auth_id=950
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alvin Sun <alvin.sun@linux.dev>

new_dummy_object() duplicated the BO creation code that new_object()
now provides; call new_object() instead.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
Reviewed-by: Daniel Almeida <daniel.almeida@collabora.com>
---
 drivers/gpu/drm/tyr/gem.rs | 14 ++------------
 1 file changed, 2 insertions(+), 12 deletions(-)

diff --git a/drivers/gpu/drm/tyr/gem.rs b/drivers/gpu/drm/tyr/gem.rs
index 0e0989a48678f..2523d05de5527 100644
--- a/drivers/gpu/drm/tyr/gem.rs
+++ b/drivers/gpu/drm/tyr/gem.rs
@@ -57,7 +57,6 @@ fn new(_dev: &TyrDrmDevice, _size: usize, args: BoCreateArgs) -> impl PinInit<Se
 pub(crate) type Bo = gem::shmem::Object<BoData>;
 
 /// Create a new GEM buffer object.
-#[expect(dead_code)]
 pub(crate) fn new_object(ddev: &TyrDrmDevice, size: usize, flags: u32) -> Result<ARef<Bo>> {
     if size == 0 {
         return Err(EINVAL);
@@ -84,17 +83,8 @@ pub(crate) fn lookup_handle(file: &TyrDrmFile, handle: u32) -> Result<ARef<Bo>>
 
 /// Creates a dummy GEM object to serve as the root of a GPUVM.
 pub(crate) fn new_dummy_object(ddev: &TyrDrmDevice) -> Result<ARef<Bo>> {
-    let bo = Bo::new(
-        ddev,
-        4096,
-        shmem::ObjectConfig {
-            map_wc: true,
-            parent_resv_obj: None,
-        },
-        BoCreateArgs { flags: 0 },
-    )?;
-
-    Ok(bo)
+    // FIXME: use a Rust resv-object abstraction once available, rather than a real BO.
+    new_object(ddev, PAGE_SIZE, 0)
 }
 
 /// Specifies how to choose a GPU virtual address for a [`KernelBo`].

-- 
2.43.0

