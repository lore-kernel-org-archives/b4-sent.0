From: Younes Akhouayri <git@younes.io>
Date: Sat, 07 Nov 2026 17:36:24 +0100
Subject: [PATCH v2] rust: doctest: fix line numbers after crate-level
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-rust-doctest-line-fix-v2-1-a66528f0a7c3@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNTQ6CMBCFr2Jm7Zi2hIquvIdhAWWQMaY1nUIkh
 Ltb8ACuXr6X97OAUGQSuB4WiDSxcPAZzPEAbmj8g5C7zGCUsVqZM8ZREnbBJcr6Yk/Y8wddq3p
 rC2suPUHuviNle9+91z+WsX2SS9vYlhhYUojzfjzpLffvY9KoUTld6Kpsyqq1tzmMnuTEAep1X
 b+sd//FzAAAAA==
X-Change-ID: 20261027-rust-doctest-line-fix-cb0f663629fe
To: Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Brendan Higgins <brendan.higgins@linux.dev>, David Gow <david@davidgow.net>, 
 Rae Moar <raemoar63@gmail.com>, Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kselftest@vger.kernel.org, kunit-dev@googlegroups.com, 
 rust-for-linux@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794069397; l=4560;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=yODJlg7TFm3NgQtApP8hmB9DSotdMjoacbgECuGShSc=;
 b=GimVZfWmQy4O6IvvPp1BMLOsh1yM/b+aIA2FtrbbAIuG9go4rlPd59FrXAspFvU34qwCphMrj
 UA9Jr3BPOz6CrGcURhEnX7EGZNZVaUbc7MDm0l/uNojhOSX39dS2X7W
X-Developer-Key: i=git@younes.io; a=ed25519;
 pk=TavwxGPDBjl4XGNQyFLKEW7PKSY4qOWusc7yf6hjV0c=
X-Endpoint-Received: by B4 Relay for git@younes.io/20261027 with auth_id=1332
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a doctest starts with a crate-level attribute such as
`#![expect(...)]`, KUnit reports failures one line too early, and
`line!()` returns a line number that is one too low.

This happens because `rustdoc` moves those attribute lines out of the
test body and puts them above the `main` function it generates. The
generator works out where the body starts by counting the lines above
`main`, but it does not know that some of those lines were moved there
from the body. So every line after a moved attribute is mapped one line
too early (or more, if there are several such attributes).

For example, adding `assert_eq!(36, 0);` as line 36 of
`rust/kernel/init.rs` (inside the doctest that starts with
`# #![expect(clippy::undocumented_unsafe_blocks)]`) gives:

    # rust_doctest_kernel_init_rs_2: ASSERTION FAILED at rust/kernel/init.rs:35

Twelve in-tree doctests start like this, e.g. in `bits.rs`, `devres.rs`,
`init.rs` and `std_vendor.rs`.

Fix it by counting the attribute lines that `rustdoc` moved (every
`#![...]` line above `main`, except the `#![allow(unused)]` that
`rustdoc` adds itself) and taking them into account when computing
where the body starts.

`rustdoc` always starts its output with that `#![allow(unused)]`, so
check for it before relying on the layout. If a future `rustdoc` (or a
crate-level `#![doc(test(attr(...)))]`) changes it, print a warning once
and keep the previous behaviour rather than failing the build: the tests
still run, only the reported line numbers would be off.

Only single-line attributes are handled, which covers every doctest in
the tree today.

With this change, the example above reports `rust/kernel/init.rs:36`,
and doctests without such attributes keep reporting the same lines as
before.

Fixes: a66d733da801 ("rust: support running Rust documentation tests as KUnit ones")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
Changes in v2:
- Check that the generated test starts with `#![allow(unused)]` before
  subtracting the moved lines; otherwise warn once and keep the old
  behaviour, instead of clamping with `saturating_sub` (Miguel).
- Note in the comment and commit message that only single-line
  attributes are handled.
- Link to v1: https://patch.msgid.link/20261027-rust-doctest-line-fix-v1-1-0c13185a58b6@younes.io
---
 scripts/rustdoc_test_gen.rs | 28 ++++++++++++++++++++++++++++
 1 file changed, 28 insertions(+)

diff --git a/scripts/rustdoc_test_gen.rs b/scripts/rustdoc_test_gen.rs
index 754c5aafcce4..01128d8c62f9 100644
--- a/scripts/rustdoc_test_gen.rs
+++ b/scripts/rustdoc_test_gen.rs
@@ -127,6 +127,7 @@ fn main() {
 
     let mut tests = String::new();
     let mut body = String::new();
+    let mut warned = false;
     let mut last_file = String::new();
     let mut number = 0;
     let mut valid_paths: Vec<PathBuf> = Vec::new();
@@ -168,6 +169,33 @@ fn main() {
             .count()
             + 1;
 
+        // `rustdoc` moves the crate-level attributes (`#![...]`) of the test out of its body and
+        // places them before `main`, after its own `#![allow(unused)]`. Subtract the moved lines,
+        // since the rest of the body is shifted by that amount with respect to the original source.
+        //
+        // Only single-line attributes are handled. If `rustdoc` stops starting its output with
+        // `#![allow(unused)]`, this computation needs to be revisited, so warn (once) rather than
+        // silently reporting wrong line numbers, but keep going since the tests themselves still
+        // work.
+        let hoisted_lines = if body.starts_with("#![allow(unused)]\n") {
+            body.lines()
+                .take(body_offset - 1)
+                .filter(|line| line.starts_with("#!["))
+                .count()
+                - 1
+        } else {
+            if !warned {
+                eprintln!(
+                    "warning: `{name}` does not start with `#![allow(unused)]`: line numbers \
+                    reported by doctests may be wrong, please update \
+                    `scripts/rustdoc_test_gen.rs`."
+                );
+                warned = true;
+            }
+            0
+        };
+        let body_offset = body_offset - hoisted_lines;
+
         use std::fmt::Write;
         write!(
             tests,

---
base-commit: 21a7f44fd0765fcc5194130b28767786eba1d1e7
change-id: 20261027-rust-doctest-line-fix-cb0f663629fe

Best regards,
--  
Younes Akhouayri <git@younes.io>

