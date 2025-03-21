From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 21 Mar 2025 13:47:25 +0100
Subject: [PATCH 2/4] sysctl: Add 0012 to test the u8 range check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250321-jag-test_extra_val-v1-2-a01b3b17dc66@kernel.org>
References: <20250321-jag-test_extra_val-v1-0-a01b3b17dc66@kernel.org>
In-Reply-To: <20250321-jag-test_extra_val-v1-0-a01b3b17dc66@kernel.org>
To: Kees Cook <kees@kernel.org>, Andrew Morton <akpm@linux-foundation.org>, 
 Shuah Khan <shuah@kernel.org>, John Sperbeck <jsperbeck@google.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2105;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=++XbEfpnPeqQ4moIezitAVfEJDIk+P74wNcs5SRzozU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGfdYAj+wL7uNtMJMtN+SaEhFHsQNTYvxgciq
 qT1UQ+ymTaQb4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJn3WAIAAoJELqXzVK3
 lkFP8xcL/00KbQvm8zlN6hup0eFPPsksVlQqhtagFA/g4+ODy/KvMy4YItrC1ixaN9bIjyAMSov
 2iUFQsO8VB6PaFjajRJyasZ5ntXMAGUgeAGHUBdrt8nTnmsIjM8tgxpbHWUJglbspBbtn3jVzLW
 XWbNt9UNb0X9QtFAj1H5oT06dlhtNZgFggUZW2AnYBNl5gbYxtW1LIYCXqbZ9hph1P5O7Y+qGIS
 jpcYS3B6QgdDgj2WCgUPk8i2atXV6p1gR1gDRxT6mQ/2Hi192I45JCF2klRJptybB4D2oKgRQXK
 gUhlNCdkdjltM4Yk152o8cKH0Tq1/QVLgnLAh8Iq2wh8rzLdUg9n1/x4h6wp1TAPYnV2ue65O7X
 mh8FGedySrH9q6xqR0wH3eS5nIFbwEEHvPeT4CWuYRml6xD79pB8EVEHBwj8UUlnyhykZhDe01W
 fX/BxHfIRKD+xnCkKj9+WG0AJDJGB+yl7cvrcKjdxauOb1gVxBne5+Oyzjf/T0t1+r3LT4+unA5
 Gs=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a sysctl test that uses the new u8 test ctl files in a created by
the sysctl test module. Check that the u8 proc file that is valid is
created and that there are two messages in dmesg for the files that were
out of range.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 tools/testing/selftests/sysctl/sysctl.sh | 30 ++++++++++++++++++++++++++++++
 1 file changed, 30 insertions(+)

diff --git a/tools/testing/selftests/sysctl/sysctl.sh b/tools/testing/selftests/sysctl/sysctl.sh
index 84472b436c07faf43e555999951e554f8e1a60c5..22b53c263dd4525ee8d4655272d6842e5249a7dc 100755
--- a/tools/testing/selftests/sysctl/sysctl.sh
+++ b/tools/testing/selftests/sysctl/sysctl.sh
@@ -36,6 +36,7 @@ ALL_TESTS="$ALL_TESTS 0008:1:1:match_int:1"
 ALL_TESTS="$ALL_TESTS 0009:1:1:unregister_error:0"
 ALL_TESTS="$ALL_TESTS 0010:1:1:mnt/mnt_error:0"
 ALL_TESTS="$ALL_TESTS 0011:1:1:empty_add:0"
+ALL_TESTS="$ALL_TESTS 0012:1:1:u8_valid:0"
 
 function allow_user_defaults()
 {
@@ -851,6 +852,34 @@ sysctl_test_0011()
 	return 0
 }
 
+sysctl_test_0012()
+{
+	TARGET="${SYSCTL}/$(get_test_target 0012)"
+	echo -n "Testing u8 range check in sysctl table check in ${TARGET} ... "
+	if [ ! -f ${TARGET} ]; then
+		echo -e "FAIL\nCould not create ${TARGET}" >&2
+		rc=1
+		test_rc
+	fi
+
+	local u8over_msg=$(dmesg | grep "u8_over range value" | wc -l)
+	if [ ! ${u8over_msg} -eq 1 ]; then
+		echo -e "FAIL\nu8 overflow not detected" >&2
+		rc=1
+		test_rc
+	fi
+
+	local u8under_msg=$(dmesg | grep "u8_under range value" | wc -l)
+	if [ ! ${u8under_msg} -eq 1 ]; then
+		echo -e "FAIL\nu8 underflow not detected" >&2
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
@@ -870,6 +899,7 @@ list_tests()
 	echo "0009 x $(get_test_count 0009) - tests sysct unregister"
 	echo "0010 x $(get_test_count 0010) - tests sysct mount point"
 	echo "0011 x $(get_test_count 0011) - tests empty directories"
+	echo "0012 x $(get_test_count 0012) - tests range check for u8 proc_handler"
 }
 
 usage()

-- 
2.47.2

