From: =?utf-8?q?Nicol=C3=A1s_Antinori?= <nico.antinori.7@gmail.com>
Date: Fri, 13 Nov 2026 15:20:55 -0300
Subject: [PATCH v3 1/3] rust: kunit: add #[should_panic] support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261113-rust_kunit_v6_send-v3-1-0d7832c07166@gmail.com>
References: <20261113-rust_kunit_v6_send-v3-0-0d7832c07166@gmail.com>
In-Reply-To: <20261113-rust_kunit_v6_send-v3-0-0d7832c07166@gmail.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=21575;
 i=nico.antinori.7@gmail.com; h=from:subject:message-id;
 bh=I8o4512vX0eaMApbpis7jVFkvZfTEeS9yP2fJaCNGjQ=;
 b=owGbwMvMwCV2QdXfwqNJ1YjxtFoSQ9b3ULOSYq+L2U537RXKV0b/EjjFt6xbm+PlHU57Jr1fy
 c7up0w6SlkYxLgYZMUUWeZyvv9sbGteUS69KQhmDisTyBAGLk4BmAh7DsNfuQfyAkfD1/blrtQ8
 VTQpQ4X9IeeRuq8z7k3dzhbFF5I+i+EPh3zzfqELVsFeu0wN5VysNgqGH7c9xiEWmp2n/Oqi5gZ
 GAA==
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
 Documentation/rust/testing.rst |  8 ++++-
 drivers/of/overlay_test.c      |  6 +++-
 include/kunit/test.h           |  9 ++++-
 lib/kunit/attributes.c         | 18 ++++++++++
 lib/kunit/kunit-test.c         | 36 ++++++++++++++++----
 lib/kunit/platform-test.c      |  6 +++-
 lib/kunit/string-stream-test.c |  9 ++++-
 lib/kunit/test.c               | 10 ++++--
 rust/kernel/kunit.rs           | 32 ++++++++++++++++++
 rust/kernel/lib.rs             | 43 +++++++++++++++++++++--
 rust/macros/kunit.rs           | 77 +++++++++++++++++++++++++++++-------------
 11 files changed, 215 insertions(+), 39 deletions(-)

diff --git a/Documentation/rust/testing.rst b/Documentation/rust/testing.rst
index 73046523a9a27393648cb4aeaeb055b745357c6d..6a82ac5885cecfd2e12839c64fdbf50428502344 100644
--- a/Documentation/rust/testing.rst
+++ b/Documentation/rust/testing.rst
@@ -169,8 +169,14 @@ And if we run it, the kernel log would look like::
 	    ok 1 test_f
 	ok 1 rust_kernel_mymod
 
+To test code paths that are expected to produce a Rust panic, the
+``#[should_panic]`` attribute can be used. When this attribute is used, tests
+that produce a panic (either with ``panic!`` or an ``assert!``) will pass.
+
 Like documentation tests, the ``assert!`` and ``assert_eq!`` macros are mapped
-back to KUnit and do not panic. Similarly, the
+back to KUnit and do not panic. The exception is tests marked with
+``#[should_panic]``, which use the standard Rust ``assert!``/``assert_eq!``
+macros so that failed assertions are handled by the panic logic. Similarly, the
 `? <https://doc.rust-lang.org/reference/expressions/operator-expr.html#the-question-mark-operator>`_
 operator is supported, i.e. the test functions may return either nothing (i.e.
 the unit type ``()``) or ``Result`` (i.e. any ``Result<T, E>``). For instance:
diff --git a/drivers/of/overlay_test.c b/drivers/of/overlay_test.c
index c787524c5a887cdf87e5acc98982733e02feb847..55df32ea1e5b947e23968afd17b0ed1ca9ed5088 100644
--- a/drivers/of/overlay_test.c
+++ b/drivers/of/overlay_test.c
@@ -63,6 +63,10 @@ static void of_overlay_apply_kunit_cleanup(struct kunit *test)
 	struct platform_device *pdev;
 	struct device *dev;
 	struct device_node *np;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
 	of_root_kunit_skip(test);
 	if (!IS_ENABLED(CONFIG_OF_OVERLAY))
