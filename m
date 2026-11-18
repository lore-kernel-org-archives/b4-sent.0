From: Peder Bergan <peder.bergan@gmail.com>
Date: Wed, 18 Nov 2026 10:08:50 +0100
Subject: [PATCH] rust: kbuild: generate a symbol version for
 rust_build_error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-fix-rust-build-error-modversions-v1-1-7c1023764f30@gmail.com>
X-B4-Tracking: v=1; b=H4sIACFr/WoC/yWN2w6CMBBEf4XssxttFaP+ivGhl0VqpJDdlpAQ/
 t0WH89kzswKQhxI4NGswDQHCWMsoA4NuN7EN2HwhUGf9FUpdcMuLMhZEtocvh6JeWQcRj8TV1f
 wYrr23JJ3d6uhzExMxdkvnq8/S7Yfcqnu1oY1QmjZRNfXKE+SmMxw3G8iLQm27QeUqHuzqQAAA
 A==
X-Change-ID: 20261118-fix-rust-build-error-modversions-4af535edc9b2
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
 Nathan Chancellor <nathan@kernel.org>, Nicolas Schier <nsc@kernel.org>, 
 Sami Tolvanen <samitolvanen@google.com>, 
 Matthew Maurer <mmaurer@google.com>, Masahiro Yamada <masahiroy@kernel.org>, 
 Gwan-gyeong Mun <gwan-gyeong.mun@intel.com>, rust-for-linux@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kbuild@vger.kernel.org, 
 linux-modules@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794992929; l=2134;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=iwv1qR5QyWs5FUrFMluYyHlgGOi5NpHY1vMGZeZUJRU=;
 b=NwD6BfBA4WLob4JLWPSWapwm4CZS3A7yc5jvskFd0xanhimNfBdKYJ6oPbN3P2DqnFUHqZ/RS
 z4EPoyo3A7EC6m2QxLn1urUhN9JCBklyXWBl1CvPG6Yij6lqo4TXdgd
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONFIG_RUST_BUILD_ASSERT_ALLOW exports rust_build_error to modules.
When CONFIG_MODVERSIONS is also enabled, modpost warns that the export
has no symbol version and records a zero CRC because the build_error.o
rule skips gendwarfksyms.

Generate the checksum from build_error.o with the existing Rust library
rule. Make build_error.o depend on rust/Makefile when module versioning
is enabled so incremental builds pick up the change. Kbuild's saved
rustc command does not include the gendwarfksyms step.

Fixes: ac61506bf2d1 ("rust: Use gendwarfksyms + extended modversions for CONFIG_MODVERSIONS")
Reported-by: Gwan-gyeong Mun <gwan-gyeong.mun@intel.com>
Closes: https://github.com/Rust-for-Linux/linux/issues/1201
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
An incremental x86-64 build with LLVM=1 CLIPPY=1 clears the modpost
warning. The kernel export and a Rust module that references it both
record the same nonzero CRC.

OpenAI Codex assisted with coding and testing.
---
 rust/Makefile | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/rust/Makefile b/rust/Makefile
index 0165626decbe..dd5b0a958d0c 100644
--- a/rust/Makefile
+++ b/rust/Makefile
@@ -773,8 +773,9 @@ $(obj)/pin_init.o: $(src)/pin-init/src/lib.rs $(obj)/compiler_builtins.o \
 # treated as such so that we pass the same flags. Otherwise, for instance,
 # `rustc` will complain about missing sanitizer flags causing an ABI mismatch.
 $(obj)/build_error.o: private is-kernel-object := y
-$(obj)/build_error.o: private skip_gendwarfksyms = 1
-$(obj)/build_error.o: $(src)/build_error.rs $(obj)/compiler_builtins.o FORCE
+# Rebuild when the symbol version generation rule changes.
+$(obj)/build_error.o: $(src)/build_error.rs $(obj)/compiler_builtins.o \
+    $(if $(CONFIG_MODVERSIONS),$(src)/Makefile) FORCE
 	+$(call if_changed_rule,rustc_library)
 
 $(obj)/ffi.o: private skip_gendwarfksyms = 1

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-fix-rust-build-error-modversions-4af535edc9b2

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

