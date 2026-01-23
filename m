From: SeungJong Ha <engineer.jjhama@gmail.com>
Date: Fri, 23 Jan 2026 13:18:44 +0000
Subject: [PATCH v2] scripts: generate_rust_analyzer: fix resolution of
 #[pin_data] macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260123-fix-pin-init-crate-dependecies-v2-1-bb1c2500e54c@gmail.com>
X-B4-Tracking: v=1; b=H4sIADN1c2kC/42NQQ6CQAxFr0K6tgaGEcWV9zAsainQRAYyQ4iGc
 HerJzB/9X7y398gSVRJcM02iLJq0ikYuEMGPFDoBbU1Bpe7Ki9ciZ2+cNaAGnRBjrQItjJLaIX
 Ng4/aE3vnz+QvYJI5ii1+B/fGeNC0TPH9+1uLb/u3ei3QwhV3UhOVJ3frR9LnkacRmn3fP64d9
 FjMAAAA
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>
Cc: rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jesung Yang <y.j3ms.n@gmail.com>, SeungJong Ha <engineer.jjhama@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1769174341; l=1902;
 i=engineer.jjhama@gmail.com; s=20260103; h=from:subject:message-id;
 bh=c7P9j4yaUBkVPSuFKvUbKfXZDCnr6ZWiWGUJURpt+5A=;
 b=iooMwfpk6BvhAz77cbYZxulg/1QPZPrvPxRDPgdolo3ZaYnWEN4irWRH6N1xKv7nanDuDhphy
 tXEShaG5pkKBI5EIeAfT99Gw3MpmP29W8ArojELHDr9ZRgUBjQO6CmD
X-Developer-Key: i=engineer.jjhama@gmail.com; a=ed25519;
 pk=G5nmjm+RTiWBpyCvc5xjR1b3li/2zipLSMyz+T4fj5E=
X-Endpoint-Received: by B4 Relay for engineer.jjhama@gmail.com/20260103 with auth_id=590
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, rust-analyzer fails to properly resolve structs annotated with
`#[pin_data]`. This prevents IDE features like "Go to Definition" from
working correctly for those structs.

Add the missing configuration to `generate_rust_analyzer.py` to ensure
the `pin-init` crate macros are handled correctly.

Signed-off-by: SeungJong Ha <engineer.jjhama@gmail.com>
---
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
Changes in v2:
- Fix typos
- Drop the quote module workaround (will be handled separately)
- Rebase onto `rust-fixes`
- Add `pin_init` dependency for Rust drivers
- Link to v1: https://lore.kernel.org/r/20260123-fix-pin-init-crate-dependecies-v1-1-1c6cfe9aa352@gmail.com
---
 scripts/generate_rust_analyzer.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/scripts/generate_rust_analyzer.py b/scripts/generate_rust_analyzer.py
index 3b645da90092..766c2d91cd81 100755
--- a/scripts/generate_rust_analyzer.py
+++ b/scripts/generate_rust_analyzer.py
@@ -214,7 +214,7 @@ def generate_crates(srctree, objtree, sysroot_src, external_src, cfgs, core_edit
             append_crate(
                 name,
                 path,
-                ["core", "kernel"],
+                ["core", "kernel", "pin_init"],
                 cfg=cfg,
             )
 

---
base-commit: 6d7fef23043553336259211346b6b135d6c1f4c3
change-id: 20260123-fix-pin-init-crate-dependecies-b94ac4247a48

Best regards,
-- 
SeungJong Ha <engineer.jjhama@gmail.com>

