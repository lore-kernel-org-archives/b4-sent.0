From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Fri, 23 Jan 2026 10:02:45 +0000
Subject: [PATCH] scripts: generate_rust_analyzer.py: better pin-init macro
 resolvea
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-fix-pin-init-crate-dependecies-v1-1-1c6cfe9aa352@gmail.com>
X-B4-Tracking: v=1; b=H4sIAERHc2kC/x2NwQqDMBAFf0X23AWNobX9leIhJk+7lzUkIgXx3
 108zmFmDqoogkqf5qCCXaqsatA9Goq/oAtYkjG51j3bzvU8y5+zKIvKxrGEDZyQoQnROjy9fYj
 e+VfwA1kkF5hxD77jeV7cntPXcAAAAA==
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769162566; l=2124;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=+X4zr6kdvi4oIiyjF3Tjs9UDmHAGo3XY3Bau+3noR/I=;
 b=GX3iubRy+ziATd5+KV++EBfG7k5Ul6g+5g1l6RGuEC9nGzyl5lnygPdW0xNDubSJ7a6FoFZAp
 aZePNC4VEywAR+xFXl07BPf/t+M1qYQKKTgSkM+jxcBOzUqVKEb7yqt
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
scripts: generate_rust_analyzer.py: Fix pin-init configuration for
better macro resolve

Hello,

I encountered an issue where rust-analyzer fails to analyze
structs decorated with the #[pin_data] attribute while testing
Rust kernel modules.

It appears that the dependencies for pin-init and drivers were
missing from the analyzer's configuration. This patch adds
those missing dependencies.

I have verified that my rust-analyzer correctly processes
\#[pin_data] structs after applying this fix.

Best regards, SeungJong
---
 scripts/generate_rust_analyzer.py | 12 ++++++++++--
 1 file changed, 10 insertions(+), 2 deletions(-)

diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index 147d0cc94068..0c6c0444917f 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -123,10 +123,18 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
     append_crate(
         "pin_init_internal",
         srctree / "rust" / "pin-init" / "internal" / "src" / "lib.rs",
-        [],
+        ["std", "proc_macro"],
         cfg=["kernel"],
         is_proc_macro=True,
     )
+    # pin_init_internal uses #[path = "../../../macros/quote.rs"] to include quote.rs
+    crates[-1]["source"] = {
+        "include_dirs": [
+            str(srctree / "rust" / "pin-init" / "internal" / "src"),
+            str(srctree / "rust" / "macros"),
+        ],
+        "exclude_dirs": [],
+    }
 
     append_crate(
         "pin_init",
@@ -190,7 +198,7 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             append_crate(
                 name,
                 path,
-                ["core", "kernel"],
+                ["core", "kernel", "pin_init"],
                 cfg=cfg,
             )
 

---
base-commit: 2ad6c5cdc89acfefb01b84afa5e55262c40d6fec
change-id: 20260123-fix-pin-init-crate-dependecies-b94ac4247a48

Best regards,
-- 
SeungJong Ha <engineer.jjhama@gmail.com>

