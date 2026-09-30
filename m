From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Wed, 30 Sep 2026 10:23:28 -0300
Subject: [PATCH 1/3] rust: kunit: add #[should_panic] support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260930-rust_kunit_v4-v1-1-e3b0d45311dd@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=6762;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=EazFusqTGC0HqhIMNPi0/T3XN1RmJ6C7Vn4d5oVOuFc=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9Ze3uRJcbHPdbJTDhpZbLdYs+37kkd3XI705Ent7Yu6t
 p3L4VNtRykLgxgXg6yYIstczvefjW3NK8qlNwXBzGFlAhnCwMUpABM5zsXIsGH2/PtOfOUzgir7
 n297H1h7fmupQHXyzRWasm2dDn0e+xj+ijzPDs2IXWvsW2MYucq40sjmOru7+9kZwus+uEtp+Fd
 zAQA=
X-Developer-Key: i=nico.antinori.7@gmail.com; a=openpgp;
 fpr=9D09EFF3333D3778771BB252D0254F3848822532
X-Endpoint-Received: by B4 Relay for nico.antinori.7@gmail.com/default with auth_id=1086
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KUnit tests in Rust are written using user-space like syntax. This patch
adds support for the `#[should_panic]` attribute, enabling the user to
test conditions that are expected to cause a panic and report the test
as successful.

Signed-off-by: Nicolás Antinori <nico.antinori.7@gmail.com>
---
 include/kunit/test.h   |  1 +
 lib/kunit/attributes.c | 18 ++++++++++++++++++
 lib/kunit/test.c       |  5 +++++
 rust/kernel/kunit.rs   | 15 +++++++++++++++
 rust/macros/kunit.rs   | 28 +++++++++++++++++++++++-----
 5 files changed, 62 insertions(+), 5 deletions(-)

