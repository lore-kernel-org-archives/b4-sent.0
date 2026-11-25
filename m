From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 25 Nov 2026 10:40:51 +0100
Subject: [PATCH] sysctl: Test rounding behaviour in jiffy-ms transformation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-lklm-jiffy_rounding-v1-1-ccf2ddf7bd3a@kernel.org>
X-B4-Tracking: v=1; b=H4sIACKtBmsC/x3MTQ5AMBBA4avIrDXRoSSuIiLolPFT0oYQcXeN5
 bd47wFPjslDGT3g6GTPmw2QcQT92NqBBOtgwARzKVGJZV5WMbExd+O2w2q2g+iyHAulO0WYQih
 3R4av/1rV7/sBEgGHdmUAAAA=
X-Change-ID: 20261125-lklm-jiffy_rounding-b46275db5e23
To: Kees Cook <kees@kernel.org>, Avi Weiss <thnkslprpt@gmail.com>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4128;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=RpJAkbVCo3PiYqOJBu0qHd458RHdZ3KqXhVVUhOgvQ4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsGrSQ6ZjTQW/We47+1WsXkCJbRiidHpMEGS
 lr2z3gOOCCzTIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrBq0kAAoJELqXzVK3
 lkFP+jYL/is73B+3x3Osc7NEipbbmNU9I5mXOvA209ipSqD1KBtjF7DGJMiIGvZ6d+KMOFqKXe5
 3mbamOYNw0Pud0yvxoMRYzV6hH0fw1q7a2Ld9ZSwd5Dc63kfTpfZCfcWlsb7nFi8TB2F8ktCatX
 70m5sHYTAU80Vg+AruwwQMG10TPQZSDUDdbZxTotXlot4V4Sd6bwcgEy15wG9HGD3UzLB9tOh4Z
 4EdrSVAMTlzajZootfipaLg3dhy93Y9QLQTebbZqddtkyyLUqwuUg1wmcCsl9SrZKILnFe5VN1D
 7OsaVtC+4GmrJCRF4zqch9jUl1HRdJA8McAWUWwxxSyCRQ03kqwy1+9QJ7U7+f40uNIHv75mqa0
 JUwVzht7FhMsQhbOhweq7aeQZ4VmwQQUGxFRLli4GdWhkV8d2VfX9b0/M0Ar2S4KSfwI/1KFLye
 HLjn+AfsKqWTo10e9we7E0+lH8SEh4V6HqKShfB4jPGIQI4TA07MdLX4OTbFtrcflrjGOd49bT7
 JA=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add two tests over int_ms_jiffies and ulong_ms_jiffies:

1. roundup_on_write writes 1 ms and requires the read to be at least 1.
   One millisecond is exact at HZ=1000 and rounds up to one jiffy below
   that, reading back as 10, 4 and 3 ms at HZ=100, 250 and 300.
2. stable_rewrite writes a random ms value, writes back what it reads,
   and requires the second read to match the first.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
These tests make sure that the fix that was recently merged [1], stays
fixed.

[1] https://lore.kernel.org/all/awH4Fh-XofdwwRqZ@hobbes
---
 lib/test_sysctl.c                        | 13 ++++++++-
 tools/testing/selftests/sysctl/sysctl.sh | 50 ++++++++++++++++++++++++++++++++
 2 files changed, 62 insertions(+), 1 deletion(-)

diff --git a/lib/test_sysctl.c b/lib/test_sysctl.c
index 65ce423461707170367a5df14999b571705251d0..40da8748c2ad283a8ac9fa9b859e8556e2dc3564 100644
--- a/lib/test_sysctl.c
+++ b/lib/test_sysctl.c
@@ -29,6 +29,7 @@
 
 static int i_zero;
 static int i_one_hundred = 100;
