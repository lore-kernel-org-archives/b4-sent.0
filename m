From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Fri, 09 Jan 2026 22:09:00 +0000
Subject: [PATCH v2 1/2] scripts: generate_rust_analyzer: add versioning
 infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260109-ra-fix-primitive-v2-1-249852a4145a@gmail.com>
References: <20260109-ra-fix-primitive-v2-0-249852a4145a@gmail.com>
In-Reply-To: <20260109-ra-fix-primitive-v2-0-249852a4145a@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Tamir Duberstein <tamird@gmail.com>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767996618; l=12537;
 i=y.j3ms.n@gmail.com; s=20251225; h=from:subject:message-id;
 bh=JWm8UAfLC1ns7QSTpKBpu5bO5YwhtDcjTNcOdRHiGqo=;
 b=HM3QI/KHxq8ZehXyGmdn5mv0OuBo3uPpmwbcxYy2lLpkXlkmGzY/GcHAu0j011w+/+tGc3S3j
 dD4JblSEHvVAZpz9eygoUoqhNmV8jKi4pEAs9MgDtdUNTCZRDs8AaUr
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=2yVgO1I+y7kkFSF2Dc/Dckj4L2FgRnvmERHFt4bspbI=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/20251225 with auth_id=586
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce multi-version support for rust-analyzer. The script now
executes `rust-analyzer --version` to query the version string and
generates a `rust-project.json` file compatible with the detected
version.

This is a preparatory patch to address inherent method resolution
failures for primitive types occurring in rust-analyzer v0.3.2693
(2025-11-24) or later when used with our current `rust-project.json`
generation logic. Since the actual fix requires a feature only available
in rust-analyzer v0.3.2727 (2025-12-22) or later, this infrastructure is
necessary to avoid breaking compatibility with rust-analyzer v0.3.1940
(2024-04-29), which corresponds to our MSRV of 1.78.

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 scripts/generate_rust_analyzer.py | 181 +++++++++++++++++++++++++++++++++-----
 1 file changed, 157 insertions(+), 24 deletions(-)

diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index 147d0cc940681426771db865bc2462e7029a6d7d..32b0da99f17549ecc83e9a68911373310a2c9617 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -4,10 +4,13 @@
 """
 
 import argparse
+from datetime import datetime
+import enum
 import json
 import logging
 import os
 import pathlib
+import re
 import subprocess
 import sys
 
@@ -19,7 +22,7 @@ def args_crates_cfgs(cfgs):
 
     return crates_cfgs
 
-def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edition):
+def generate_crates(ctx, srctree, objtree, sysroot_src, external_src, cfgs, core_edition):
     # Generate the configuration list.
     cfg = []
     with open(objtree / "include" / "generated" / "rustc_cfg") as fd:
@@ -35,7 +38,7 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
     crates_indexes = {}
     crates_cfgs = args_crates_cfgs(cfgs)
 
-    def append_crate(display_name, root_module, deps, cfg=[], is_workspace_member=True, is_proc_macro=False, edition="2021"):
+    def append_crate(display_name, root_module, deps, cfg=[], crate_attrs=[], is_workspace_member=True, is_proc_macro=False, edition="2021"):
         crate = {
             "display_name": display_name,
             "root_module": str(root_module),
@@ -48,6 +51,8 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
                 "RUST_MODFILE": "This is only for rust-analyzer"
             }
         }
+        if ctx["use_crate_attrs"] and len(crate_attrs) > 0:
+            crate["crate_attrs"] = crate_attrs
         if is_proc_macro:
             proc_macro_dylib_name = subprocess.check_output(
                 [os.environ["RUSTC"], "--print", "file-names", "--crate-name", display_name, "--crate-type", "proc-macro", "-"],
@@ -72,52 +77,58 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             edition=edition,
         )
 
-    # NB: sysroot crates reexport items from one another so setting up our transitive dependencies
-    # here is important for ensuring that rust-analyzer can resolve symbols. The sources of truth
-    # for this dependency graph are `(sysroot_src / crate / "Cargo.toml" for crate in crates)`.
-    append_sysroot_crate("core", [], cfg=crates_cfgs.get("core", []), edition=core_edition)
-    append_sysroot_crate("alloc", ["core"])
-    append_sysroot_crate("std", ["alloc", "core"])
-    append_sysroot_crate("proc_macro", ["core", "std"])
+    def sysroot_deps(*deps):
+        return list(deps) if ctx["add_sysroot_crates"] else []
+
+    if ctx["add_sysroot_crates"]:
+        # NB: sysroot crates reexport items from one another so setting up our transitive dependencies
+        # here is important for ensuring that rust-analyzer can resolve symbols. The sources of truth
+        # for this dependency graph are `(sysroot_src / crate / "Cargo.toml" for crate in crates)`.
+        append_sysroot_crate("core", [], cfg=crates_cfgs.get("core", []), edition=core_edition)
+        append_sysroot_crate("alloc", ["core"])
+        append_sysroot_crate("std", ["alloc", "core"])
+        append_sysroot_crate("proc_macro", ["core", "std"])
 
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
+        sysroot_deps("core", "alloc", "std", "proc_macro"),
         cfg=crates_cfgs["proc_macro2"],
     )
 
     append_crate(
         "quote",
         srctree / "rust" / "quote" / "lib.rs",
-        ["alloc", "proc_macro", "proc_macro2"],
+        sysroot_deps("alloc", "proc_macro") + ["proc_macro2"],
         cfg=crates_cfgs["quote"],
     )
 
     append_crate(
         "syn",
         srctree / "rust" / "syn" / "lib.rs",
-        ["proc_macro", "proc_macro2", "quote"],
+        sysroot_deps("proc_macro") + ["proc_macro2", "quote"],
         cfg=crates_cfgs["syn"],
     )
 
     append_crate(
         "macros",
         srctree / "rust" / "macros" / "lib.rs",
-        ["std", "proc_macro", "proc_macro2", "quote", "syn"],
+        sysroot_deps("std", "proc_macro") + ["proc_macro2", "quote", "syn"],
         is_proc_macro=True,
     )
 
     append_crate(
         "build_error",
         srctree / "rust" / "build_error.rs",
-        ["core", "compiler_builtins"],
+        sysroot_deps("core") + ["compiler_builtins"],
+        crate_attrs=["no_std"],
     )
 
     append_crate(
@@ -125,31 +136,36 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
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
+        sysroot_deps("core") + ["pin_init_internal", "macros"],
         cfg=["kernel"],
+        crate_attrs=["no_std"],
     )
 
     append_crate(
         "ffi",
         srctree / "rust" / "ffi.rs",
-        ["core", "compiler_builtins"],
+        sysroot_deps("core") + ["compiler_builtins"],
+        crate_attrs=["no_std"],
     )
 
     def append_crate_with_generated(
         display_name,
         deps,
+        crate_attrs=[]
     ):
         append_crate(
             display_name,
             srctree / "rust"/ display_name / "lib.rs",
             deps,
             cfg=cfg,
+            crate_attrs=crate_attrs
         )
         crates[-1]["env"]["OBJTREE"] = str(objtree.resolve(True))
         crates[-1]["source"] = {
@@ -160,9 +176,21 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             "exclude_dirs": [],
         }
 
-    append_crate_with_generated("bindings", ["core", "ffi", "pin_init"])
-    append_crate_with_generated("uapi", ["core", "ffi", "pin_init"])
-    append_crate_with_generated("kernel", ["core", "macros", "build_error", "pin_init", "ffi", "bindings", "uapi"])
+    append_crate_with_generated(
+        "bindings",
+        sysroot_deps("core") + ["ffi", "pin_init"],
+        crate_attrs=["no_std"],
+    )
+    append_crate_with_generated(
+        "uapi",
+        sysroot_deps("core") + ["ffi", "pin_init"],
+        crate_attrs=["no_std"],
+    )
+    append_crate_with_generated(
+        "kernel",
+        sysroot_deps("core") + ["macros", "build_error", "pin_init", "ffi", "bindings", "uapi"],
+        crate_attrs=["no_std"],
+    )
 
     def is_root_crate(build_file, target):
         try:
@@ -190,12 +218,103 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             append_crate(
                 name,
                 path,
-                ["core", "kernel"],
+                sysroot_deps("core") + ["kernel"],
                 cfg=cfg,
+                crate_attrs=["no_std"]
             )
 
     return crates
 
+@enum.unique
+class RaVersion(enum.Enum):
+    """
+    Represents rust-analyzer compatibility baselines. Concrete versions are mapped to the most
+    recent baseline they have reached. Must be in release order.
+    """
+
+    # v0.3.1940, released on 2024-04-29; bundled with the rustup 1.78 toolchain.
+    V20240429 = 0
+
+    @staticmethod
+    def baselines():
+        assert len(RaVersion) == 1, "Exhaustiveness check: update baseline list!"
+
+        return [
+            (datetime.strptime("2024-04-29", "%Y-%m-%d"), (0, 3, 1940), RaVersion.V20240429),
+        ]
+
+    @staticmethod
+    def default():
+        # The default is the 2024-04-29 release, aligning with our MSRV policy.
+        return RaVersion.V20240429
+
+    def __str__(self):
+        assert len(RaVersion) == 1, "Exhaustiveness check: update if branches!"
+
+        if self == RaVersion.V20240429:
+            return "v0.3.1940 (2024-04-29)"
+        else:
+            assert False, "Unreachable"
+
+def generate_rust_project(
+    ra_version,
+    srctree,
+    objtree,
+    sysroot,
+    sysroot_src,
+    external_src,
+    cfgs,
+    core_edition
+):
+    assert len(RaVersion) == 1, "Exhaustiveness check: update if branches!"
+
+    if ra_version == RaVersion.V20240429:
+        ctx = {
+            "use_crate_attrs": False,
+            "add_sysroot_crates": True,
+        }
+        return {
+            "crates": generate_crates(ctx, srctree, objtree, sysroot_src, external_src, cfgs, core_edition),
+            "sysroot": str(sysroot),
+        }
+    else:
+        assert False, "Unreachable"
+
+def query_ra_version():
+    try:
+        # Use the rust-analyzer binary found in $PATH.
+        ra_version_output = subprocess.check_output(
+            ["rust-analyzer", "--version"],
+            stdin=subprocess.DEVNULL,
+        ).decode('utf-8').strip()
+        return ra_version_output
+    except FileNotFoundError:
+        logging.warning("Failed to find rust-analyzer in $PATH")
+        return None
+
+def map_ra_version_baseline(ra_version_output):
+    checkpoints = reversed(RaVersion.baselines())
+
+    # First, attempt to resolve to our known checkpoint using the release date.
+    # This covers patterns like "rust-analyzer 1.78.0 (9b00956e 2024-04-29)".
+    date_match = re.search(r"\d{4}-\d{2}-\d{2}", ra_version_output)
+    if date_match:
+        found_date = datetime.strptime(date_match.group(), "%Y-%m-%d")
+        for date, ver, enum in checkpoints:
+            if found_date >= date:
+                return enum
+
+    # Otherwise, attempt to resolve to our known checkpoint using the rust-analyzer version.
+    # This covers patterns like "rust-analyzer 0.3.2743-standalone".
+    version_match = re.search(r"\d+\.\d+\.\d+", ra_version_output)
+    if version_match:
+        found_version = tuple(map(int, version_match.group().split(".")))
+        for date, ver, enum in checkpoints:
+            if found_version >= ver:
+                return enum
+
+    return RaVersion.default()
+
 def main():
     parser = argparse.ArgumentParser()
     parser.add_argument('--verbose', '-v', action='store_true')
@@ -216,10 +335,24 @@ def main():
     # Making sure that the `sysroot` and `sysroot_src` belong to the same toolchain.
     assert args.sysroot in args.sysroot_src.parents
 
-    rust_project = {
-        "crates": generate_crates(args.srctree, args.objtree, args.sysroot_src, args.exttree, args.cfgs, args.core_edition),
-        "sysroot": str(args.sysroot),
-    }
+    output = query_ra_version()
+    if output:
+        compatible_ra_version = map_ra_version_baseline(output)
+    else:
+        default = RaVersion.default()
+        logging.warning("Falling back to `rust-project.json` for rust-analyzer %s", default)
+        compatible_ra_version = default
+
+    rust_project = generate_rust_project(
+        compatible_ra_version,
+        args.srctree,
+        args.objtree,
+        args.sysroot,
+        args.sysroot_src,
+        args.exttree,
+        args.cfgs,
+        args.core_edition,
+    )
 
     json.dump(rust_project, sys.stdout, sort_keys=True, indent=4)
 

-- 
2.47.3

