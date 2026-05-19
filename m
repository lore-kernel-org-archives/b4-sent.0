From: Alvin Sun <alvin.sun@linux.dev>
Date: Tue, 19 May 2026 14:26:13 +0800
Subject: [PATCH 1/8] rust: module: add `MODULE_PTR` const to
 `ModuleMetadata` trait
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-fix-fops-owner-v1-1-2ded9830da14@linux.dev>
References: <20260519-fix-fops-owner-v1-0-2ded9830da14@linux.dev>
In-Reply-To: <20260519-fix-fops-owner-v1-0-2ded9830da14@linux.dev>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Luis Chamberlain <mcgrof@kernel.org>, 
 Petr Pavlu <petr.pavlu@suse.com>, Daniel Gomez <da.gomez@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, Aaron Tomlin <atomlin@atomlin.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Arnd Bergmann <arnd@arndb.de>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-modules@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, nova-gpu@lists.linux.dev, 
 Alvin Sun <alvin.sun@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779171975; l=2011;
 i=alvin.sun@linux.dev; s=20260317; h=from:subject:message-id;
 bh=ZxczDP1VleS2E+h97aaS99GWrdXeqA4F9FKMUPVF+a8=;
 b=nZswdxITOGGBNtXxziHC46ym73dmkEpgBRSKXECBrIkKx63Q6fXF2BcQ9Wu99HlqtRv32iuS7
 nenSNwiKIxRDsSSvybK6NrQ/NmLMOgegWv7aRnPdYLyeBWx7+qzexiI
X-Developer-Key: i=alvin.sun@linux.dev; a=ed25519;
 pk=CHcwQp8GSoj25V/L1ZWNSQjWp9eSIb0s9LKr0Nm3WuE=
X-Endpoint-Received: by B4 Relay for alvin.sun@linux.dev/20260317 with auth_id=684
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a `MODULE_PTR` const to the `ModuleMetadata` trait so that
modules can provide a constant pointer to their `struct module`
usable in const contexts such as static file_operations.

Signed-off-by: Alvin Sun <alvin.sun@linux.dev>
---
 rust/kernel/lib.rs    |  3 +++
 rust/macros/module.rs | 14 ++++++++++++++
 2 files changed, 17 insertions(+)

diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index b72b2fbe046d6..c7e809636e1a9 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -184,6 +184,9 @@ fn init(module: &'static ThisModule) -> impl pin_init::PinInit<Self, error::Erro
 pub trait ModuleMetadata {
     /// The name of the module as specified in the `module!` macro.
     const NAME: &'static crate::str::CStr;
+
+    /// The pointer to the kernel `struct module` for this module.
+    const MODULE_PTR: *mut bindings::module;
 }
 
 /// Equivalent to `THIS_MODULE` in the C API.
diff --git a/rust/macros/module.rs b/rust/macros/module.rs
index 06c18e2075083..7204fe604f24a 100644
--- a/rust/macros/module.rs
+++ b/rust/macros/module.rs
@@ -519,6 +519,20 @@ pub(crate) fn module(info: ModuleInfo) -> Result<TokenStream> {
 
         impl ::kernel::ModuleMetadata for #type_ {
             const NAME: &'static ::kernel::str::CStr = #name_cstr;
+
+            #[cfg(MODULE)]
+            const MODULE_PTR: *mut ::kernel::bindings::module = {
+                extern "C" {
+                    static __this_module: ::kernel::types::Opaque<::kernel::bindings::module>;
+                }
+
+                // SAFETY: `__this_module` is constructed by the kernel at load time
+                // and lives until the module is unloaded.
+                unsafe { __this_module.get() }
+            };
+
+            #[cfg(not(MODULE))]
+            const MODULE_PTR: *mut ::kernel::bindings::module = ::core::ptr::null_mut();
         }
 
         // Double nested modules, since then nobody can access the public items inside.

-- 
2.43.0

