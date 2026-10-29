From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Thu, 29 Oct 2026 13:59:01 -0300
Subject: [PATCH v2 1/3] rust: kunit: add #[should_panic] support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261029-rust_kunit_v6_send-v2-1-5ce551efc48e@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=14052;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=sbpLybwVB7Ofd+oehlVpwBPiQ4LnQa6JfCug/U1Ccsc=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9bj6ubjNzz6it+nlCetunps9aStMzpV2uf4HeErYpjJI
 73ewvBdRykLgxgXg6yYIstczvefjW3NK8qlNwXBzGFlAhnCwMUpABMJDGX4p83/1GuXd4VuithH
 7SQOl29MIt+4+hYK/kn0W+Qn6fh0EiNDyww5T+mK29FlN5/PzE4qsm25wcC1wv/jhY+70+v8vEU
 5AA==
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
 include/kunit/test.h       |  1 +
 include/kunit/try-catch.h  |  3 +++
 lib/kunit/attributes.c     | 18 ++++++++++++++++
 lib/kunit/kunit-test.c     |  3 +++
 lib/kunit/test.c           |  2 ++
 lib/kunit/try-catch-impl.h |  2 ++
 lib/kunit/try-catch.c      | 14 ++++++++-----
 rust/kernel/kunit.rs       | 51 +++++++++++++++++++++++++++++++++++++++++++---
 rust/macros/kunit.rs       | 35 ++++++++++++++++++++++++-------
 9 files changed, 114 insertions(+), 15 deletions(-)

