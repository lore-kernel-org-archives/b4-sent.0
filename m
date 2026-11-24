From: "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
Date: Tue, 24 Nov 2026 11:43:52 -0500
Subject: [PATCH v2 2/2] kunit: tool: Fail on out-of-sequence test numbers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-kunit-v2-v2-2-e1adbcad6b48@student.oaklandcc.edu>
References: <20261124-kunit-v2-v2-0-e1adbcad6b48@student.oaklandcc.edu>
In-Reply-To: <20261124-kunit-v2-v2-0-e1adbcad6b48@student.oaklandcc.edu>
To: Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>
Cc: Rae Moar <raemoar63@gmail.com>, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-kernel@vger.kernel.org, 
 "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795538631; l=7561;
 i=poulin.louis@student.oaklandcc.edu; s=20261123; h=from:subject:message-id;
 bh=9gIm8lwEHUBfPgQsOux5N4mfKiU+6pcgKwtui91p1t4=;
 b=f4nQNOjB4AHdvJL1btW6LZtQfAeiO1Vg0vrOlewhReNYB94rc1wHXYHf9SKuDY3j/MMWwxD6k
 5wmnTQeIjl1DuIN03PB/4/dKhhO0FEhY+a0tBjltfV/jRgYc0OI9Hmv
X-Developer-Key: i=poulin.louis@student.oaklandcc.edu; a=ed25519;
 pk=LwBiuOLz0gqWTufz54rXgw2coado8UrJcWQ13DbYfxw=
X-Endpoint-Received: by B4 Relay for poulin.louis@student.oaklandcc.edu/20261123 with auth_id=1616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

KTAP requires numbering to start at 1 and increase by one at each
nesting level. The parser notes a mismatch as an error but can still
mark an ok or skipped result as successful. A saved log with duplicate
numbers can make kunit.py parse exit 0.

After decoding ok or SKIP, mark a wrongly numbered result as FAILURE.
The result record is malformed even if the test assertion printed ok.
It then contributes to both failed and error counts. This avoids a
broader policy of failing on every parse error, which would also
change late-plan handling. The preceding patch preserves this failure
when a parent suite has only skipped children.

This change covers numbering mismatches only. A missing numbered line
can flag subsequent results whose numbers differ from their expected
positions. Other malformed or truncated logs retain their existing
status policy.

