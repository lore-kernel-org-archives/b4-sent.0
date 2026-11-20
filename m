From: Peder Bergan <peder.bergan@gmail.com>
Date: Fri, 20 Nov 2026 17:32:12 +0100
Subject: [PATCH] rust: put C helper exports in a dedicated namespace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-rust-helper-namespace-v1-1-3b9a05553ff6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAt2AGsC/yWM0Q6CMBAEf4Xcs420RjH+ivHhKIvUSG3uiiEh/
 LsUH2ezMwspJEDpVi0k+AYNn7iBPVTkB45PmNBtTK52F2tdbWTSbAa8E8REHqGJPcy5wdWfGqD
 petrcJOjDvHfvjz/r1L7gc4mVR8sK0wpHP5RpSpoFPB73fsScaV1/Kuql2p4AAAA=
X-Change-ID: 20261120-rust-helper-namespace-57e8c37ee7df
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Boqun Feng <boqun@kernel.org>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Daniel Gomez <da.gomez@kernel.org>, Sami Tolvanen <samitolvanen@google.com>, 
 Aaron Tomlin <atomlin@atomlin.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-modules@vger.kernel.org, 
 Wedson Almeida Filho <wedsonaf@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795192339; l=3698;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=5abfNuTCOBRWevTCg/nJxA+AusAhHZG6K5llcZxRyjI=;
 b=kHhyiIoVhUVvEZ39eIExpOF7QUtA1sz03mr1zCe+6+mUbacftH2am3hofEnCEBIkZ6Y7elFJw
 1dEuwYZ8hHfADPm4c37j0mG/eJgltFQ5TJZ0LLUmtyK2jVAim1/mjBu
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rust_helper_ prefix marks these C wrappers as Rust implementation
details. Their exports use the default namespace, so GPL-compatible
modules can link against them without an explicit import.

Export the wrappers in RUST_HELPERS so modpost can detect accidental
dependencies at build time by flagging a missing namespace import.
Have module! supply the import when the helpers are exported, since
inlining and generic instantiation can introduce calls through ordinary
Rust abstractions.

External modules that call these helpers without module! need to
declare the import explicitly.

Suggested-by: Wedson Almeida Filho <wedsonaf@gmail.com>
Link: https://github.com/Rust-for-Linux/linux/issues/216
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
The two Rust sample modules loaded and unloaded under x86-64 QEMU
with namespace enforcement enabled. Removing the import made modpost
reject the sample. The exports and imports were also checked with helper
inlining enabled and disabled.

OpenAI Codex assisted with coding and testing.
---
 rust/Makefile         | 4 +++-
 rust/exports.c        | 2 ++
 rust/macros/module.rs | 5 +++++
 3 files changed, 10 insertions(+), 1 deletion(-)

diff --git a/rust/Makefile b/rust/Makefile
index 0165626decbe7..17c559052e936 100644
--- a/rust/Makefile
+++ b/rust/Makefile
@@ -569,9 +569,10 @@ $(obj)/helpers/helpers.bc $(obj)/helpers/helpers_module.bc: $(src)/helpers/helpe
 
 rust_exports = $(NM) -p --defined-only $(1) | awk '$$2~/(T|R|D|B)/ && $$3!~/__(pfx|cfi|odr_asan)/ { printf $(2),$$3 }'
 
+rust_export_macro = EXPORT_SYMBOL_RUST_GPL
 quiet_cmd_exports = EXPORTS $@
       cmd_exports = \
-	$(call rust_exports,$<,"EXPORT_SYMBOL_RUST_GPL(%s);\n") > $@
+	$(call rust_exports,$<,"$(rust_export_macro)(%s);\n") > $@
 
 $(obj)/exports_core_generated.h: $(obj)/core.o FORCE
 	$(call if_changed,exports)
@@ -585,6 +586,7 @@ $(obj)/exports_core_generated.h: $(obj)/core.o FORCE
 # function either. Therefore, we export all symbols from helpers and bindings.
 # In the future, this may be revisited to reduce the number of exports after
 # the compiler is informed about the places codegen is required.
+$(obj)/exports_helpers_generated.h: private rust_export_macro = EXPORT_SYMBOL_RUST_HELPER_GPL
 $(obj)/exports_helpers_generated.h: $(obj)/helpers/helpers.o FORCE
 	$(call if_changed,exports)
 
diff --git a/rust/exports.c b/rust/exports.c
index 1b52460b0f4ee..fde2a52d2a1ae 100644
--- a/rust/exports.c
+++ b/rust/exports.c
@@ -14,6 +14,8 @@
 #include <linux/export.h>
 
 #define EXPORT_SYMBOL_RUST_GPL(sym) extern int sym; EXPORT_SYMBOL_GPL(sym)
+#define EXPORT_SYMBOL_RUST_HELPER_GPL(sym) \
+	extern int sym; EXPORT_SYMBOL_NS_GPL(sym, "RUST_HELPERS")
 
 #include "exports_core_generated.h"
 #include "exports_bindings_generated.h"
diff --git a/rust/macros/module.rs b/rust/macros/module.rs
index 0a7b9e24c9600..ac3376fa8fb85 100644
--- a/rust/macros/module.rs
+++ b/rust/macros/module.rs
@@ -467,6 +467,11 @@ pub(crate) fn module(info: ModuleInfo) -> Result<TokenStream> {
         }
     }
 
+    // Inlined kernel code can introduce calls to C helpers in any Rust module.
+    if !cfg!(CONFIG_RUST_INLINE_HELPERS) {
+        modinfo.emit_only_loadable("import_ns", "RUST_HELPERS", false);
+    }
+
     // Built-in modules also export the `file` modinfo string.
     let file =
         std::env::var("RUST_MODFILE").expect("Unable to fetch RUST_MODFILE environmental variable");

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261120-rust-helper-namespace-57e8c37ee7df

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