@@ -70,7 +74,7 @@ static void of_overlay_apply_kunit_cleanup(struct kunit *test)
 	if (!IS_ENABLED(CONFIG_OF_EARLY_FLATTREE))
 		kunit_skip(test, "requires CONFIG_OF_EARLY_FLATTREE for root node");
 
-	kunit_init_test(&fake, "fake test", NULL);
+	kunit_init_test(&fake, "fake test", NULL, &attr);
 	KUNIT_ASSERT_EQ(test, fake.status, KUNIT_SUCCESS);
 
 	KUNIT_ASSERT_EQ(test, 0,
diff --git a/include/kunit/test.h b/include/kunit/test.h
index 31d549578f8ec113bef9b5d72bc9355c07fce3c0..43c48a1b3684f5ca7ed237a7606a22d7d0c9fb31 100644
--- a/include/kunit/test.h
+++ b/include/kunit/test.h
@@ -83,6 +83,7 @@ enum kunit_speed {
 /* Holds attributes for each test case and suite */
 struct kunit_attributes {
 	enum kunit_speed speed;
+	bool rust_should_panic;
 };
 
 /**
@@ -355,6 +356,9 @@ struct kunit {
 	char status_comment[KUNIT_STATUS_COMMENT_SIZE];
 	/* Saves the last seen test. Useful to help with faults. */
 	struct kunit_loc last_seen;
+
+	/* The attributes associated with the test */
+	struct kunit_attributes *attr;
 };
 
 static inline void kunit_set_failure(struct kunit *test)
@@ -369,7 +373,10 @@ const char *kunit_filter_glob(void);
 char *kunit_filter(void);
 char *kunit_filter_action(void);
 
-void kunit_init_test(struct kunit *test, const char *name, struct string_stream *log);
+void kunit_init_test(struct kunit *test,
+		     const char *name,
+		     struct string_stream *log,
+		     struct kunit_attributes *attr);
 
 int kunit_run_tests(struct kunit_suite *suite);
 
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
index 126e30879dad652d5b236aeb13d4406a4ddbab00..e2219e1e37501406ae7991895483fb28872f4339 100644
--- a/lib/kunit/kunit-test.c
+++ b/lib/kunit/kunit-test.c
@@ -186,7 +186,7 @@ static void kunit_resource_test_init_resources(struct kunit *test)
 {
 	struct kunit_test_resource_context *ctx = test->priv;
 
-	kunit_init_test(&ctx->test, "testing_test_init_test", NULL);
+	kunit_init_test(&ctx->test, "testing_test_init_test", NULL, ctx->test.attr);
 
 	KUNIT_EXPECT_TRUE(test, list_empty(&ctx->test.resources));
 }
@@ -539,12 +539,19 @@ static void kunit_resource_test_action_ordering(struct kunit *test)
 static int kunit_resource_test_init(struct kunit *test)
 {
 	struct kunit_test_resource_context *ctx = kzalloc_obj(*ctx);
+	struct kunit_attributes *ctx_test_attr;
 
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, ctx);
 
 	test->priv = ctx;
 
-	kunit_init_test(&ctx->test, "test_test_context", NULL);
+	ctx_test_attr = kzalloc_obj(*ctx_test_attr, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, ctx_test_attr);
+
+	ctx_test_attr->speed = KUNIT_SPEED_NORMAL;
+	ctx_test_attr->rust_should_panic = false;
+
+	kunit_init_test(&ctx->test, "test_test_context", NULL, ctx_test_attr);
 
 	return 0;
 }
@@ -553,6 +560,7 @@ static void kunit_resource_test_exit(struct kunit *test)
 {
 	struct kunit_test_resource_context *ctx = test->priv;
 
+	kfree(ctx->test.attr);
 	kunit_cleanup(&ctx->test);
 	kfree(ctx);
 }