Commit 14e594a1fc8b ("kunit: tool: fix count of tests if late test
plan") deliberately kept a parsed pass despite missing results after
a late plan. Its fixture also had an unrelated ok 4 result. Number
that result as ok 1 to keep the plan test focused, and cover a wrong
first number separately. Add duplicate, SKIP, nested-suite, missing
number and CLI exit-code tests.

Signed-off-by: Louis H. Poulin II <poulin.louis@student.oaklandcc.edu>
---
 tools/testing/kunit/kunit_parser.py    | 11 ++---
 tools/testing/kunit/kunit_tool_test.py | 79 ++++++++++++++++++++++++++++++++--
 2 files changed, 82 insertions(+), 8 deletions(-)

diff --git a/tools/testing/kunit/kunit_parser.py b/tools/testing/kunit/kunit_parser.py
index dce365d1..38547312 100644
--- a/tools/testing/kunit/kunit_parser.py
+++ b/tools/testing/kunit/kunit_parser.py
@@ -423,11 +423,6 @@ def parse_test_result(lines: LineStream, test: Test,
 	else:
 		test.name = match.group(4)
 
-	# Check test num
-	num = int(match.group(2))
-	if num != expected_num:
-		test.add_error(printer, f'Expected test number {expected_num} but found {num}')
-
 	# Set status of test object
 	status = match.group(1)
 	if skip_match:
@@ -437,6 +432,12 @@ def parse_test_result(lines: LineStream, test: Test,
 		test.status = TestStatus.SUCCESS
 	else:
 		test.status = TestStatus.FAILURE
+
+	# A malformed result must not make the run successful.
+	num = int(match.group(2))
+	if num != expected_num:
+		test.add_error(printer, f'Expected test number {expected_num} but found {num}')
+		test.status = TestStatus.FAILURE
 	return True
 
 def parse_diagnostic(lines: LineStream) -> List[str]:
diff --git a/tools/testing/kunit/kunit_tool_test.py b/tools/testing/kunit/kunit_tool_test.py
index 5fd386d0..6a3011de 100755
--- a/tools/testing/kunit/kunit_tool_test.py
+++ b/tools/testing/kunit/kunit_tool_test.py
@@ -410,13 +410,78 @@ class KUnitParserTest(unittest.TestCase):
 	def test_parse_late_test_plan(self):
 		output = """
 		TAP version 13
-		ok 4 test4
+		ok 1 test1
 		1..4
 		"""
 		result = kunit_parser.parse_run_tests(output.splitlines(), stdout)
-		# Missing test results after test plan should alert a suspected test crash.
+		# Keep this test focused on a late plan, not result numbering.
 		self.assertEqual(kunit_parser.TestStatus.SUCCESS, result.status)
-		self.assertEqual(result.counts, kunit_parser.TestCounts(passed=1, errors=2))
+		self.assertEqual(result.counts, kunit_parser.TestCounts(passed=1, errors=1))
+
+	def test_wrong_first_number_fails(self):
+		output = ['KTAP version 1', '1..1', 'ok 4 - fourth']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, kunit_parser.TestCounts(failed=1, errors=1))
+
+	def test_repeated_test_number_fails(self):
+		output = ['KTAP version 1', '1..2', 'ok 1 - first', 'ok 1 - second']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts,
+			kunit_parser.TestCounts(passed=1, failed=1, errors=1))
+
+	def test_missing_number_fails_later_results(self):
+		output = ['KTAP version 1', '1..3',
+			'ok 1 - first', 'ok 3 - third', 'ok 4 - fourth']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts,
+			kunit_parser.TestCounts(passed=1, failed=2, errors=2))
+
+	def test_wrong_numbered_skip_fails(self):
+		output = ['KTAP version 1', '1..1', 'ok 2 - skipped # SKIP reason']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, kunit_parser.TestCounts(failed=1, errors=1))
+
+	def test_wrong_numbered_suite_result_fails(self):
+		output = ['KTAP version 1', '1..1',
+			'    KTAP version 1', '    # Subtest: suite', '    1..1',
+			'    ok 1 - case', 'ok 2 - suite']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		suite = result.subtests[0]
+		self.assertEqual(kunit_parser.TestStatus.SUCCESS, suite.subtests[0].status)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, suite.status)
+		self.assertEqual(suite.counts,
+			kunit_parser.TestCounts(passed=1, failed=1, errors=1))
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, suite.counts)
+
+	def test_wrong_numbered_nested_case_fails(self):
+		output = ['KTAP version 1', '1..1',
+			'    KTAP version 1', '    # Subtest: suite', '    1..1',
+			'    ok 2 - case', 'ok 1 - suite']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		suite = result.subtests[0]
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, suite.subtests[0].status)
+		self.assertEqual(suite.counts,
+			kunit_parser.TestCounts(failed=1, errors=1))
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, suite.counts)
+
+	def test_wrong_numbered_suite_with_skipped_child_fails(self):
+		output = ['KTAP version 1', '1..1',
+			'    KTAP version 1', '    # Subtest: suite', '    1..1',
+			'    ok 1 - case # SKIP reason', 'ok 2 - suite']
+		result = kunit_parser.parse_run_tests(output, stdout)
+		suite = result.subtests[0]
+		self.assertEqual(kunit_parser.TestStatus.SKIPPED, suite.subtests[0].status)
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, suite.status)
+		self.assertEqual(suite.counts,
+			kunit_parser.TestCounts(failed=1, skipped=1, errors=1))
+		self.assertEqual(kunit_parser.TestStatus.FAILURE, result.status)
+		self.assertEqual(result.counts, suite.counts)
 
 def line_stream_from_strs(strs: Iterable[str]) -> kunit_parser.LineStream:
 	return kunit_parser.LineStream(enumerate(strs, start=1))
@@ -797,6 +862,14 @@ class KUnitMainTest(unittest.TestCase):
 		self.assertEqual(self.linux_source_mock.run_kernel.call_count, 1)
 		self.print_mock.assert_any_call(StrContains('Could not find any KTAP output.'))
 
+	def test_parse_duplicate_number_exits_failure(self):
+		with tempfile.NamedTemporaryFile(mode='w+', delete=True) as log:
+			log.write('KTAP version 1\n1..2\nok 1 - first\nok 1 - second\n')
+			log.flush()
+			with self.assertRaises(SystemExit) as result:
+				kunit.main(['parse', log.name])
+		self.assertEqual(result.exception.code, 1)
+
 	def test_exec_no_tests(self):
 		self.linux_source_mock.run_kernel = mock.Mock(return_value=['TAP version 14', '1..0'])
 		with self.assertRaises(SystemExit) as e:

-- 
2.56.1

