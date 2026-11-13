From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Subject: [PATCH v3 0/3] rust: kunit: support #[should_panic] and same test
 name with different #[cfg(...)]
Date: Fri, 13 Nov 2026 15:20:54 -0300
Message-Id: <20261113-rust_kunit_v6_send-v3-0-0d7832c07166@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAZV92oC/32NWw6CMBBFt0Lm25o+LBG/3IchhLRTmCiFtKXRE
 PZuZQF+npPcczeIGAgj3KoNAmaKNPsC6lSBGXs/ICNbGCSXteCyYWGNqXuunlKX6y6it8xypZU
 RtdCugTJcAjp6H9FHW3ikmObwOT6y/Nm/uSwZZ9qg1gKduVzxPkw9vc5mnqDd9/0LZr8L7bQAA
 AA=
X-Change-ID: 20261029-rust_kunit_v6_send-d0353c1615f9
To: Alice Ryhl <aliceryhl@google.com>, Benno Lossin <lossin@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Brendan Higgins <brendan.higgins@linux.dev>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Danilo Krummrich <dakr@kernel.org>, David Gow <david@davidgow.net>, 
 Gary Guo <gary@garyguo.net>, Miguel Ojeda <ojeda@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Shuah Khan <skhan@linuxfoundation.org>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Burak Emir <burak.emir@gmail.com>, Rae Moar <raemoar63@gmail.com>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 Yury Norov <yury.norov@gmail.com>, kunit-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-doc@vger.kernel.org, 
 =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=7645;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=zmw4ZEYxMtkU8oSXCrqD6/tR6BnBwHq4KByl9D8pjP8=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9b3ULMtAmmcPksmP9aPnz3bNd93S6ZUmvb9OK1sE/nZP
 z4/Yy/vKGVhEONikBVTZJnL+f6zsa15Rbn0piCYOaxMIEMYuDgFYCJXaxn+1/vP370+01QmNEvc
 a+Lsu/Iad7+xv7sR1FHEkv322Sx5PYb/+ZfUhP8ELDPZvfJQwGzbbImwhoSKu0KXGdsPOR+uYOH
 jBAA=
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series intends to implement two features for KUnit tests
written in Rust. The work is based on a TODO comment made in the
`bitmap.rs` module [1].

Changelog:

v3:

Gone back to the `#[panic_handler]` implementation (original idea from
RFC Patch), after discussing it in the v2 patch thread. This means that
`#[should_panic]` will catch Rust panics only.

The changes are:
- `#[should_panic]` introduction patch (patch 1):
  - Handling panics through a `#[panic_handler]` in
    `rust/kernel/lib.rs`.
  - Added a `kunit_attributes` pointer to the `kunit` struct to be able
    to read the test attributes from the panic handler in Rust.
  - Modified `kunit_init_test` to fill the `kunit_attributes` pointer
    inside the `kunit` struct.
  - Using `extract_if` for detecting `should_panic` attribute instead of
    just checking that it is there.
  - Explicitly using `kunit_assert!` in `macros/kunit.rs`, because now
    the macro overwrite is done inside the function body.
  - Fixed KUnit test initialization in `lib/kunit/kunit-test.c`,
    `lib/kunit/platform-test.c`, `lib/kunit/string-stream-test.c` and
    `drivers/of/overlay_test.c` (passed `kunit_attributes`)
  - Rolled back `kunit_assert!` and `kunit_assert_eq!` modifications
    from v2.
  - Rolled back adding `rust_should_panic` property to `kunit_try_catch`
    C struct
  - Removed test case that called BUG() C binding directly within the
    test.
  - Added `#[should_panic]` to documentation.

- bitmap.rs test (patch 3)
  - Solved some nits pointed out by Miguel.

- General:
  - Carried all Reviewed-by from v2 for patch 2 (this patch did not
    change)
  - Carried Acked-by and Reviewed-by from v2 for patch 3 (changes are
    not functional)

Note: Now that we are using the `#[panic_handler]` I have a draft
implementation of `#[should_panic = "message"]` support, but I think
it'd be better to send it as a separate patch once this is merged to
not add noise to the review of this (the affected patch is the first
one).

Note: I was not sure whether to add the attributes assignment to
`kunit_init_test`, as it is a public function and doing so required
changing its signature to accept an attributes pointer argument. Is this
the right place to do it?

Link to v2: https://lore.kernel.org/rust-for-linux/20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com/

v2:
- Added more tests in `rust/kernel/kunit.rs` testing Sashiko findings
  and changes.
- Solved Sashiko: "[Low] kunit: spurious "try faulted" error logs for
  successful #[should_panic] tests": Solved by adding
  `rust_should_panic` in `kunit_try_catch` C struct to check if the test
  is expected to panic and act accordingly. Dismissed what I first talked
  about in [3].
- Solved Sashiko: "[Medium] kunit: assert! macro in #[should_panic]
  tests causes unexpected failure": Solved by making `kunit_assert`
  macro aware if the test should panic and act accordingly. Dismissed what
  I first talked about in [3]
