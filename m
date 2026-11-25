From: Peder Bergan <peder.bergan@gmail.com>
Date: Wed, 25 Nov 2026 11:32:02 +0100
Subject: [PATCH] kbuild: rust: drop the obsolete libclang stack-init probe
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-perf-rust-bindgen-drop-legacy-clang-v1-1-dafbf8d4d3df@gmail.com>
X-B4-Tracking: v=1; b=H4sIACG5BmsC/1WNQQ6CMBBFr0Jm7URKRINXMSzaYYAaUpppMRjC3
 W3Fjcs3mf/eBoHFcoB7sYHwywY7uwTqVACN2g2MtksMVVldlapq9Cw9yhIiGuu6gR12MnuceND
 0RprSBtWl0WVNdFO6gWTywr1dv5VHe3BYzJMpZnX+MDowGtGOxnzKeP6L/PxeZsNH3vEaYd8/s
 C3uwMIAAAA=
X-Change-ID: 20261125-perf-rust-bindgen-drop-legacy-clang-149a05cc71a9
To: Miguel Ojeda <ojeda@kernel.org>
Cc: Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 rust-for-linux@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 llvm@lists.linux.dev, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795602725; l=2276;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=4ZJGRNrE7feOv/GCMj7ydDys1bv5wRP0IitEqJ8w6Fk=;
 b=1fizUnF/HOhdMP16188n+b1IbPvGMzuRgl4VjsgdEjCnNLU3DSwpJZ1ZiwljBjFWbqoZ+Kloo
 Z2BN0qrh7NrBFAjysQZwbT0SKkU3ZCvvEN6Ynf3xD9b5+tfJwU+4f4s
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For Rust-enabled GCC builds with CONFIG_INIT_STACK_ALL_ZERO, the Rust
Makefile runs bindgen to check whether libclang needs the old enabler
for -ftrivial-auto-var-init=zero. LLVM 16 made the flag usable on its own,
and the Rust toolchain check already requires libclang 17.0.1 or newer
(18.0.0 on LoongArch).

Drop the obsolete enabler and the bindgen invocation that selects it.
On this rust-next base, median warm make prepare time fell from 0.72 s
to 0.49 s over ten runs per version on x86-64 with GCC 16.2.1, libclang
23.1.5 and bindgen 0.73.2. For both GCC and Clang, the generated kernel,
helper and UAPI bindings matched byte for byte before and after the
change.

Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
OpenAI Codex assisted with coding and testing.
---
 rust/Makefile | 14 --------------
 1 file changed, 14 deletions(-)

diff --git a/rust/Makefile b/rust/Makefile
index 6dceabbf02c87..66b06ad6f11df 100644
--- a/rust/Makefile
+++ b/rust/Makefile
@@ -483,20 +483,6 @@ BINDGEN_TARGET		:= $(BINDGEN_TARGET_$(SRCARCH))
 # some configurations, with new GCC versions, etc.
 bindgen_extra_c_flags = -w --target=$(BINDGEN_TARGET)
 
-# Auto variable zero-initialization requires an additional special option with
-# clang that is going to be removed sometime in the future (likely in
-# clang-18), so make sure to pass this option only if clang supports it
-# (libclang major version < 16).
-#
-# https://github.com/llvm/llvm-project/issues/44842
-# https://github.com/llvm/llvm-project/blob/llvmorg-16.0.0-rc2/clang/docs/ReleaseNotes.rst#deprecated-compiler-flags
-ifdef CONFIG_INIT_STACK_ALL_ZERO
-libclang_maj_ver=$(shell $(BINDGEN) $(srctree)/scripts/rust_is_available_bindgen_libclang.h 2>&1 | sed -ne 's/.*clang version \([0-9]*\).*/\1/p')
-ifeq ($(shell expr $(libclang_maj_ver) \< 16), 1)
-bindgen_extra_c_flags += -enable-trivial-auto-var-init-zero-knowing-it-will-be-removed-from-clang
-endif
-endif
-
 bindgen_c_flags = $(filter-out $(bindgen_skip_c_flags), $(c_flags)) \
 	$(bindgen_extra_c_flags)
 endif

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261125-perf-rust-bindgen-drop-legacy-clang-149a05cc71a9

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