+static unsigned long ul_one = 1;
 static int match_int_ok = 1;
 
 enum {
@@ -52,6 +53,7 @@ struct test_sysctl_data {
 	int int_jiffies;
 	int int_ms_jiffies;
 	int int_userhz_jiffies;
+	ulong ulong_ms_jiffies;
 
 	unsigned int uint_0001;
 
@@ -72,10 +74,11 @@ static struct test_sysctl_data test_data = {
 
 	.boot_int = 0,
 
-	/* One second in each converter's unit; all three store HZ jiffies. */
+	/* One second in each converter's unit; all four store HZ jiffies. */
 	.int_jiffies = HZ,
 	.int_ms_jiffies = HZ,
 	.int_userhz_jiffies = HZ,
+	.ulong_ms_jiffies = HZ,
 
 	.uint_0001 = 314,
 
@@ -144,6 +147,14 @@ static const struct ctl_table test_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec_userhz_jiffies,
 	},
+	{
+		.procname	= "ulong_ms_jiffies",
+		.data		= &test_data.ulong_ms_jiffies,
+		.maxlen		= sizeof(ulong),
+		.mode		= 0644,
+		.proc_handler	= proc_doulongvec_ms_jiffies_minmax,
+		.extra1		= &ul_one,
+	},
 	{
 		.procname	= "uint_0001",
 		.data		= &test_data.uint_0001,
diff --git a/tools/testing/selftests/sysctl/sysctl.sh b/tools/testing/selftests/sysctl/sysctl.sh
index ad1ee0fccd7cefb066caf23d8aad42abfa046ba0..d24ac6c5a027248afbad4ee0331800fb00aa8978 100755
--- a/tools/testing/selftests/sysctl/sysctl.sh
+++ b/tools/testing/selftests/sysctl/sysctl.sh
@@ -351,6 +351,56 @@ test_int_jiffies_negative()
 	assert_content "$t" "1" || RET=$KSFT_FAIL
 }
 
+# Writing 1 ms reads back 10, 4, 3 and 1 ms at HZ=100, 250, 300 and 1000
+# respectively. Here we make sure that it is >= to 1.
+test_jiffies_conv_roundup_on_write()
+{
+	local m="${SYSCTL}/int_ms_jiffies"
+	local l="${SYSCTL}/ulong_ms_jiffies"
+	local f got
+
+	[[ -f "$m" && -f "$l" ]] || { RET=$KSFT_SKIP; return; }
+
+	for f in "$m" "$l"; do
+		if ! printf '%s' "1" > "$f" 2>/dev/null; then
+			ktap_print_msg "$f: write of 1 rejected"
+			RET=$KSFT_FAIL
+			continue
+		fi
+		got=$(cat "$f")
+		if [[ ! "$got" =~ ^[0-9]+$ ]] || (( got < 1 )); then
+			ktap_print_msg "$f: wrote 1, got '$got', want >= 1"
+			RET=$KSFT_FAIL
+		fi
+	done
+}
+
+# Check that writing back what was just read does not change it again.
+test_jiffies_conv_stable_rewrite()
+{
+	local m="${SYSCTL}/int_ms_jiffies"
+	local l="${SYSCTL}/ulong_ms_jiffies"
+	local orig=$RANDOM
+	local f first
+
+	[[ -f "$m" && -f "$l" ]] || { RET=$KSFT_SKIP; return; }
+
+	for f in "$m" "$l"; do
+		if ! printf '%s' "$orig" > "$f" 2>/dev/null; then
+			ktap_print_msg "$f: write of $orig rejected"
+			RET=$KSFT_FAIL
+			continue
+		fi
+		first=$(cat "$f")
+		if ! printf '%s' "$first" > "$f" 2>/dev/null; then
+			ktap_print_msg "$f: rewrite of '$first' rejected"
+			RET=$KSFT_FAIL
+			continue
+		fi
+		assert_content "$f" "$first" || RET=$KSFT_FAIL
+	done
+}
+
 test_uint_plain()
 {
 	local t="${SYSCTL}/uint_0001"

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261125-lklm-jiffy_rounding-b46275db5e23

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

