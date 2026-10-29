From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Thu, 29 Oct 2026 13:59:02 -0300
Subject: [PATCH v2 2/3] rust: kunit: allow same test name with different
 #[cfg(...)]
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261029-rust_kunit_v6_send-v2-2-5ce551efc48e@gmail.com>
References: <20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com>
In-Reply-To: <20261029-rust_kunit_v6_send-v2-0-5ce551efc48e@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=5079;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=zzc2fwAl7G0oF5NHbgAZSoqWvnfQ18grBJuQDw4KJ6o=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9bj6pZZTq5XXzhrVeUXqtR/NffM8tku2Mz4dUOp8Jb/r
 P9Y6hd3lLIwiHExyIopsszlfP/Z2Na8olx6UxDMHFYmkCEMXJwCMJEVDQx/uKe9Pn5Czrqk4oRM
 l9CP2ZMDizn4TgRNNBJyd+pNnvZrL8P/2IPR7bZLwtLuzSrsd3rNePBQ5M4J/o8v9lbtKggOZ3/
 JBQA=
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
 rust/macros/kunit.rs | 36 ++++++++++++++++++++----------------
 2 files changed, 42 insertions(+), 16 deletions(-)

diff --git a/rust/kernel/kunit.rs b/rust/kernel/kunit.rs
index 5e688b743ee2152867e2f99c7f18b86e1b7fbe3d..ba3040d302b95af6d6e648a229ac8e9ea2c31a8c 100644
--- a/rust/kernel/kunit.rs
+++ b/rust/kernel/kunit.rs
@@ -367,6 +367,28 @@ fn rust_test_kunit_in_kunit_test() {
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
index 288b53d21c4e7c8d9b5148d50c1a833f73e53015..173792563ca8b42e39ec0a53798f7b3bb75bf9cf 100644
--- a/rust/macros/kunit.rs
+++ b/rust/macros/kunit.rs
@@ -45,6 +45,8 @@ pub(crate) fn kunit_tests(test_suite: Ident, mut module: ItemMod) -> Result<Toke
 
     let mut processed_items = Vec::new();
     let mut test_cases = Vec::new();
+    let mut test_cases_cfgs = Vec::new();
+    let mut test_case_number: u32 = 1;
 
     // Generate the test KUnit test suite and a test case for each `#[test]`.
     //
@@ -134,7 +136,7 @@ macro_rules! assert_eq {
         // Add back the test item.
         processed_items.push(Item::Fn(f));
 
-        let kunit_wrapper_fn_name = format_ident!("kunit_rust_wrapper_{test}");
+        let kunit_wrapper_fn_name = format_ident!("kunit_rust_wrapper_{test}_{test_case_number}");
         let test_cstr = LitCStr::new(
             &CString::new(test_str.as_str()).expect("identifier cannot contain NUL"),
             test.span(),
@@ -154,18 +156,12 @@ macro_rules! assert_eq {
             )
         };
         processed_items.push(parse_quote! {
+            // Prepend any `cfg` attributes before the function declaration to activate it only in
+            // cases the configs are on
+            #(#cfg_attrs)*
             unsafe extern "C" fn #kunit_wrapper_fn_name(_test: *mut ::kernel::bindings::kunit) {
-                (*_test).status = ::kernel::bindings::kunit_status_KUNIT_SKIPPED;
-
-
-                // Append any `cfg` attributes the user might have written on their tests so we
-                // don't attempt to call them when they are `cfg`'d out. An extra `use` is used
-                // here to reduce the length of the assert message.
-                #(#cfg_attrs)*
-                {
-                    (*_test).status = ::kernel::bindings::kunit_status_KUNIT_SUCCESS;
-                    #assertion
-                }
+                (*_test).status = ::kernel::bindings::kunit_status_KUNIT_SUCCESS;
+                #assertion
             }
         });
 
@@ -174,15 +170,23 @@ macro_rules! assert_eq {
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

