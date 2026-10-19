From: Sami Tolvanen <samitolvanen@google.com>
Date: Mon, 19 Oct 2026 20:21:52 +0000
Subject: [PATCH] rust: drm: gem: shmem: do not leak pages when sg_table()
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261019-rust-shmem-fixes-v1-1-3f7f6de5b5e7@google.com>
X-B4-Tracking: v=1; b=H4sIAN971moC/x3LQQqAIBBA0avIrBtIhdCuEi2sxpqFFU5FEN09a
 fn4/AeEMpNAqx7IdLHwthboSsG4hHUm5KkYTG0aXWuP+ZQDZUmUMPJNgjY468IUrB8ilG3P9Id
 ydf37fiLu4TtiAAAA
X-Change-ID: 20261019-rust-shmem-fixes-3a838ada39bf
To: David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Danilo Krummrich <dakr@kernel.org>, Alice Ryhl <aliceryhl@google.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Trevor Gross <tmgross@umich.edu>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Lyude Paul <lyude@redhat.com>
Cc: dri-devel@lists.freedesktop.org, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Sami Tolvanen <samitolvanen@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2150;
 i=samitolvanen@google.com; h=from:subject:message-id;
 bh=Zr7vQwXA9E8hmZ2MFtEBon9gBEwSUz6LGsU4RyoehDI=;
 b=owGbwMvMwCUWxa662nLh8irG02pJDFnXqh/66sV7me2K21Ap8fxBQcQl3qbl+9uSjvM/+BAUo
 vkqQ1Wwo5SFQYyLQVZMkaXl6+qtu787pb76XCQBM4eVCWQIAxenAEzEbg/DP9XdK03VPWOeTj1v
 FhWx5Xi0cA6vbYffi6OiRxVuSh4tnszw3/F8r8CvXVpTOrNWyzqsZryX+ldn7p3uLWLK2Rd/HSx
 O5QcA
X-Developer-Key: i=samitolvanen@google.com; a=openpgp;
 fpr=35CCFB63B283D6D3AEB783944CB5F6848BBC56EE
X-Endpoint-Received: by B4 Relay for samitolvanen@google.com/default with auth_id=1242
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`SGTableMap::new()` takes a pages reference and maps the table before
`Devres::new()` allocates. If the allocation fails, dropping the map
frees the table but keeps the reference, and the next `sg_table()`
takes another one. `drm_gem_shmem_release()` puts only one, so the
pages leak.

Take the pages in the initializer, after the allocation.

Fixes: 616c229ab010 ("rust: drm: gem: Introduce shmem::Object::sg_table()")
Signed-off-by: Sami Tolvanen <samitolvanen@google.com>
---
 rust/kernel/drm/gem/shmem.rs | 21 ++++++++++++---------
 1 file changed, 12 insertions(+), 9 deletions(-)

diff --git a/rust/kernel/drm/gem/shmem.rs b/rust/kernel/drm/gem/shmem.rs
index a687d46d170d..72e4af3b0503 100644
--- a/rust/kernel/drm/gem/shmem.rs
+++ b/rust/kernel/drm/gem/shmem.rs
@@ -555,15 +555,18 @@ fn drop(&mut self) {
 }
 
 impl<T: DriverObject> SGTableMap<T> {
-    fn new(obj: &Object<T>) -> impl Init<Self, Error> {
-        // INVARIANT:
-        // - We call drm_gem_shmem_get_pages_sgt below and check whether or not it succeeds,
-        //   fulfilling the invariant of SGTableMap that the object's `sgt` field is initialized.
-        // SAFETY:
-        // - `obj` is fully initialized, making this function safe to call.
-        from_err_ptr(unsafe { bindings::drm_gem_shmem_get_pages_sgt(obj.as_raw_shmem()) })?;
-
-        Ok(Self { obj: obj.into() })
+    fn new(obj: &Object<T>) -> impl Init<Self, Error> + '_ {
+        pin_init::init_scope(move || {
+            // SAFETY:
+            // - `obj` is fully initialized, making this function safe to call.
+            from_err_ptr(unsafe { bindings::drm_gem_shmem_get_pages_sgt(obj.as_raw_shmem()) })?;
+
+            // INVARIANT:
+            // - We call drm_gem_shmem_get_pages_sgt above and check whether or not it succeeds,
+            //   fulfilling the invariant of SGTableMap that the object's `sgt` field is
+            //   initialized.
+            Ok(try_init!(Self { obj: obj.into() }))
+        })
     }
 }
 

---
base-commit: c03c1a14507dfaf8b856c2608f9ac216021fc222
change-id: 20261019-rust-shmem-fixes-3a838ada39bf

