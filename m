From: Jesung Yang <y.j3ms.n@gmail.com>
Date: Mon, 04 May 2026 22:20:59 +0900
Subject: [PATCH v6 1/2] scripts: generate_rust_analyzer.py: add versioning
 infrastructure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-ra-fix-primitive-v6-1-74cfc1e862d0@gmail.com>
References: <20260504-ra-fix-primitive-v6-0-74cfc1e862d0@gmail.com>
In-Reply-To: <20260504-ra-fix-primitive-v6-0-74cfc1e862d0@gmail.com>
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, Tamir Duberstein <tamird@kernel.org>
Cc: Eliot Courtney <ecourtney@nvidia.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Jesung Yang <y.j3ms.n@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777900862; l=7711;
 i=y.j3ms.n@gmail.com; s=kernel; h=from:subject:message-id;
 bh=iMGZ4nKUo7ygsBxQBjRI1Tgrka8f2FIJhcQOAaXiL3A=;
 b=Zo/QKqe6tY3cRTNJUE5I3wXdBBLaGtKO36xta+tB3AAUKbg/WCUunqPd2Q08q5z0UnkVoqmhd
 KiAE4f7fByhCzPtF9wOfsfBq6CT/wvEyXxQeEpsRsIJPwwGN6UuZYEN
X-Developer-Key: i=y.j3ms.n@gmail.com; a=ed25519;
 pk=4nSlncQuTIIYLyLXkNxS0ssInM3uK0snxLSeQ2tdG/o=
X-Endpoint-Received: by B4 Relay for y.j3ms.n@gmail.com/kernel with auth_id=755
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce multi-version support for rust-analyzer. The script now
executes `rust-analyzer --version` to query the version string.

This is a preparatory patch to address inherent method resolution
failures for primitive types occurring in rust-analyzer v0.3.2693
(2025-11-24) or later when used with our current `rust-project.json`
generation logic. Since the actual fix requires using the `sysroot_src`
field with a feature only available in rust-analyzer v0.3.2727
(2025-12-22) or later, this infrastructure is necessary to maintain
compatibility with older rust-analyzer releases.

Signed-off-by: Jesung Yang <y.j3ms.n@gmail.com>
---
 scripts/generate_rust_analyzer.py | 178 +++++++++++++++++++++++++++++++++++++-
 1 file changed, 174 insertions(+), 4 deletions(-)

diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index d5f9a0ca742c..934698c7eb95 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -4,6 +4,9 @@
 """
 
 import argparse
+from datetime import date
+import enum
+import re
 import json
 import logging
 import os
@@ -343,6 +346,153 @@ def generate_crates(
 
     return crates
 
+
+Version = tuple[int, int, int]
+
+
+@enum.unique
+class RaVersionInfo(enum.Enum):
+    """
+    Represents rust-analyzer compatibility baselines. Concrete versions are
+    mapped to the most recent baseline they have reached. Must be in release
+    order.
+    """
+
+    # NOTE:
+    # This rust-analyzer release should be kept in sync with our MSRV (currently
+    # 1.85.0). When the MSRV is bumped, follow the steps below to retrieve the
+    # information needed to update this:
+    #
+    #   1) Clone both Rust and rust-analyzer repositories.
+    #      ```console
+    #      $ git clone https://github.com/rust-lang/rust.git
+    #      $ git clone https://github.com/rust-lang/rust-analyzer.git
+    #      ```
+    #   2) Run the following script, providing the new MSRV as an argument. It
+    #      prints a link to the matching [1] rust-analyzer release page.
+    #      ```bash
+    #      #!/usr/bin/env bash
+    #
+    #      RUST_VERSION=$1
+    #      LOOKAHEAD=50
+    #
+    #      subject_string=$(
+    #        git -C ./rust -c log.follow=false log \
+    #          -n "$LOOKAHEAD" --format='%s' "$RUST_VERSION" \
+    #          -- src/tools/rust-analyzer | grep 'Merge pull request #'
+    #      )
+    #      IFS=$'\n' read -d '' -r -a subject_array <<< "$subject_string"
+    #
+    #      hash=$(
+    #        git -C ./rust-analyzer log -n 1 --format='%H' --fixed-strings \
+    #          "${subject_array[@]/#/--grep=}"
+    #      )
+    #
+    #      tag_predates=$(
+    #        git -C ./rust-analyzer describe --tags --abbrev=0 "$hash"
+    #      )
+    #
+    #      link_prefix="https://github.com/rust-lang/rust-analyzer/releases/tag"
+    #      echo "$link_prefix/$tag_predates"
+    #      ```
+    #   3) Grab the release date and the version string.
+    #
+    # [1] Note that rust-analyzer releases may not perfectly align with those
+    #     shipped in upstream Rust. We take a conservative approach here: use
+    #     the tag that directly predates the latest merge commit found upstream.
+    #
+    # v0.3.2228, released on 2024-12-23;
+    # shipped with the rustup 1.85.0 toolchain.
+    MSRV = (
+        date(2024, 12, 23),
+        (0, 3, 2228),
+        (1, 85, 0),
+    )
+
+    def __init__(
+        self,
+        release_date: date,
+        ra_version: Version,
+        rust_version: Version,
+    ) -> None:
+        self.release_date = release_date
+        self.ra_version = ra_version
+        self.rust_version = rust_version
+
+
+class RustProject(TypedDict):
+    crates: List[Crate]
+    sysroot: str
+
+
+def generate_rust_project(
+    _version_info: RaVersionInfo,
+    srctree: pathlib.Path,
+    objtree: pathlib.Path,
+    sysroot: pathlib.Path,
+    sysroot_src: pathlib.Path,
+    external_src: Optional[pathlib.Path],
+    cfgs: List[str],
+    core_edition: str,
+) -> RustProject:
+    rust_project: RustProject = {
+        "crates": generate_crates(
+            srctree, objtree, sysroot_src, external_src, cfgs, core_edition
+        ),
+        "sysroot": str(sysroot),
+    }
+
+    return rust_project
+
+def query_ra_version() -> Optional[str]:
+    try:
+        # Use the rust-analyzer binary found in $PATH.
+        ra_version_output = (
+            subprocess.check_output(
+                ["rust-analyzer", "--version"],
+                stdin=subprocess.DEVNULL,
+            )
+            .decode("utf-8")
+            .strip()
+        )
+        return ra_version_output
+    except FileNotFoundError:
+        return None
+
+def map_ra_version_baseline(ra_version_output: str) -> RaVersionInfo:
+    baselines = reversed(RaVersionInfo)
+
+    version_match = re.search(r"\d+\.\d+\.\d+", ra_version_output)
+    if version_match:
+        version_string = version_match.group()
+        found_version = tuple(map(int, version_string.split(".")))
+
+        # `rust-analyzer --version` shows a different version string depending
+        # on how the binary is built: it may print either the Rust version or
+        # the rust-analyzer version itself. To distinguish between them, we
+        # leverage rust-analyzer's versioning convention.
+        #
+        # See:
+        # - https://github.com/rust-lang/rust-analyzer/blob/fad5c3d2d642/xtask/src/dist.rs#L19-L21
+        is_ra_version = version_string.startswith(("0.3", "0.4", "0.5"))
+        if is_ra_version:
+            for info in baselines:
+                if found_version >= info.ra_version:
+                    return info
+        else:
+            for info in baselines:
+                if found_version >= info.rust_version:
+                    return info
+
+    date_match = re.search(r"\d{4}-\d{2}-\d{2}", ra_version_output)
+    if date_match:
+        found_date = date.fromisoformat(date_match.group())
+        for info in baselines:
+            if found_date >= info.release_date:
+                return info
+
+    return RaVersionInfo.MSRV
+
 def main() -> None:
     parser = argparse.ArgumentParser()
     parser.add_argument('--verbose', '-v', action='store_true')
@@ -371,10 +521,30 @@ def main() -> None:
         level=logging.INFO if args.verbose else logging.WARNING
     )
 
-    rust_project = {
-        "crates": generate_crates(args.srctree, args.objtree, args.sysroot_src, args.exttree, args.cfgs, args.core_edition),
-        "sysroot": str(args.sysroot),
-    }
+    ra_version_output = query_ra_version()
+    if ra_version_output:
+        compatible_ra_version = map_ra_version_baseline(ra_version_output)
+    else:
+        logging.warning(
+            "Failed to find rust-analyzer in $PATH; " \
+            "falling back to `rust-project.json` for rust-analyzer " \
+            "%s, %s (shipped with Rust %s)",
+            ".".join(map(str, RaVersionInfo.MSRV.ra_version)),
+            RaVersionInfo.MSRV.release_date,
+            ".".join(map(str, RaVersionInfo.MSRV.rust_version)),
+        )
+        compatible_ra_version = RaVersionInfo.MSRV
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
2.53.0

