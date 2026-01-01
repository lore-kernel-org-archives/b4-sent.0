From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Thu, 01 Jan 2026 06:25:26 +0000
Subject: [PATCH] rust: fix IDE support for inherent methods of primitive
 types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-ra-fix-primitive-v1-1-def809357b4e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAFYTVmkC/x2MSQqAMAwAvyI5G2jcWvyKeBBNNQdrSUUE8e8Wj
 wMz80BiFU7QFw8oX5LkCBmoLGDeprAyypIZKlN1hgyhTujlxqiyyykXo3XUNp4d2dpDzqJyFv7
 lML7vB2ZAB5ViAAAA
X-Change-ID: 20260101-ra-fix-primitive-78154fe8173f
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767248738; l=9946;
 i=y.j3ms.n@gmail.com; s=20251225; h=from:subject:message-id;
 bh=ngAPSt8b3oSBCTDeW0vwzZHGZOR+W6apYA6LrKYv1Mo=;
 b=GlqIccwMqCaABUlbqwmoQco5WbIYGl1uFADWuvG6uHNIjKrshZEPxAdrV1XrFUjDPEayxflr6
 gM9pbtlpzBTAAxUEVX30XGNVliuq9hVErZnPhL4xq7z3qdlrehiEPXL
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=2yVgO1I+y7kkFSF2Dc/Dckj4L2FgRnvmERHFt4bspbI=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/20251225 with auth_id=586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update `generate_rust_analyzer.py` so that the generated
`rust-project.json` contains the `sysroot_src` field with
`"crate_attrs": ["no_std"]` specified for relevant crates. This ensures
that rust-analyzer provides proper IDE support for inherent methods of
primitive types.

Since commit 50384460c68f ("Rewrite method resolution to follow rustc
more closely") to rust-analyzer, it no longer provides language server
features like code completion and go-to-definition for inherent methods
of primitive types when sysroot crates (e.g., `core`, `std`) are inlined
in `rust-project.json` [1]. As `generate_rust_analyzer.py` currently
inlines these crates, our setup is affected by this change.

Specifying the `sysroot_src` field restores this functionality by
allowing rust-analyzer to locate sysroot crates by itself. However, this
causes `std` to be treated as a dependency for all local crates by
default. To align with our compilation settings, provide the `no_std`
attribute via the `crate_attrs` field, as the `-Zcrate-attr=no_std`
compiler flag is not visible to rust-analyzer. This combined approach
removes manual manipulation of sysroot dependencies while preventing
incorrect symbol resolution against the standard library.

Note that this configuration requires rust-analyzer release 2025-12-22
(v0.3.2727) or later, which introduced support for the `crate_attrs`
field.

Link: https://rust-lang.zulipchat.com/#narrow/channel/x/topic/x/near/561607963 [1]
Link: https://rust-for-linux.zulipchat.com/#narrow/channel/x/topic/x/near/561607753

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 rust/Makefile                     |  1 -
 scripts/generate_rust_analyzer.py | 75 +++++++++++++++++++--------------------
 2 files changed, 37 insertions(+), 39 deletions(-)

diff --git a/rust/Makefile b/rust/Makefile
index 5d357dce1704d15e43effc528be8f5a4d74d3d8d..5110b7fa7b21941894dfeadc1fec5e87af3e7515 100644
--- a/rust/Makefile
+++ b/rust/Makefile
@@ -566,7 +566,6 @@ quiet_cmd_rustc_library = $(if $(skip_clippy),RUSTC,$(RUSTC_OR_CLIPPY_QUIET)) L
 
 rust-analyzer:
 	$(Q)MAKEFLAGS= $(srctree)/scripts/generate_rust_analyzer.py \
-		--cfgs='core=$(core-cfgs)' $(core-edition) \
 		--cfgs='proc_macro2=$(proc_macro2-cfgs)' \
 		--cfgs='quote=$(quote-cfgs)' \
 		--cfgs='syn=$(syn-cfgs)' \
diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index 147d0cc940681426771db865bc2462e7029a6d7d..6178a53516ec35f308897e65c5001edd81b0d3dd 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -19,7 +19,7 @@ def args_crates_cfgs(cfgs):
 
     return crates_cfgs
 
-def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edition):
+def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs):
     # Generate the configuration list.
     cfg = []
     with open(objtree / "include" / "generated" / "rustc_cfg") as fd:
@@ -35,7 +35,7 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
     crates_indexes = {}
     crates_cfgs = args_crates_cfgs(cfgs)
 
-    def append_crate(display_name, root_module, deps, cfg=[], is_workspace_member=True, is_proc_macro=False, edition="2021"):
+    def append_crate(display_name, root_module, deps, cfg=[], crate_attrs=[], is_workspace_member=True, is_proc_macro=False, edition="2021"):
         crate = {
             "display_name": display_name,
             "root_module": str(root_module),
@@ -48,6 +48,8 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
                 "RUST_MODFILE": "This is only for rust-analyzer"
             }
         }
