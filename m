From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Subject: [PATCH v2 0/3] rust: kunit: support #[should_panic] and same test
 name with different #[cfg(...)]
Date: Thu, 29 Oct 2026 13:59:00 -0300
Message-Id: <20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAFR742oC/x3MQQqAIBBA0avErBPUSKirREjoVENgMVMRSHdPW
 r7F/xkEmVCgrzIw3iS0pwJbVxDWKS2oKBaD1dYZbTvFl5x+uxKd/nZeMEUVddM2wTjTzh2U8GC
 c6fmnw/i+H03elpBkAAAA
X-Change-ID: 20261029-rust_kunit_v6_send-d0353c1615f9
To: Alice Ryhl <aliceryhl@google.com>, Benno Lossin <lossin@kernel.org>, 
 Boqun Feng <boqun@kernel.org>, Brendan Higgins <brendan.higgins@linux.dev>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Danilo Krummrich <dakr@kernel.org>, David Gow <david@davidgow.net>, 
 Gary Guo <gary@garyguo.net>, Miguel Ojeda <ojeda@kernel.org>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>
Cc: Alexandre Courbot <acourbot@nvidia.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Burak Emir <burak.emir@gmail.com>, Rae Moar <raemoar63@gmail.com>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 Yury Norov <yury.norov@gmail.com>, kunit-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, 
 =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5381;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=qbLPq7lD1HdTSfI9ix8eOoU9492wccTuMFu99cmlC/g=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9bj6uaWjphP06byffzN93TVjpLm5rcFvJV+na3lsz1/h
 u8VFJPtKGVhEONikBVTZJnL+f6zsa15Rbn0piCYOaxMIEMYuDgFYCJpBYwMu9JyemMO5Oo+feyQ
 f/i8VV1zcpqtmMvsk3/f/zjNoPmqheE3G6NjiyDPd2kBoxzTFQWT1875paOZ69jUeTi+o9p7Vxk
 PAA==
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series intends to implement two features for KUnit tests
written in Rust. The work is based on a TODO comment made in the
`bitmap.rs` module [1].

Changelog:

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
  a test that was expected to panic do not
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
  side (`kunit_run_case_catch_errors` function). This allow to catch
  panics triggered, for example in a Rust function that called a panicking
  C function.
- Now the tests that have an inactive #[cfg(..)] do not appear un the
  KUnit execution summary as ignored, they just do not run.
Link to v1: https://lore.kernel.org/all/20260930-rust_kunit_v4-v1-0-e3b0d45311dd@gmail.com/

- RFC patch: https://lore.kernel.org/rust-for-linux/cover.1789500084.git.nico.antinori.7@gmail.com/

1. Supporting `#[should_panic]` [2]:

KUnit tests in Rust follow the user-space syntax, but at the moment
`#[should_panic]` is not supported. The first patch of this series adds
support for the attribute (only in its basic form, `#[should_panic =
"message"]` is not supported yet).

The way it is supported is by adding a new boolean property called
`rust_should_panic` to `kunit_attributes` struct in kunit/test.h and in
`kunit_attributes` in kunit/try-catch.h and check for the
`try_catch->try_result` code and the named flag to detect if there was a
panic in `kunit_try_catch_run` function.

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

 include/kunit/test.h       |  1 +
 include/kunit/try-catch.h  |  3 ++
 lib/kunit/attributes.c     | 18 ++++++++++++
 lib/kunit/kunit-test.c     |  3 ++
 lib/kunit/test.c           |  2 ++
 lib/kunit/try-catch-impl.h |  2 ++
 lib/kunit/try-catch.c      | 14 +++++----
 rust/kernel/bitmap.rs      | 21 +++++++------
 rust/kernel/kunit.rs       | 73 ++++++++++++++++++++++++++++++++++++++++++++--
 rust/macros/kunit.rs       | 67 +++++++++++++++++++++++++++++-------------
 10 files changed, 164 insertions(+), 40 deletions(-)
---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261029-rust_kunit_v6_send-d0353c1615f9

Best regards,
-- 
Nicolás Antinori <nico.antinori.7@gmail.com>