@@ -666,8 +674,12 @@ static struct kunit_suite kunit_log_test_suite = {
 static void kunit_status_set_failure_test(struct kunit *test)
 {
 	struct kunit fake;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
-	kunit_init_test(&fake, "fake test", NULL);
+	kunit_init_test(&fake, "fake test", NULL, &attr);
 
 	KUNIT_EXPECT_EQ(test, fake.status, (enum kunit_status)KUNIT_SUCCESS);
 	kunit_set_failure(&fake);
@@ -677,8 +689,12 @@ static void kunit_status_set_failure_test(struct kunit *test)
 static void kunit_status_mark_skipped_test(struct kunit *test)
 {
 	struct kunit fake;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
-	kunit_init_test(&fake, "fake test", NULL);
+	kunit_init_test(&fake, "fake test", NULL, &attr);
 
 	/* Before: Should be SUCCESS with no comment. */
 	KUNIT_EXPECT_EQ(test, fake.status, KUNIT_SUCCESS);
@@ -715,8 +731,12 @@ static void kunit_current_test(struct kunit *test)
 static void kunit_current_fail_test(struct kunit *test)
 {
 	struct kunit fake;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
-	kunit_init_test(&fake, "fake test", NULL);
+	kunit_init_test(&fake, "fake test", NULL, &attr);
 	KUNIT_EXPECT_EQ(test, fake.status, KUNIT_SUCCESS);
 
 	/* Set current->kunit_test to fake test. */
@@ -881,8 +901,12 @@ static void kunit_stub_test(struct kunit *test)
 		void *real_fn_addr;
 		void *replacement_addr;
 	} *stub_ctx;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
-	kunit_init_test(&fake_test, "kunit_stub_fake_test", NULL);
+	kunit_init_test(&fake_test, "kunit_stub_fake_test", NULL, &attr);
 	KUNIT_ASSERT_EQ(test, fake_test.status, KUNIT_SUCCESS);
 	KUNIT_ASSERT_EQ(test, list_count_nodes(&fake_test.resources), 0);
 
diff --git a/lib/kunit/platform-test.c b/lib/kunit/platform-test.c
index e3debb8fbcef36f22418310ae6a0c14be0859ce3..4e60079a8a0bc1a0de6954dab2c8ca09985e9dd9 100644
--- a/lib/kunit/platform-test.c
+++ b/lib/kunit/platform-test.c
@@ -71,8 +71,12 @@ static void kunit_platform_device_add_cleans_up(struct kunit *test)
 	const int id = -1;
 	struct kunit fake;
 	struct device *dev;
+	struct kunit_attributes attr = {
+		.speed = KUNIT_SPEED_NORMAL,
+		.rust_should_panic = false,
+	};
 
-	kunit_init_test(&fake, "kunit_platform_device_add_fake_test", NULL);
+	kunit_init_test(&fake, "kunit_platform_device_add_fake_test", NULL, &attr);
 	KUNIT_ASSERT_EQ(test, fake.status, KUNIT_SUCCESS);
 
 	pdev = kunit_platform_device_alloc(&fake, name, id);
diff --git a/lib/kunit/string-stream-test.c b/lib/kunit/string-stream-test.c
index 7734e33156f9456eebfdca5b82972c010fb4e7df..3f43fb3dc144dfa3f7890ff9c47b08d7e9045e1e 100644
--- a/lib/kunit/string-stream-test.c
+++ b/lib/kunit/string-stream-test.c
@@ -122,11 +122,18 @@ static void string_stream_resource_free_test(struct kunit *test)
 {
 	struct string_stream_test_priv *priv = test->priv;
 	struct kunit *fake_test;
+	struct kunit_attributes *fake_attr;
 
 	fake_test = kunit_kzalloc(test, sizeof(*fake_test), GFP_KERNEL);
 	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, fake_test);
 
-	kunit_init_test(fake_test, "string_stream_fake_test", NULL);
+	fake_attr = kunit_kzalloc(test, sizeof(*fake_attr), GFP_KERNEL);
+	KUNIT_ASSERT_NOT_ERR_OR_NULL(test, fake_attr);
+
+	fake_attr->speed = KUNIT_SPEED_NORMAL;
+	fake_attr->rust_should_panic = false;
+
+	kunit_init_test(fake_test, "string_stream_fake_test", NULL, fake_attr);
 	fake_test->priv = priv;
 
 	/*
diff --git a/lib/kunit/test.c b/lib/kunit/test.c
index 09e3dabfac0c945b2608feb88c1b1d46fb807edc..0ef869385c435f2394db629301f62916b840064b 100644
--- a/lib/kunit/test.c
+++ b/lib/kunit/test.c
@@ -351,7 +351,10 @@ static void kunit_init_params(struct kunit *test)
 	test->params_array.elem_size = 0;
 }
 
-void kunit_init_test(struct kunit *test, const char *name, struct string_stream *log)
+void kunit_init_test(struct kunit *test,
+		     const char *name,
+		     struct string_stream *log,
+		     struct kunit_attributes *attributes)
 {
 	spin_lock_init(&test->lock);
 	INIT_LIST_HEAD(&test->resources);
@@ -359,6 +362,7 @@ void kunit_init_test(struct kunit *test, const char *name, struct string_stream
 	test->log = log;
 	if (test->log)
 		string_stream_clear(log);
+	test->attr = attributes;
 	test->status = KUNIT_SUCCESS;
 	test->status_comment[0] = '\0';
 	kunit_init_params(test);
@@ -724,7 +728,7 @@ kunit_run_param_test(struct kunit_suite *suite, struct kunit_case *test_case,
 			.param_index = ++test->param_index,
 			.parent = test,
 		};
-		kunit_init_test(&param_test, test_case->name, NULL);
+		kunit_init_test(&param_test, test_case->name, NULL, &test_case->attr);
 		param_test.log = test_case->log;
 		kunit_run_case_catch_errors(suite, test_case, &param_test);
 
@@ -764,7 +768,7 @@ kunit_run_one_test(struct kunit_suite *suite, struct kunit_case *test_case,
 	struct kunit test = { .param_value = NULL, .param_index = 0 };
 	struct kunit_result_stats param_stats = { 0 };
 
-	kunit_init_test(&test, test_case->name, test_case->log);
+	kunit_init_test(&test, test_case->name, test_case->log, &test_case->attr);
 	if (test_case->status == KUNIT_SKIPPED) {
 		/* Test marked as skip */
 		test.status = KUNIT_SKIPPED;
diff --git a/rust/kernel/kunit.rs b/rust/kernel/kunit.rs
index 25ff272d29b2b3f192a3968481c1d5417df4335b..be02b9e4ae70f4913a5074c512d4adf78e34335c 100644
--- a/rust/kernel/kunit.rs
+++ b/rust/kernel/kunit.rs
@@ -209,6 +209,7 @@ pub const fn kunit_case(
         name: kernel::str::as_char_ptr_in_const_context(name),
         attr: kernel::bindings::kunit_attributes {
             speed: kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+            rust_should_panic: false,
         },
         generate_params: None,
         status: kernel::bindings::kunit_status_KUNIT_SUCCESS,
@@ -284,6 +285,7 @@ macro_rules! kunit_unsafe_test_suite {
                     exit: None,
                     attr: ::kernel::bindings::kunit_attributes {
                         speed: ::kernel::bindings::kunit_speed_KUNIT_SPEED_NORMAL,
+                        rust_should_panic: false,
                     },
                     status_comment: [0; 256usize],
                     debugfs: ::core::ptr::null_mut(),
@@ -335,8 +337,20 @@ pub fn in_kunit_test() -> bool {
 #[cfg(CONFIG_RUST_KUNIT_SELFTEST)]
 #[kunit_tests(rust_kernel_kunit)]
 mod tests {
+    #![expect(clippy::assertions_on_constants, reason = "Testing failure behavior")]
+
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
@@ -347,6 +361,24 @@ fn rust_test_kunit_in_kunit_test() {
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
diff --git a/rust/kernel/lib.rs b/rust/kernel/lib.rs
index 1ab41129d557a97c09b4fb1bfc6aadb4250156a7..ba9e1a07aab8cf1f91d44c09e3a8e2291781d32a 100644
--- a/rust/kernel/lib.rs
+++ b/rust/kernel/lib.rs
@@ -179,13 +179,52 @@ impl ModuleMetadata for LocalModule {
 }
 
 #[cfg(not(testlib))]
-#[panic_handler]
-fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
+#[inline]
+fn bug_on_panic(info: &core::panic::PanicInfo<'_>) -> ! {
     pr_emerg!("{}\n", info);
     // SAFETY: FFI call.
     unsafe { bindings::BUG() };
 }
 
+#[cfg(all(not(testlib), not(CONFIG_KUNIT = "y")))]
+#[panic_handler]
+fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
+    bug_on_panic(info);
+}
+
+#[cfg(all(not(testlib), CONFIG_KUNIT = "y"))]
+#[panic_handler]
+fn panic(info: &core::panic::PanicInfo<'_>) -> ! {
+    // SAFETY: This function is safe to call even if CONFIG_KUNIT=n. If a null pointer is returned,
+    // the panic is handled same as if CONFIG_KUNIT=n.
+    let kunit_test = unsafe { ::bindings::kunit_get_current_test() };
+    if kunit_test.is_null() {
+        bug_on_panic(info);
+    } else {
+        // SAFETY: We are in the else branch of kunit_test.is_null() condition, meaning that
+        // `::bindings::kunit_get_current_test()` returned a kunit struct successfully.
+        let test_attributes = unsafe { (*kunit_test).attr };
+        if test_attributes.is_null() {
+            use crate::str::CStrExt as _;
+            // SAFETY: Test name should be set by KUnit framework at this stage.
+            let test_str = unsafe { str::CStr::from_char_ptr((*kunit_test).name.cast()) };
+            pr_emerg!("Test case {} has no attributes\n", test_str);
+            bug_on_panic(info);
+        }
+        // SAFETY: We already tested that test_attributes.is_null() is false, meaning that it is
+        // safe to retrieve its attributes.
+        else if unsafe { (*test_attributes).rust_should_panic } {
+            // SAFETY: We are in the else branch of kunit_test.is_null() condition, meaning that
+            // `::bindings::kunit_get_current_test()` returned a kunit struct successfully.
+            unsafe {
+                bindings::__kunit_abort(kunit_test);
+            };
+        } else {
+            bug_on_panic(info);
+        }
+    }
+}
+
 /// Produces a pointer to an object from a pointer to one of its fields.
 ///
 /// If you encounter a type mismatch due to the [`Opaque`] type, then use [`Opaque::cast_into`] or
diff --git a/rust/macros/kunit.rs b/rust/macros/kunit.rs
index e9152b9d51f9450b7e549e2e1629b5fc5f485a28..ac7495deab17d6579e3f213b7018516c9ca68425 100644
--- a/rust/macros/kunit.rs
+++ b/rust/macros/kunit.rs
@@ -106,25 +106,40 @@ pub(crate) fn kunit_tests(test_suite: Ident, mut module: ItemMod) -> Result<Toke
             .cloned()
             .collect();
 
-        // Before the test, override usual `assert!` and `assert_eq!` macros with ones that call
-        // KUnit instead.
+        let should_panic = f
+            .attrs
+            .extract_if(.., |attr| attr.path().is_ident("should_panic"))
+            .count()
+            > 0;
+
+        // Inside the test, override usual `assert!` and `assert_eq!` macros with ones that call
+        // KUnit instead unless the test should panic. For tests expected to panic, assertions are
+        // not overwritten so they can be handled by the Rust's panic handler.
         let test_str = test.to_string();
-        processed_items.push(parse_quote! {
-            #[allow(unused)]
-            macro_rules! assert {
-                ($cond:expr $(,)?) => {{
-                    kernel::kunit_assert!(#test_str, $cond);
-                }}
-            }
-        });
-        processed_items.push(parse_quote! {
-            #[allow(unused)]
-            macro_rules! assert_eq {
-                ($left:expr, $right:expr $(,)?) => {{
-                    kernel::kunit_assert_eq!(#test_str, $left, $right);
-                }}
-            }
-        });
+        if !should_panic {
+            f.block.stmts.insert(
+                0,
+                parse_quote! {
+                    #[allow(unused)]
+                    macro_rules! assert {
+                        ($cond:expr $(,)?) => {{
+                            kernel::kunit_assert!(#test_str, $cond);
+                        }}
+                    }
+                },
+            );
+            f.block.stmts.insert(
+                0,
+                parse_quote! {
+                    #[allow(unused)]
+                    macro_rules! assert_eq {
+                        ($left:expr, $right:expr $(,)?) => {{
+                            kernel::kunit_assert_eq!(#test_str, $left, $right);
+                        }}
+                    }
+                },
+            );
+        }
 
         // Add back the test item.
         processed_items.push(Item::Fn(f));
@@ -134,25 +149,41 @@ macro_rules! assert_eq {
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
+                kernel::kunit_assert!(#test_str, is_test_result_ok(#test()));
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