diff --git a/include/kunit/test.h b/include/kunit/test.h
index 31d549578f8ec113bef9b5d72bc9355c07fce3c0..15bd020d83722163bfc3899f64247afb2c4cefa4 100644
--- a/include/kunit/test.h
+++ b/include/kunit/test.h
@@ -83,6 +83,7 @@ enum kunit_speed {
 /* Holds attributes for each test case and suite */
 struct kunit_attributes {
 	enum kunit_speed speed;
+	bool rust_should_panic;
 };
 
 /**
diff --git a/include/kunit/try-catch.h b/include/kunit/try-catch.h
index d4e1a5b98ed67e4f71ff1bcc71422d5bada54b75..197029e19d759dfeb2700af13cfc8fc246768bb9 100644
--- a/include/kunit/try-catch.h
+++ b/include/kunit/try-catch.h
@@ -22,6 +22,8 @@ struct kunit;
  * @try_result: Contains any errno obtained while running test case.
  * @try: The function, the test case, to attempt to run.
  * @catch: The function called if @try bails out.
+ * @rust_should_panic: Flag used to avoid printing spurious error logs when a
+ *	Rust test is annotated with #[should_panic].
  * @context: used to pass user data to the try and catch functions.
  *
  * kunit_try_catch provides a generic, architecture independent way to execute
@@ -48,6 +50,7 @@ struct kunit_try_catch {
 	kunit_try_catch_func_t try;
 	kunit_try_catch_func_t catch;
 	unsigned long timeout;
+	bool rust_should_panic;
 	void *context;
 };
 
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
 
diff --git a/lib/kunit/kunit-test.c b/lib/kunit/kunit-test.c
index 126e30879dad652d5b236aeb13d4406a4ddbab00..7cca586767cc711f7a829cc4c3bdec17bd8c7d9c 100644
--- a/lib/kunit/kunit-test.c
+++ b/lib/kunit/kunit-test.c
@@ -45,6 +45,7 @@ static void kunit_test_try_catch_successful_try_no_catch(struct kunit *test)
 			     test,
 			     kunit_test_successful_try,
 			     kunit_test_no_catch,
+			     false,
 			     300 * msecs_to_jiffies(MSEC_PER_SEC));
 	kunit_try_catch_run(try_catch, test);
 
@@ -78,6 +79,7 @@ static void kunit_test_try_catch_unsuccessful_try_does_catch(struct kunit *test)
 			     test,
 			     kunit_test_unsuccessful_try,
 			     kunit_test_catch,
+			     false,
 			     300 * msecs_to_jiffies(MSEC_PER_SEC));
 	kunit_try_catch_run(try_catch, test);
 
@@ -133,6 +135,7 @@ static void kunit_test_fault_null_dereference(struct kunit *test)
 			     test,
 			     kunit_test_null_dereference,
 			     kunit_test_catch,
+			     false,
 			     300 * msecs_to_jiffies(MSEC_PER_SEC));
 	kunit_try_catch_run(try_catch, test);
 
diff --git a/lib/kunit/test.c b/lib/kunit/test.c
index 09e3dabfac0c945b2608feb88c1b1d46fb807edc..8b0072c66e1710c7faa7de2df7ff8c4bf48b8e88 100644
--- a/lib/kunit/test.c
+++ b/lib/kunit/test.c
@@ -584,6 +584,7 @@ static void kunit_run_case_catch_errors(struct kunit_suite *suite,
 			     test,
 			     kunit_try_run_case,
 			     kunit_catch_run_case,
+			     test_case->attr.rust_should_panic,
 			     kunit_test_timeout(suite, test_case));
 	context.test = test;
 	context.suite = suite;
@@ -595,6 +596,7 @@ static void kunit_run_case_catch_errors(struct kunit_suite *suite,
 			     test,
 			     kunit_try_run_case_cleanup,
 			     kunit_catch_run_case_cleanup,
+			     false,
 			     kunit_test_timeout(suite, test_case));
 	kunit_try_catch_run(try_catch, &context);
 
diff --git a/lib/kunit/try-catch-impl.h b/lib/kunit/try-catch-impl.h
index 6f401b97cd0b9842e7533f1b828f72f884450f74..9abe69bb8b396185afb77cb11ca651ba4c9b6a59 100644
--- a/lib/kunit/try-catch-impl.h
+++ b/lib/kunit/try-catch-impl.h
@@ -18,11 +18,13 @@ static inline void kunit_try_catch_init(struct kunit_try_catch *try_catch,
 					struct kunit *test,
 					kunit_try_catch_func_t try,
 					kunit_try_catch_func_t catch,
+					bool rust_should_panic,
 					unsigned long timeout)
 {
 	try_catch->test = test;
 	try_catch->try = try;
 	try_catch->catch = catch;
+	try_catch->rust_should_panic = rust_should_panic;
 	try_catch->timeout = timeout;
 }
 
diff --git a/lib/kunit/try-catch.c b/lib/kunit/try-catch.c
index d84a879f0a789f3625538735644910c84ac80e56..b9e29d4e7dd52d8d82d71a3f138f0313c772ee76 100644
--- a/lib/kunit/try-catch.c
+++ b/lib/kunit/try-catch.c
@@ -76,11 +76,15 @@ void kunit_try_catch_run(struct kunit_try_catch *try_catch, void *context)
 	if (exit_code == -EFAULT)
 		try_catch->try_result = 0;
 	else if (exit_code == -EINTR) {
-		if (test->last_seen.file)
-			kunit_err(test, "try faulted: last line seen %s:%d\n",
-				  test->last_seen.file, test->last_seen.line);
-		else
-			kunit_err(test, "try faulted\n");
+		if (try_catch->rust_should_panic) {
+			try_catch->try_result = 0;
+		} else {
+			if (test->last_seen.file)
+				kunit_err(test, "try faulted: last line seen %s:%d\n",
+					  test->last_seen.file, test->last_seen.line);
+			else
+				kunit_err(test, "try faulted\n");
+		}
 	} else if (exit_code == -ETIMEDOUT)
 		kunit_err(test, "try timed out\n");
 	else if (exit_code)
diff --git a/rust/kernel/kunit.rs b/rust/kernel/kunit.rs
index 25ff272d29b2b3f192a3968481c1d5417df4335b..5e688b743ee2152867e2f99c7f18b86e1b7fbe3d 100644
--- a/rust/kernel/kunit.rs
+++ b/rust/kernel/kunit.rs
@@ -58,7 +58,7 @@ pub fn info(args: fmt::Arguments<'_>) {
 #[doc(hidden)]
 #[macro_export]
 macro_rules! kunit_assert {
-    ($name:literal, $condition:expr $(,)?) => {
+    ($name:literal, $test_should_panic:expr, $condition:expr $(,)?) => {
         'out: {
             // Do nothing if the condition is `true`.
             if $condition {
@@ -93,6 +93,14 @@ macro_rules! kunit_assert {
                 ));
                 break 'out;
             }
+            // If condition fails but the test should panic, then we just abort.
+            else if $test_should_panic {
+                // SAFETY: FFI call. The `kunit_test` pointer is valid because we got it from
+                // `kunit_get_current_test()` and it was not null.
+                unsafe {
+                    $crate::bindings::__kunit_abort(kunit_test);
+                }
+            }
 
             #[repr(transparent)]
             struct Location($crate::bindings::kunit_loc);
@@ -166,10 +174,10 @@ unsafe impl Sync for UnaryAssert {}
 #[doc(hidden)]
 #[macro_export]
 macro_rules! kunit_assert_eq {
-    ($name:literal, $left:expr, $right:expr $(,)?) => {{
+    ($name:literal, $test_should_panic:expr, $left:expr, $right:expr $(,)?) => {{
         // For the moment, we just forward to the expression assert because, for binary asserts,
         // KUnit supports only a few types (e.g. integers).
-        $crate::kunit_assert!($name, $left == $right);
+        $crate::kunit_assert!($name, $test_should_panic, $left == $right);
     }};
 }
 
@@ -209,6 +217,7 @@ pub const fn kunit_case(
         name: kernel::str::as_char_ptr_in_const_context(name),
         attr: kernel::bindings::kunit_attributes {
             speed: kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+            rust_should_panic: false,
         },
         generate_params: None,
         status: kernel::bindings::kunit_status_KUNIT_SUCCESS,
@@ -284,6 +293,7 @@ macro_rules! kunit_unsafe_test_suite {
                     exit: None,
                     attr: ::kernel::bindings::kunit_attributes {
                         speed: ::kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+                        rust_should_panic: false,
                     },
                     status_comment: [0; 256usize],
                     debugfs: ::core::ptr::null_mut(),
@@ -337,6 +347,16 @@ pub fn in_kunit_test() -> bool {
 mod tests {
     use super::*;
 
+    struct TestStruct;
+
+    impl TestStruct {
+        // This assert does not get replaced with kunit_assert, since this is not a #[test]
+        // function.
+        pub(crate) fn escaped_assert() {
+            assert!(false);
+        }
+    }
+
     #[test]
     fn rust_test_kunit_example_test() {
         assert_eq!(1 + 1, 2);
@@ -347,6 +367,31 @@ fn rust_test_kunit_in_kunit_test() {
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
+    #[test]
+    #[should_panic]
+    fn rust_test_assert_false_success_with_should_panic() {
+        assert!(false)
+    }
+
+    #[test]
+    #[should_panic]
+    fn rust_test_should_panic_with_escaped_assert() {
+        TestStruct::escaped_assert();
+    }
+
     #[test]
     #[cfg(not(all()))]
     fn rust_test_kunit_always_disabled_test() {
diff --git a/rust/macros/kunit.rs b/rust/macros/kunit.rs
index e9152b9d51f9450b7e549e2e1629b5fc5f485a28..288b53d21c4e7c8d9b5148d50c1a833f73e53015 100644
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
@@ -113,7 +118,7 @@ pub(crate) fn kunit_tests(test_suite: Ident, mut module: ItemMod) -> Result<Toke
             #[allow(unused)]
             macro_rules! assert {
                 ($cond:expr $(,)?) => {{
-                    kernel::kunit_assert!(#test_str, $cond);
+                    kernel::kunit_assert!(#test_str, #should_panic, $cond);
                 }}
             }
         });
@@ -121,7 +126,7 @@ macro_rules! assert {
             #[allow(unused)]
             macro_rules! assert_eq {
                 ($left:expr, $right:expr $(,)?) => {{
-                    kernel::kunit_assert_eq!(#test_str, $left, $right);
+                    kernel::kunit_assert_eq!(#test_str, #should_panic, $left, $right);
                 }}
             }
         });
@@ -134,25 +139,41 @@ macro_rules! assert_eq {
             &CString::new(test_str.as_str()).expect("identifier cannot contain NUL"),
             test.span(),
         );
+        let assertion = if should_panic {
+            quote!(
+                let _ = #test();
+                ::kernel::kunit::err(::kernel::prelude::fmt!(
+                    "    Expected {} to panic\n", #test_str
+                ));
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