+        if len(crate_attrs) > 0:
+            crate["crate_attrs"] = crate_attrs
         if is_proc_macro:
             proc_macro_dylib_name = subprocess.check_output(
                 [os.environ["RUSTC"], "--print", "file-names", "--crate-name", display_name, "--crate-type", "proc-macro", "-"],
@@ -57,67 +59,46 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
         crates_indexes[display_name] = len(crates)
         crates.append(crate)
 
-    def append_sysroot_crate(
-        display_name,
-        deps,
-        cfg=[],
-        edition="2021",
-    ):
-        append_crate(
-            display_name,
-            sysroot_src / display_name / "src" / "lib.rs",
-            deps,
-            cfg,
-            is_workspace_member=False,
-            edition=edition,
-        )
-
-    # NB: sysroot crates reexport items from one another so setting up our transitive dependencies
-    # here is important for ensuring that rust-analyzer can resolve symbols. The sources of truth
-    # for this dependency graph are `(sysroot_src / crate / "Cargo.toml" for crate in crates)`.
-    append_sysroot_crate("core", [], cfg=crates_cfgs.get("core", []), edition=core_edition)
-    append_sysroot_crate("alloc", ["core"])
-    append_sysroot_crate("std", ["alloc", "core"])
-    append_sysroot_crate("proc_macro", ["core", "std"])
-
     append_crate(
         "compiler_builtins",
         srctree / "rust" / "compiler_builtins.rs",
         [],
+        crate_attrs=["no_std"],
     )
 
     append_crate(
         "proc_macro2",
         srctree / "rust" / "proc-macro2" / "lib.rs",
-        ["core", "alloc", "std", "proc_macro"],
+        [],
         cfg=crates_cfgs["proc_macro2"],
     )
 
     append_crate(
         "quote",
         srctree / "rust" / "quote" / "lib.rs",
-        ["alloc", "proc_macro", "proc_macro2"],
+        ["proc_macro2"],
         cfg=crates_cfgs["quote"],
     )
 
     append_crate(
         "syn",
         srctree / "rust" / "syn" / "lib.rs",
-        ["proc_macro", "proc_macro2", "quote"],
+        ["proc_macro2", "quote"],
         cfg=crates_cfgs["syn"],
     )
 
     append_crate(
         "macros",
         srctree / "rust" / "macros" / "lib.rs",
-        ["std", "proc_macro", "proc_macro2", "quote", "syn"],
+        ["proc_macro2", "quote", "syn"],
         is_proc_macro=True,
     )
 
     append_crate(
         "build_error",
         srctree / "rust" / "build_error.rs",
-        ["core", "compiler_builtins"],
+        ["compiler_builtins"],
+        crate_attrs=["no_std"],
     )
 
     append_crate(
@@ -125,31 +106,36 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
         srctree / "rust" / "pin-init" / "internal" / "src" / "lib.rs",
         [],
         cfg=["kernel"],
+        crate_attrs=["no_std"],
         is_proc_macro=True,
     )
 
     append_crate(
         "pin_init",
         srctree / "rust" / "pin-init" / "src" / "lib.rs",
-        ["core", "pin_init_internal", "macros"],
+        ["pin_init_internal", "macros"],
         cfg=["kernel"],
+        crate_attrs=["no_std"],
     )
 
     append_crate(
         "ffi",
         srctree / "rust" / "ffi.rs",
-        ["core", "compiler_builtins"],
+        ["compiler_builtins"],
+        crate_attrs=["no_std"],
     )
 
     def append_crate_with_generated(
         display_name,
         deps,
+        crate_attrs=[],
     ):
         append_crate(
             display_name,
             srctree / "rust"/ display_name / "lib.rs",
             deps,
             cfg=cfg,
+            crate_attrs=crate_attrs,
         )
         crates[-1]["env"]["OBJTREE"] = str(objtree.resolve(True))
         crates[-1]["source"] = {
@@ -160,9 +146,21 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             "exclude_dirs": [],
         }
 
-    append_crate_with_generated("bindings", ["core", "ffi", "pin_init"])
-    append_crate_with_generated("uapi", ["core", "ffi", "pin_init"])
-    append_crate_with_generated("kernel", ["core", "macros", "build_error", "pin_init", "ffi", "bindings", "uapi"])
+    append_crate_with_generated(
+        "bindings",
+        ["ffi", "pin_init"],
+        crate_attrs=["no_std"],
+    )
+    append_crate_with_generated(
+        "uapi",
+        ["ffi", "pin_init"],
+        crate_attrs=["no_std"],
+    )
+    append_crate_with_generated(
+        "kernel",
+        ["macros", "build_error", "pin_init", "ffi", "bindings", "uapi"],
+        crate_attrs=["no_std"],
+    )
 
     def is_root_crate(build_file, target):
         try:
@@ -190,8 +188,9 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             append_crate(
                 name,
                 path,
-                ["core", "kernel"],
+                ["kernel"],
                 cfg=cfg,
+                crate_attrs=["no_std"],
             )
 
     return crates
@@ -200,7 +199,6 @@ def main():
     parser = argparse.ArgumentParser()
     parser.add_argument('--verbose', '-v', action='store_true')
     parser.add_argument('--cfgs', action='append', default=[])
-    parser.add_argument("core_edition")
     parser.add_argument("srctree", type=pathlib.Path)
     parser.add_argument("objtree", type=pathlib.Path)
     parser.add_argument("sysroot", type=pathlib.Path)
@@ -217,8 +215,9 @@ def main():
     assert args.sysroot in args.sysroot_src.parents
 
     rust_project = {
-        "crates": generate_crates(args.srctree, args.objtree, args.sysroot_src, args.exttree, args.cfgs, args.core_edition),
+        "crates": generate_crates(args.srctree, args.objtree, args.sysroot_src, args.exttree, args.cfgs),
         "sysroot": str(args.sysroot),
+        "sysroot_src": str(args.sysroot_src)
     }
 
     json.dump(rust_project, sys.stdout, sort_keys=True, indent=4)

---
base-commit: f8f9c1f4d0c7a64600e2ca312dec824a0bc2f1da
change-id: 20260101-ra-fix-primitive-78154fe8173f

Best regards,
-- 
Jesung Yang <y.j3ms.n@gmail.com>

