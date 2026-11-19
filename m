From: Peder Bergan <peder.bergan@gmail.com>
Date: Thu, 19 Nov 2026 11:19:28 +0100
Subject: [PATCH v2] rust: kbuild: generate a symbol version for
 rust_build_error
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-fix-rust-build-error-modversions-v2-1-1c2271cbcab5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAC/N/moC/5WOTQ6CMBCFr2K6dpQWBXXlPYyLtgxQQymZKQRju
 LsUT+Dye3l/H8FIDlncdh9BODl2oV9B7XfCtrpvEFy1slCZKqSUF6jdDDRyBDO6rgIkCgQ+VBN
 SyjKcdH3Oz1jZq1FirRkI18w28Xj+mEfzQhtTb3IYzQiGdG/bJI0DR0Ltj9tMj3NMptZxDPTej
 k4ylf3xaZIgobQyU3lZnOo8uzdeu+5ggxfPZVm+bFXCkgcBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795083567; l=2248;
 i=peder.bergan@gmail.com; s=kernel-contributions; h=from:subject:message-id;
 bh=dbbgO3cdXEYZnqxuqEQFpr48GQcdzVFtPCT9yziI+74=;
 b=tae+5P4ETQ7tXxOEyLVULdo6qfYAyHFcHGGYHK8B2HaCV+oz05eO5UPy0B9Ijz6zN869I5j52
 3/d3NVa5wfmAJb0zYT6QHK8/qAQl1vfSpqWRqT+A3M6W+sT3zEX4/a9
X-Developer-Key: i=peder.bergan@gmail.com; a=ed25519;
 pk=39790pn1YZCulHBoUG1uiQI1Hm01EvhBEa2zVrS/yN0=
X-Endpoint-Received: by B4 Relay for peder.bergan@gmail.com/kernel-contributions with auth_id=1395
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CONFIG_RUST_BUILD_ASSERT_ALLOW exports rust_build_error to modules.
When CONFIG_MODVERSIONS is also enabled, modpost warns that the export
has no symbol version and records a zero CRC because the build_error.o
rule skips gendwarfksyms.

Let the existing Rust library rule run gendwarfksyms for build_error.o
so modpost gets a version calculated from the Rust definition.

Fixes: ac61506bf2d1 ("rust: Use gendwarfksyms + extended modversions for CONFIG_MODVERSIONS")
Reported-by: Gwan-gyeong Mun <gwan-gyeong.mun@intel.com>
Closes: https://github.com/Rust-for-Linux/linux/issues/1201
Signed-off-by: Peder Bergan <peder.bergan@gmail.com>
---
A clean x86-64 build with Clippy enabled generated the same nonzero CRC
for the kernel export and an external Rust module that references it.
An output tree built before this patch can reuse rust/build_error.o
without generating the CRC. Rebuild that object before relinking.
External modules built with the old CRC for rust_build_error also need
rebuilding against the corrected kernel.

OpenAI Codex assisted with coding and testing.
---
Changes in v2:
- Drop the rust/Makefile prerequisite after Gary's review.
- Omit Sami's v1 Reviewed-by because v2 changes incremental rebuild behavior.
- Link to v1: https://lore.kernel.org/rust-for-linux/20261118-fix-rust-build-error-modversions-v1-1-7c1023764f30@gmail.com/
---
 rust/Makefile | 1 -
 1 file changed, 1 deletion(-)

diff --git a/rust/Makefile b/rust/Makefile
index 0165626decbe..189c5cbdf44f 100644
--- a/rust/Makefile
+++ b/rust/Makefile
@@ -773,7 +773,6 @@ $(obj)/pin_init.o: $(src)/pin-init/src/lib.rs $(obj)/compiler_builtins.o \
 # treated as such so that we pass the same flags. Otherwise, for instance,
 # `rustc` will complain about missing sanitizer flags causing an ABI mismatch.
 $(obj)/build_error.o: private is-kernel-object := y
-$(obj)/build_error.o: private skip_gendwarfksyms = 1
 $(obj)/build_error.o: $(src)/build_error.rs $(obj)/compiler_builtins.o FORCE
 	+$(call if_changed_rule,rustc_library)
 

---
base-commit: aebb7274476403040d582c61478df8f4a7bf9cd3
change-id: 20261118-fix-rust-build-error-modversions-4af535edc9b2

Best regards,
--  
Peder Bergan <peder.bergan@gmail.com>

