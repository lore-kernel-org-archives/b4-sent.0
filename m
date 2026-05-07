From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Thu, 07 May 2026 23:47:25 +0900
Subject: [PATCH v7 2/2] scripts: generate_rust_analyzer.py: fix IDE support
 for primitive types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-ra-fix-primitive-v7-2-cb8e3791f2b5@gmail.com>
References: <20260507-ra-fix-primitive-v7-0-cb8e3791f2b5@gmail.com>
In-Reply-To: <20260507-ra-fix-primitive-v7-0-cb8e3791f2b5@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Tamir Duberstein <tamird@kernel.org>
Cc: Eliot Courtney <ecourtney@nvidia.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778165245; l=9490;
 i=y.j3ms.n@gmail.com; s=kernel; h=from:subject:message-id;
 bh=EfvWMSOdPqKPOjfHTHCBWBx35ul3PX2qpFJE57W+2l0=;
 b=VTw/KhSIaNqnEzg6Wy1ZdcDDA6jjbv9bmmDXe0XPLkHybd0hL74urX6tOhk4TVs3MaaU26mkw
 eavdgE58S9tDzO2CizoUTiP0yLiPBLwMxVlQvf0/mp6NEiKOUZ2Jmo5
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=4nSlncQuTIIYLyLXkNxS0ssInM3uK0snxLSeQ2tdG/o=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/kernel with auth_id=755
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
Reviewed-by: Tamir Duberstein <tamird@kernel.org>
Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 scripts/generate_rust_analyzer.py | 108 ++++++++++++++++++++++++++++++--------
 1 file changed, 87 insertions(+), 21 deletions(-)

diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index 79c69004aed1..8629dd186891 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -4,6 +4,7 @@
 """
 
 import argparse
+from dataclasses import dataclass
 from datetime import date
 import enum
 import re
@@ -39,14 +40,28 @@ class Source(TypedDict):
     exclude_dirs: List[str]
 
 
-class Crate(TypedDict):
-    display_name: str
-    root_module: str
-    is_workspace_member: bool
-    deps: List[Dependency]
-    cfg: List[str]
-    edition: str
-    env: Dict[str, str]
+# TODO: clean up once Python 3.11 is adopted.
+if sys.version_info < (3, 11):
+    class Crate(TypedDict, total=False):
+        display_name: str
+        root_module: str
+        is_workspace_member: bool
+        deps: List[Dependency]
+        cfg: List[str]
+        crate_attrs: List[str]
+        edition: str
+        env: Dict[str, str]
+else:
+    from typing import NotRequired
+    class Crate(TypedDict):
+        display_name: str
+        root_module: str
+        is_workspace_member: bool
+        deps: List[Dependency]
+        cfg: List[str]
+        crate_attrs: NotRequired[List[str]]
+        edition: str
+        env: Dict[str, str]
 
 
 class ProcMacroCrate(Crate):
@@ -58,7 +73,14 @@ class CrateWithGenerated(Crate):
     source: Source
 
 
+@dataclass(frozen=True)
+class RaVersionCtx:
+    manual_sysroot_crates: bool
+    use_crate_attrs: bool
+
+
 def generate_crates(
+    ctx: RaVersionCtx,
     srctree: pathlib.Path,
     objtree: pathlib.Path,
     sysroot_src: pathlib.Path,
@@ -84,22 +106,24 @@ def generate_crates(
     def build_crate(
         display_name: str,
         root_module: pathlib.Path,
-        deps: List[Dependency],
+        deps: List[Optional[Dependency]],
         *,
         cfg: Optional[List[str]],
+        crate_attrs: Optional[List[str]],
         is_workspace_member: Optional[bool],
         edition: Optional[str],
     ) -> Crate:
+        filtered_deps = [dep for dep in deps if dep is not None]
         cfg = cfg if cfg is not None else crates_cfgs.get(display_name, [])
         is_workspace_member = (
             is_workspace_member if is_workspace_member is not None else True
         )
         edition = edition if edition is not None else "2021"
-        return {
+        crate: Crate = {
             "display_name": display_name,
             "root_module": str(root_module),
             "is_workspace_member": is_workspace_member,
-            "deps": deps,
+            "deps": filtered_deps,
             "cfg": cfg,
             "edition": edition,
             "env": {
@@ -107,10 +131,15 @@ def generate_crates(
             }
         }
 
+        if ctx.use_crate_attrs and crate_attrs is not None:
+            crate["crate_attrs"] = crate_attrs
+
+        return crate
+
     def append_proc_macro_crate(
         display_name: str,
         root_module: pathlib.Path,
-        deps: List[Dependency],
+        deps: List[Optional[Dependency]],
         *,
         cfg: Optional[List[str]] = None,
         is_workspace_member: Optional[bool] = None,
@@ -121,6 +150,7 @@ def generate_crates(
             root_module,
             deps,
             cfg=cfg,
+            crate_attrs=None,
             is_workspace_member=is_workspace_member,
             edition=edition,
         )
@@ -148,9 +178,10 @@ def generate_crates(
     def append_crate(
         display_name: str,
         root_module: pathlib.Path,
-        deps: List[Dependency],
+        deps: List[Optional[Dependency]],
         *,
         cfg: Optional[List[str]] = None,
+        crate_attrs: Optional[List[str]] = None,
         is_workspace_member: Optional[bool] = None,
         edition: Optional[str] = None,
     ) -> Dependency:
@@ -160,6 +191,7 @@ def generate_crates(
                 root_module,
                 deps,
                 cfg=cfg,
+                crate_attrs=crate_attrs,
                 is_workspace_member=is_workspace_member,
                 edition=edition,
             )
@@ -167,10 +199,12 @@ def generate_crates(
 
     def append_sysroot_crate(
         display_name: str,
-        deps: List[Dependency],
+        deps: List[Optional[Dependency]],
         *,
         cfg: Optional[List[str]] = None,
-    ) -> Dependency:
+    ) -> Optional[Dependency]:
+        if not ctx.manual_sysroot_crates:
+            return None
         return append_crate(
             display_name,
             sysroot_src / display_name / "src" / "lib.rs",
@@ -269,13 +303,14 @@ def generate_crates(
 
     def append_crate_with_generated(
         display_name: str,
-        deps: List[Dependency],
+        deps: List[Optional[Dependency]],
     ) -> Dependency:
         crate = build_crate(
             display_name,
             srctree / "rust"/ display_name / "lib.rs",
             deps,
             cfg=generated_cfg,
+            crate_attrs=None,
             is_workspace_member=True,
             edition=None,
         )
@@ -342,6 +377,7 @@ def generate_crates(
                 path,
                 [core, kernel, pin_init],
                 cfg=generated_cfg,
+                crate_attrs=["no_std"],
             )
 
     return crates
@@ -415,6 +451,21 @@ class RaVersionInfo(enum.Enum):
         date(2024, 12, 23),
         (0, 3, 2228),
         (1, 85, 0),
+        RaVersionCtx(
+            use_crate_attrs=False,
+            manual_sysroot_crates=True,
+        ),
+    )
+    # v0.3.2727, released on 2025-12-22;
+    # v0.3.2743 is shipped with the rustup 1.94.0 toolchain.
+    SUPPROTS_CRATE_ATTRS = (
+        date(2025, 12, 22),
+        (0, 3, 2727),
+        (1, 94, 0),
+        RaVersionCtx(
+            use_crate_attrs=True,
+            manual_sysroot_crates=False,
+        ),
     )
 
     def __init__(
@@ -422,19 +473,30 @@ class RaVersionInfo(enum.Enum):
         release_date: date,
         ra_version: Version,
         rust_version: Version,
+        ctx: RaVersionCtx,
     ) -> None:
         self.release_date = release_date
         self.ra_version = ra_version
         self.rust_version = rust_version
+        self.ctx = ctx
 
 
-class RustProject(TypedDict):
-    crates: List[Crate]
-    sysroot: str
+# TODO: clean up once Python 3.11 is adopted.
+if sys.version_info < (3, 11):
+    class RustProject(TypedDict, total=False):
+        crates: List[Crate]
+        sysroot: str
+        sysroot_src: str
+else:
+    from typing import NotRequired
+    class RustProject(TypedDict):
+        crates: List[Crate]
+        sysroot: str
+        sysroot_src: NotRequired[str]
 
 
 def generate_rust_project(
-    _version_info: RaVersionInfo,
+    version_info: RaVersionInfo,
     srctree: pathlib.Path,
     objtree: pathlib.Path,
     sysroot: pathlib.Path,
@@ -443,13 +505,17 @@ def generate_rust_project(
     cfgs: List[str],
     core_edition: str,
 ) -> RustProject:
+    ctx = version_info.ctx
     rust_project: RustProject = {
         "crates": generate_crates(
-            srctree, objtree, sysroot_src, external_src, cfgs, core_edition
+            ctx, srctree, objtree, sysroot_src, external_src, cfgs, core_edition
         ),
         "sysroot": str(sysroot),
     }
 
+    if not ctx.manual_sysroot_crates:
+        rust_project["sysroot_src"] = str(sysroot_src)
+
     return rust_project
 
 def query_ra_version() -> Optional[str]:

-- 
2.53.0