diff --git a/include/kunit/test.h b/include/kunit/test.h
index da5312e0dfa57f37a7e96c9e618b03b0947ede8b..f2c640718d12258c183817be08a091b8cf316d16 100644
--- a/include/kunit/test.h
+++ b/include/kunit/test.h
@@ -83,6 +83,7 @@ enum kunit_speed {
 /* Holds attributes for each test case and suite */
 struct kunit_attributes {
 	enum kunit_speed speed;
+	bool rust_should_panic;
 };
 
 /**
diff --git a/lib/kunit/attributes.c b/lib/kunit/attributes.c
index 6d7a53af94a9acf3cf336409462059b972efeb22..8a9dc526b3cb2d363d42087f8666a03e9bc2bc4b 100644
--- a/lib/kunit/attributes.c
+++ b/lib/kunit/attributes.c
@@ -246,6 +246,16 @@ static void *attr_is_init_get(void *test_or_suite, bool is_test)
 		return ((void *) suite->is_init);
 }
 
+static void *attr_rust_should_panic_get(void *test_or_suite, bool is_test)
+{
+	struct kunit_case *test = is_test ? test_or_suite : NULL;
+
+	if (test)
+		return ((void *) test->attr.rust_should_panic);
+	else
+		return ((void *) NULL);
+}
+
 /* List of all Test Attributes */
 
 static struct kunit_attr kunit_attr_list[] = {
@@ -272,6 +282,14 @@ static struct kunit_attr kunit_attr_list[] = {
 		.filter = attr_bool_filter,
 		.attr_default = (void *)false,
 		.print = PRINT_SUITE,
+	},
+	{
+		.name = "rust_should_panic",
+		.get_attr = attr_rust_should_panic_get,
+		.to_string = attr_bool_to_string,
+		.filter = attr_bool_filter,
+		.attr_default = (void *)false,
+		.print = PRINT_NEVER,
 	}
 };
 
diff --git a/lib/kunit/test.c b/lib/kunit/test.c
index 09e3dabfac0c945b2608feb88c1b1d46fb807edc..2140841b7dc9ca45346159683d8f2b85b6e11381 100644
--- a/lib/kunit/test.c
+++ b/lib/kunit/test.c
@@ -590,6 +590,11 @@ static void kunit_run_case_catch_errors(struct kunit_suite *suite,
 	context.test_case = test_case;
 	kunit_try_catch_run(try_catch, &context);
 
+	if (try_catch->try_result == -EINTR && test_case->attr.rust_should_panic) {
+		test->status = KUNIT_SUCCESS;
+		test_case->status = KUNIT_SUCCESS;
+	}
+
 	/* Now run the cleanup */
 	kunit_try_catch_init(try_catch,
 			     test,
diff --git a/rust/kernel/kunit.rs b/rust/kernel/kunit.rs
index 91eaff8c186afd09333a525bc106d39391d30a92..5fa4d994e0f7ebf5bbe5fd3571a372548cc8499b 100644
--- a/rust/kernel/kunit.rs
+++ b/rust/kernel/kunit.rs
@@ -207,6 +207,7 @@ pub const fn kunit_case(
         name: kernel::str::as_char_ptr_in_const_context(name),
         attr: kernel::bindings::kunit_attributes {
             speed: kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+            rust_should_panic: false,
         },
         generate_params: None,
         status: kernel::bindings::kunit_status_KUNIT_SUCCESS,
@@ -282,6 +283,7 @@ macro_rules! kunit_unsafe_test_suite {
                     exit: None,
                     attr: ::kernel::bindings::kunit_attributes {
                         speed: ::kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+                        rust_should_panic: false,
                     },
                     status_comment: [0; 256usize],
                     debugfs: ::core::ptr::null_mut(),
@@ -345,6 +347,19 @@ fn rust_test_kunit_in_kunit_test() {
         assert!(in_kunit_test());
     }
 
+    #[test]
+    #[should_panic]
+    fn rust_test_kunit_panic_in_kunit_test() {
+        panic!("This test should panic and pass");
+    }
+
+    #[test]
+    #[should_panic]
+    fn rust_test_kunit_panic_in_kunit_test_bug() {
+        // The panic is produced in a C call. This should succeed.
+        unsafe { bindings::BUG() };
+    }
+
     #[test]
     #[cfg(not(all()))]
     fn rust_test_kunit_always_disabled_test() {
diff --git a/rust/macros/kunit.rs b/rust/macros/kunit.rs
index ae20ed6768f1564439acf0cadc72a787bada8473..f1d0210e6a49468876d69821cc559002ad12da50 100644
--- a/rust/macros/kunit.rs
+++ b/rust/macros/kunit.rs
@@ -106,6 +106,11 @@ pub(crate) fn kunit_tests(test_suite: Ident, mut module: ItemMod) -> Result<Toke
             .cloned()
             .collect();
 
+        let should_panic = f
+            .attrs
+            .iter()
+            .any(|attr| attr.path().is_ident("should_panic"));
+
         // Before the test, override usual `assert!` and `assert_eq!` macros with ones that call
         // KUnit instead.
         let test_str = test.to_string();
@@ -135,25 +140,38 @@ macro_rules! assert_eq {
             &CString::new(test_str.as_str()).expect("identifier cannot contain NUL"),
             test.span(),
         );
+        let assertion = if should_panic {
+            quote!(
+                let _ = #test();
+                (*_test).status = ::kernel::bindings::kunit_status_KUNIT_FAILURE;
+            )
+        } else {
+            quote!(
+                use ::kernel::kunit::is_test_result_ok;
+                assert!(is_test_result_ok(#test()));
+            )
+        };
         processed_items.push(parse_quote! {
             unsafe extern "C" fn #kunit_wrapper_fn_name(_test: *mut ::kernel::bindings::kunit) {
                 (*_test).status = ::kernel::bindings::kunit_status_KUNIT_SKIPPED;
 
+
                 // Append any `cfg` attributes the user might have written on their tests so we
                 // don't attempt to call them when they are `cfg`'d out. An extra `use` is used
                 // here to reduce the length of the assert message.
                 #(#cfg_attrs)*
                 {
                     (*_test).status = ::kernel::bindings::kunit_status_KUNIT_SUCCESS;
-                    use ::kernel::kunit::is_test_result_ok;
-                    assert!(is_test_result_ok(#test()));
+                    #assertion
                 }
             }
         });
 
-        test_cases.push(quote!(
-            ::kernel::kunit::kunit_case(#test_cstr, #kunit_wrapper_fn_name)
-        ));
+        test_cases.push(quote!({
+            let mut case = ::kernel::kunit::kunit_case(#test_cstr, #kunit_wrapper_fn_name);
+            case.attr.rust_should_panic = #should_panic;
+            case
+        }));
     }
 
     let num_tests_plus_1 = test_cases.len() + 1;

-- 
2.47.3

