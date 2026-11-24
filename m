From: "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
Date: Tue, 24 Nov 2026 11:43:51 -0500
Subject: [PATCH v2 1/2] kunit: tool: Count failed suites with only skipped
 tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-kunit-v2-v2-1-e1adbcad6b48@student.oaklandcc.edu>
References: <20261124-kunit-v2-v2-0-e1adbcad6b48@student.oaklandcc.edu>
In-Reply-To: <20261124-kunit-v2-v2-0-e1adbcad6b48@student.oaklandcc.edu>
To: Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>
Cc: Rae Moar <raemoar63@gmail.com>, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-kernel@vger.kernel.org, 
 "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795538631; l=2838;
 i=poulin.louis@student.oaklandcc.edu; s=20261123; h=from:subject:message-id;
 bh=xh9sNC2jcUJyidrIOBVwX3s9EcjKEehFHQ3B5Y11RuI=;
 b=0ojOw3R2JUt7QEPqZWNFyndqLiWe91EEeNg+VL2FhuHnfOmjszpQHmB+kSUk3LFhNW+tM1Xw0
 yrrw43AkjtfDVhlYl2AkgOHLvsm5kOSJnJkYq6fZOlPgrHHrdT/Dks7
X-Developer-Key: i=poulin.louis@student.oaklandcc.edu; a=ed25519;
 pk=LwBiuOLz0gqWTufz54rXgw2coado8UrJcWQ13DbYfxw=
X-Endpoint-Received: by B4 Relay for poulin.louis@student.oaklandcc.edu/20261123 with auth_id=1616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A suite can report not ok while all its child cases are skipped.
The parser retains the suite status as FAILURE but counts only the
skipped children. The run status is then derived from those counts and
incorrectly reports SKIPPED.

When a suite reports failure and the child aggregate is SKIPPED, add
a failed count for the suite, as is already done when child aggregate
is SUCCESS. Cover a correctly numbered failing suite with a skipped
child.

Fixes: d65d07cb5b01 ("kunit: tool: improve compatibility of kunit_parser with KTAP specification")
Signed-off-by: Louis H. Poulin II <poulin.louis@student.oaklandcc.edu>
---
 tools/testing/kunit/kunit_parser.py    |  4 +++-
 tools/testing/kunit/kunit_tool_test.py | 13 +++++++++++++
 2 files changed, 16 insertions(+), 1 deletion(-)

diff --git a/tools/testing/kunit/kunit_parser.py b/tools/testing/kunit/kunit_parser.py
index d722874b..dce365d1 100644
--- a/tools/testing/kunit/kunit_parser.py
+++ b/tools/testing/kunit/kunit_parser.py
@@ -694,7 +694,9 @@ def bubble_up_test_results(test: Test) -> None:
 	elif test.counts.get_status() == TestStatus.TEST_CRASHED:
 		test.status = TestStatus.TEST_CRASHED
 
-	if status == TestStatus.FAILURE and test.counts.get_status() == TestStatus.SUCCESS:
+	# Preserve a failing suite result when its children all pass or skip.
+	if (status == TestStatus.FAILURE and
+			test.counts.get_status() in (TestStatus.SUCCESS, TestStatus.SKIPPED)):
 		counts.add_status(status)
 
 def parse_test(lines: LineStream, expected_num: int, log: List[str], is_subtest: bool, printer: Printer) -> Test:
diff --git a/tools/testing/kunit/kunit_tool_test.py b/tools/testing/kunit/kunit_tool_test.py
index 85ae2175..5fd386d0 100755
--- a/tools/testing/kunit/kunit_tool_test.py
+++ b/tools/testing/kunit/kunit_tool_test.py
@@ -265,6 +265,19 @@ class KUnitParserTest(unittest.TestCase):
 		self.assertEqual(kunit_parser.TestStatus.SKIPPED, result.status)
 		self.assertEqual(result.counts, kunit_parser.TestCounts(skipped=5))
 
+	def test_failed_suite_with_skipped_child_fails(self):
+		output = ['KTAP version 1', '1..1',
+			'    KTAP version 1', '    # Subtest: suite', '    1..1',
+			'    ok 1 - case # SKIP reason', 'not ok 1 - suite']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		suite = result.subtests[0]
+		self.assertEqual(kunit_parser.TestStatus.SKIPPED, suite.subtests[0].status)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, suite.status)
+		self.assertEqual(suite.counts,
+			kunit_parser.TestCounts(failed=1, skipped=1))
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, suite.counts)
+
 	def test_ignores_hyphen(self):
 		hyphen_log = _test_data_path('test_strip_hyphen.log')
 		with open(hyphen_log) as file:

-- 
2.56.1

