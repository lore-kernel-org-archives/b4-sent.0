From: Younes Akhouayri <git@younes.io>
Date: Tue, 27 Oct 2026 07:31:58 +0100
Subject: [PATCH] rust: doctest: fix line numbers after crate-level
 attributes
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-rust-doctest-line-fix-v1-1-0c13185a58b6@younes.io>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM0QrCMBAEf6XcswdpCin6K+KDTTf2RFLJpaVQ+
 u+e+rTMwsxOiiJQujQ7FayiMmeD9tRQnO75AZbRmLzzoXW+57Jo5XGOFbYvyeAkG8fBpRC64M8
 JZO67wO5f93r7sy7DE7F+Y3QcH39dKBd5AAAA
X-Change-ID: 20261027-rust-doctest-line-fix-cb0f663629fe
To: Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>, Rae Moar <raemoar63@gmail.com>, 
 Miguel Ojeda <ojeda@kernel.org>, Boqun Feng <boqun@kernel.org>, 
 Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <lossin@kernel.org>, Andreas Hindborg <a.hindborg@kernel.org>, 
 Alice Ryhl <aliceryhl@google.com>, Trevor Gross <tmgross@umich.edu>, 
 Danilo Krummrich <dakr@kernel.org>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Tamir Duberstein <tamird@kernel.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: rust-for-linux@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-kernel@vger.kernel.org, 
 Younes Akhouayri <git@younes.io>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793082718; l=2652;
 i=git@younes.io; s=20261027; h=from:subject:message-id;
 bh=ZibAN+j218M4v6xGY3Uc7Usec6aRaCACBYkqr0vExUE=;
 b=nRS2HXLSCcZDH+gtG/ijx+UjOUZy/v7h2EtBHqsRdWpcHtedueiNyv3iKNcZRZHGkqkYyhkFm
 SF0fXLhRw+JB5s5OXbntEKAIan/1w+l+QGDt7BeIybka7jQf13q9Vez
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

With this change, the example above reports `rust/kernel/init.rs:36`,
and doctests without such attributes keep reporting the same lines as
before.

Fixes: a66d733da801 ("rust: support running Rust documentation tests as KUnit ones")
Signed-off-by: Younes Akhouayri <git@younes.io>
---
 scripts/rustdoc_test_gen.rs | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/scripts/rustdoc_test_gen.rs b/scripts/rustdoc_test_gen.rs
index 754c5aafcce4..c821ec63c32d 100644
--- a/scripts/rustdoc_test_gen.rs
+++ b/scripts/rustdoc_test_gen.rs
@@ -168,6 +168,17 @@ fn main() {
             .count()
             + 1;
 
+        // `rustdoc` moves the crate-level attributes (`#![...]`) of the test out of its body and
+        // places them before `main`, after its own `#![allow(unused)]`. Subtract the moved lines,
+        // since the rest of the body is shifted by that amount with respect to the original source.
+        let hoisted_lines = body
+            .lines()
+            .take(body_offset - 1)
+            .filter(|line| line.starts_with("#!["))
+            .count()
+            .saturating_sub(1);
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

