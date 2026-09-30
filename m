From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Wed, 30 Sep 2026 10:23:29 -0300
Subject: [PATCH 2/3] rust: kunit: allow same test name with different
 #[cfg(...)]
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260930-rust_kunit_v4-v1-2-e3b0d45311dd@gmail.com>
References: <20260930-rust_kunit_v4-v1-0-e3b0d45311dd@gmail.com>
In-Reply-To: <20260930-rust_kunit_v4-v1-0-e3b0d45311dd@gmail.com>
To: Alice Ryhl <aliceryhl@google.com>, Burak Emir <burak.emir@gmail.com>, 
 Brendan Higgins <brendan.higgins@linux.dev>, David Gow <david@davidgow.net>, 
 Miguel Ojeda <ojeda@kernel.org>
Cc: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>, 
 Alexandre Courbot <acourbot@nvidia.com>, 
 Andreas Hindborg <a.hindborg@kernel.org>, Benno Lossin <lossin@kernel.org>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn1_gh@protonmail.com>, 
 Boqun Feng <boqun@kernel.org>, Brigham Campbell <me@brighamcampbell.com>, 
 Daniel Almeida <daniel.almeida@collabora.com>, 
 Danilo Krummrich <dakr@kernel.org>, Gary Guo <gary@garyguo.net>, 
 Jori Koolstra <jkoolstra@xs4all.nl>, 
 =?utf-8?q?Onur_=C3=96zkan?= <work@onurozkan.dev>, 
 Rae Moar <raemoar63@gmail.com>, Shuah Khan <skhan@linuxfoundation.org>, 
 Tamir Duberstein <tamird@kernel.org>, Trevor Gross <tmgross@umich.edu>, 
 Yury Norov <yury.norov@gmail.com>, linux-kernel@vger.kernel.org, 
 rust-for-linux@vger.kernel.org, linux-kernel-mentees@lists.linux.dev
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3972;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=gqKKuAOLxDKy392fHljpb4t4v5urh7WAzgomKGObknI=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9Ze3uQ/Nx882Lr9fnTjLlWRWR7rDj1mi9QTXl1W8E/wq
 75f9W+fjlIWBjEuBlkxRZa5nO8/G9uaV5RLbwqCmcPKBDKEgYtTACbyIJGR4QCrusChWv2bVm4N
 E6NC3k3OyPv4/5p76KV7u7JtOFOfyTEyPD31N9v0yK/sL+b2nCeyQl7IdTSfmmTrc1rC78ybWSX
 3OAA=
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sometimes it is necessary to test the same code paths under different
configurations. The `#[cfg(...)]` macro can be used to check if specific
configurations are enabled and run tests accordingly.

Currently, defining multiple tests with the same name under different
`#[cfg(...)]` attributes results in a compilation error. This patch
removes that restriction, allowing identical test names across different
configurations.

Signed-off-by: Nicolás Antinori <nico.antinori.7@gmail.com>
---
 rust/kernel/kunit.rs | 22 ++++++++++++++++++++++
 rust/macros/kunit.rs | 20 +++++++++++++++-----
 2 files changed, 37 insertions(+), 5 deletions(-)

diff --git a/rust/kernel/kunit.rs b/rust/kernel/kunit.rs
index 5fa4d994e0f7ebf5bbe5fd3571a372548cc8499b..5ff988ab76a408751d1f57b59cc82a79c6c2534a 100644
--- a/rust/kernel/kunit.rs
+++ b/rust/kernel/kunit.rs
@@ -347,6 +347,28 @@ fn rust_test_kunit_in_kunit_test() {
         assert!(in_kunit_test());
     }
 
+    // Tests with cfg have the same name on purpose because we are implicitly testing that
+    // tests with the same name but different configs do not throw a compilation error
+    #[test]
+    #[cfg(CONFIG_RUST_KUNIT_SELFTEST = "y")]
+    fn rust_test_kunit_run_only_active_cfg() {
+        assert!(in_kunit_test());
+    }
+
+    #[test]
+    #[cfg(CONFIG_RUST_KUNIT_SELFTEST = "n")]
+    fn rust_test_kunit_run_only_active_cfg() {
+        // This test should never run because of the `cfg`.
+        assert!(false)
+    }
+
+    #[test]
+    #[cfg(CONFIG_RUST_KUNIT_SELFTEST = "INVALID_VALUE")]
+    fn rust_test_kunit_run_only_active_cfg() {
+        // This test should never run because of the `cfg`.
+        assert!(false)
+    }
+
     #[test]
     #[should_panic]
     fn rust_test_kunit_panic_in_kunit_test() {
diff --git a/rust/macros/kunit.rs b/rust/macros/kunit.rs
index f1d0210e6a49468876d69821cc559002ad12da50..18cfa463c8dbaa216160a686b1cd6c144986568c 100644
--- a/rust/macros/kunit.rs
+++ b/rust/macros/kunit.rs
@@ -45,6 +45,8 @@ pub(crate) fn kunit_tests(test_suite: Ident, mut module: ItemMod) -> Result<Toke
 
     let mut processed_items = Vec::new();
     let mut test_cases = Vec::new();
+    let mut test_cases_cfgs = Vec::new();
+    let mut test_case_number: u32 = 1;
 
     // Generate the test KUnit test suite and a test case for each `#[test]`.
     //
@@ -135,7 +137,7 @@ macro_rules! assert_eq {
         // Add back the test item.
         processed_items.push(Item::Fn(f));
 
-        let kunit_wrapper_fn_name = format_ident!("kunit_rust_wrapper_{test}");
+        let kunit_wrapper_fn_name = format_ident!("kunit_rust_wrapper_{test}_{test_case_number}");
         let test_cstr = LitCStr::new(
             &CString::new(test_str.as_str()).expect("identifier cannot contain NUL"),
             test.span(),
@@ -172,15 +174,23 @@ macro_rules! assert_eq {
             case.attr.rust_should_panic = #should_panic;
             case
         }));
+        test_cases_cfgs.push(cfg_attrs);
+        test_case_number += 1;
     }
 
-    let num_tests_plus_1 = test_cases.len() + 1;
+    // This dummy array is used to calculate the exact number of tests cases that are active
+    // depending on their #[cfg(...)] attribute.
+    processed_items.push(parse_quote!(
+        const TEST_CASES_COUNT: &[()] = &[#(#(#test_cases_cfgs)* (),)* ()];
+    ));
+
     processed_items.push(parse_quote! {
-        static mut TEST_CASES: [::kernel::bindings::kunit_case; #num_tests_plus_1] = [
-            #(#test_cases,)*
-            ::pin_init::zeroed(),
+        static mut TEST_CASES: [::kernel::bindings::kunit_case; TEST_CASES_COUNT.len()] = [
+            #(#(#test_cases_cfgs)* { #test_cases },)*
+            ::pin_init::zeroed()
         ];
     });
+
     processed_items.push(parse_quote! {
         ::kernel::kunit_unsafe_test_suite!(#test_suite, TEST_CASES);
     });

-- 
2.47.3

