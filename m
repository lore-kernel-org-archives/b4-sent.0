From: Joel Granados <j.granados@samsung.com>
Date: Tue, 21 Nov 2023 12:02:19 +0100
Subject: [PATCH 2/3] sysctl: Add a selftest for handling empty dirs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231121-jag-fix_out_of_bounds_insert-v1-2-571e76d51316@samsung.com>
References: <20231121-jag-fix_out_of_bounds_insert-v1-0-571e76d51316@samsung.com>
In-Reply-To: <20231121-jag-fix_out_of_bounds_insert-v1-0-571e76d51316@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, Kees Cook <keescook@chromium.org>, 
 Iurii Zaikin <yzaikin@google.com>, Shuah Khan <shuah@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=3897;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=bKjIXr0H+JsfSfz8xoXCVF/jy2aS3I1Y63fFXt/C07E=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlXI5D0LZq/oFYRZ4WUYe0Wlyd9gXjLPnh7W7YW
 qMrp4gEAWuJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZVyOQwAKCRC6l81St5ZB
 T4fYC/wJkklJdFj9BvtYlU849BuM7cf7Qh5+ZjpAmMELnTk6sRAvSlANrBRLxx8hBkD+jlfkOr2
 I+sFj78+0dfjdDBlcuKxNgEYp7U2cYRdy4e5OZ7rupNaO4aVF726D0pcA4ayG41RpJF0MX/m2Wk
 I8QqJzwgdLy0HF5JMT8gve19MS57N+KJ364mnaHpNjczMMejIgW+3P+Nm31RFvvPkVv4Z7rG22G
 IDySN/8AOVXH/EOIEx5UAB2MLEGLt4DYpy3JNWJlAfPc1Gd4WcqxAaSsMNoo2IluWUzh3QhHwCF
 wWT2iT1j8m7QNdKd6WuaLsxKN7ULhMuSfcDRJxI8Ml3BQgcZ0AHfQjR5263qAHbKMrNaZoPHaRN
 5W3PC3aHH3eyuPWOlPA1wk+ZQjS7UhuSvK6jH6MaCSi96ch32L0RVrg18zUCWEj+E/nbiFDDIoT
 7YNN3sm5PXfVwyElGz7HPWuwzli4yjK8iiyUD7YROTX5u1wiWPE5cWQdqnsTqgj2atYss=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Basic test to ensure that empty directories can be registered and that
they in turn can serve as a base dir for other registrations.

Add one test to the sysctl selftest module. It first registers an empty
directory under "empty_add" and then uses that as a base to register
another empty dir.
The sysctl bash script then checks that "empty_add" is present and that
there an empty directory within it.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 lib/test_sysctl.c                        | 29 +++++++++++++++++++++++++++++
 tools/testing/selftests/sysctl/sysctl.sh | 23 +++++++++++++++++++++++
 2 files changed, 52 insertions(+)

diff --git a/lib/test_sysctl.c b/lib/test_sysctl.c
index 8036aa91a1cb..730908bc1c2b 100644
--- a/lib/test_sysctl.c
+++ b/lib/test_sysctl.c
@@ -35,6 +35,8 @@ static struct {
 	struct ctl_table_header *test_h_setup_node;
 	struct ctl_table_header *test_h_mnt;
 	struct ctl_table_header *test_h_mnterror;
+	struct ctl_table_header *empty_add;
+	struct ctl_table_header *empty;
 } sysctl_test_headers;
 
 struct test_sysctl_data {
@@ -220,6 +222,25 @@ static int test_sysctl_run_register_mount_point(void)
 	return 0;
 }
 
+static struct ctl_table test_table_empty[] = { };
+
+static int test_sysctl_run_register_empty(void)
+{
+	/* Tets that an empty dir can be created */
+	sysctl_test_headers.empty_add
+		= register_sysctl("debug/test_sysctl/empty_add", test_table_empty);
+	if (!sysctl_test_headers.empty_add)
+		return -ENOMEM;
+
+	/* Test that register on top of an empty dir works */
+	sysctl_test_headers.empty
+		= register_sysctl("debug/test_sysctl/empty_add/empty", test_table_empty);
+	if (!sysctl_test_headers.empty)
+		return -ENOMEM;
+
+	return 0;
+}
+
 static int __init test_sysctl_init(void)
 {
 	int err;
@@ -233,6 +254,10 @@ static int __init test_sysctl_init(void)
 		goto out;
 
 	err = test_sysctl_run_register_mount_point();
+	if (err)
+		goto out;
+
+	err = test_sysctl_run_register_empty();
 
 out:
 	return err;
@@ -248,6 +273,10 @@ static void __exit test_sysctl_exit(void)
 		unregister_sysctl_table(sysctl_test_headers.test_h_mnt);
 	if (sysctl_test_headers.test_h_mnterror)
 		unregister_sysctl_table(sysctl_test_headers.test_h_mnterror);
+	if (sysctl_test_headers.empty)
+		unregister_sysctl_table(sysctl_test_headers.empty);
+	if (sysctl_test_headers.empty_add)
+		unregister_sysctl_table(sysctl_test_headers.empty_add);
 }
 
 module_exit(test_sysctl_exit);
diff --git a/tools/testing/selftests/sysctl/sysctl.sh b/tools/testing/selftests/sysctl/sysctl.sh
index 444b2befda82..e956d2c3b7e9 100755
--- a/tools/testing/selftests/sysctl/sysctl.sh
+++ b/tools/testing/selftests/sysctl/sysctl.sh
@@ -35,6 +35,7 @@ ALL_TESTS="$ALL_TESTS 0007:1:1:boot_int:1"
 ALL_TESTS="$ALL_TESTS 0008:1:1:match_int:1"
 ALL_TESTS="$ALL_TESTS 0009:1:1:unregister_error:0"
 ALL_TESTS="$ALL_TESTS 0010:1:1:mnt/mnt_error:0"
+ALL_TESTS="$ALL_TESTS 0011:1:1:empty_add:0"
 
 function allow_user_defaults()
 {
@@ -828,6 +829,27 @@ sysctl_test_0010()
 	return 0
 }
 
+sysctl_test_0011()
+{
+	TARGET="${SYSCTL}/$(get_test_target 0011)"
+	echo -n "Testing empty dir handling in ${TARGET} ... "
+	if [ ! -d ${TARGET} ]; then
+		echo -e "FAIL\nCould not create ${TARGET}" >&2
+		rc=1
+		test_rc
+	fi
+
+	TARGET2="${TARGET}/empty"
+	if [ ! -d ${TARGET2} ]; then
+		echo -e "FAIL\nCould not create ${TARGET2}" >&2
+		rc=1
+		test_rc
+	fi
+
+	echo "OK"
+	return 0
+}
+
 list_tests()
 {
 	echo "Test ID list:"
@@ -846,6 +868,7 @@ list_tests()
 	echo "0008 x $(get_test_count 0008) - tests sysctl macro values match"
 	echo "0009 x $(get_test_count 0009) - tests sysct unregister"
 	echo "0010 x $(get_test_count 0010) - tests sysct mount point"
+	echo "0011 x $(get_test_count 0011) - tests empty directories"
 }
 
 usage()

-- 
2.30.2