- Solved Sashiko: "[Low] kunit: missing diagnostic log for
  #[should_panic] tests that fail to panic": Added an error message when
  a test that was expected to panic does not.
- Solved Sashiko: "[Low] kunit: dead_code error for test wrappers with
  inactive cfg": Solved by moving the #[cfg(..)] attributes on top of
  the wrapper functions
- Dismissed Sashiko: "[Medium] rust: bitmap: memory leak in
  owned_bitmap_out_of_bounds() test panic": Not sure if can be done
  anything. If I am not mistaken this is the same issue as stated here [4].

Sashiko report links: https://sashiko.dev/#/patchset/20260930-rust_kunit_v4-v1-0-e3b0d45311dd@gmail.com?part=1

v1:
- Removed 'stringification' of test names (to avoid clash of names for
  different configurations now a number is appended).
- Added bool `rust_should_panic` attribute to `kunit_attributes` C
  struct
- Removed #[panic_handler] in Rust side, checking for aborts in the C
  side (`kunit_run_case_catch_errors` function). This allows to catch
  panics triggered, for example in a Rust function that called a panicking
  C function.
- Now the tests that have an inactive #[cfg(..)] do not appear in the
  KUnit execution summary as ignored, they just do not run.
Link to v1: https://lore.kernel.org/all/20260930-rust_kunit_v4-v1-0-e3b0d45311dd@gmail.com/

- RFC patch: https://lore.kernel.org/rust-for-linux/cover.1789500084.git.nico.antinori.7@gmail.com/

1. Supporting `#[should_panic]` [2]:

KUnit tests in Rust follow the user-space syntax, but at the moment
`#[should_panic]` is not supported. The first patch of this series adds
support for the attribute (only in its basic form, `#[should_panic =
"message"]` is not supported yet).

The way it is supported is by adding a new boolean property called
`rust_should_panic` to `kunit_attributes` struct in kunit/test.h and
check in the `#[panic_handler]` whether the test was supposed to panic
or not.

2. Allow same test name with different #[cfg(...)]:

When testing `#[should_panic]` in `bitmap.rs` (check the last patch of
the series) I found that the test that was supposed to panic had the
same name as another one, but they were run on different configurations.
This caused the following compilation error:

ERROR:root:error[E0428]: the name `kunit_rust_wrapper_owned_bitmap_out_of_bounds` is defined multiple times
   --> ../rust/kernel/bitmap.rs:503:1
    |
503 | #[macros::kunit_tests(rust_kernel_bitmap)]
    | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `kunit_rust_wrapper_owned_bitmap_out_of_bounds` redefined here
    |
    = note: `kunit_rust_wrapper_owned_bitmap_out_of_bounds` must be defined only once in the value namespace of this module
    = note: this error originates in the attribute macro `macros::kunit_tests` (in Nightly builds, run with -Z macro-backtrace for more info)

Now, only the tests with an active `#[cfg(...)]` will be executed by the
runner. Tests with an inactive `#[cfg(...)]` will not appear in the
report since they are not added to the TEST_CASES array.

[1] https://github.com/Rust-for-Linux/linux/blob/fd73f4a6659897191fa0d40695fe370925dd3780/rust/kernel/bitmap.rs#L592-L600
[2] https://doc.rust-lang.org/rust-by-example/testing/unit_testing.html#testing-panics
[3] https://lore.kernel.org/all/DM41PHVITKOG.3I6P2X8048BEP@gmail.com/
[4] https://github.com/Rust-for-Linux/linux/blob/fd73f4a6659897191fa0d40695fe370925dd3780/rust/kernel/kunit.rs#L129-L136

Signed-off-by: Nicolás Antinori <nico.antinori.7@gmail.com>
---
Nicolás Antinori (3):
      rust: kunit: add #[should_panic] support
      rust: kunit: allow same test name with different #[cfg(...)]
      rust: bitmap: kunit: uncomment owned_bitmap_out_of_bounds panic case

 Documentation/rust/testing.rst |   8 ++-
 drivers/of/overlay_test.c      |   6 ++-
 include/kunit/test.h           |   9 +++-
 lib/kunit/attributes.c         |  18 +++++++
 lib/kunit/kunit-test.c         |  36 +++++++++++---
 lib/kunit/platform-test.c      |   6 ++-
 lib/kunit/string-stream-test.c |   9 +++-
 lib/kunit/test.c               |  10 ++--
 rust/kernel/bitmap.rs          |  18 +++----
 rust/kernel/kunit.rs           |  54 ++++++++++++++++++++
 rust/kernel/lib.rs             |  43 +++++++++++++++-
 rust/macros/kunit.rs           | 109 +++++++++++++++++++++++++++--------------
 12 files changed, 264 insertions(+), 62 deletions(-)
---
base-commit: ee83899302a0457a3ba47464a13e8682bd7ba27d
change-id: 20261029-rust_kunit_v6_send-d0353c1615f9

Best regards,
-- 
Nicolás Antinori <nico.antinori.7@gmail.com>

