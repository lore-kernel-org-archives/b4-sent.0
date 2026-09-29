From: Simon Sudarushkin <simonsudarushkin@gmail.com>
Date: Tue, 29 Sep 2026 20:50:32 +0500
Subject: [PATCH] kunit: tool: report executor errors when listing tests
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-kunit-list-errors-v1-1-16bf855e2ec3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB1IIoTqVYoLjWM7tcQyE0UQ7
 26qy7f4fwclYVJoih2EVlaeY4YtCwjvLr4IecgGZ5w3tatxWiIn/LImJJFZFH0VbF8Z7x/WQe5
 +QiNv1/PZ3tal/1BI/xEcxwmVASRgdQAAAA==
X-Change-ID: 20260929-kunit-list-errors-63c1b3066812
To: Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>, Rae Moar <raemoar63@gmail.com>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: linux-kselftest@vger.kernel.org, kunit-dev@googlegroups.com, 
 linux-kernel@vger.kernel.org, 
 Simon Sudarushkin <simonsudarushkin@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790697071; l=6951;
 i=simonsudarushkin@gmail.com; s=20260929; h=from:subject:message-id;
 bh=WISOKMy68itHiwuQRD0Fmjjiui3rz30qfn+eKl1cbEg=;
 b=2hMvzP9MHwfL3ht8v7Ws1fJh00YzKB+GZ4aNPMQ1ISqxKx64d4UVbVckhrceLlFRU2LbpB8oC
 HFNoguCEPH/AY1vr10POZLabd8eQEMQTxLWKAj3qU6s90J3QxIC41Qq
X-Developer-Key: i=simonsudarushkin@gmail.com; a=ed25519;
 pk=yr+Zf16IVZZq8kE1LwDB48Z/iOOIAkvBRA07CDmvH2M=
X-Endpoint-Received: by B4 Relay for simonsudarushkin@gmail.com/20260929 with auth_id=1081
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

--list_tests, --list_suites, --list_tests_attr and --run_isolated first
ask the kernel for the list of tests. extract_tap_lines() keeps the
"kunit executor:" lines printed before the KTAP header, but the list
code then drops the first line as the dummy header and filters the rest
by name, so an executor error is silently lost:

  $ ./tools/testing/kunit/kunit.py run --list_tests --filter 'nosuchattr=1'
  ...
  $ echo $?
  0

The kernel log has "attribute not found: nosuchattr=1" and "error
filtering suites: -22", while a normal run with the same filter reports
the error and exits with 1. If the kernel prints no KTAP output at all,
the same pop() raises ValueError and kunit.py exits with a traceback.

Move the code shared by _list_tests() and _list_tests_attr() into
_run_list_action(), which raises ListError on executor errors or when
there is no KTAP output. exec_tests() prints the error and returns
TEST_FAILURE, as a normal run does.

Fixes: ff9e09a3762f ("kunit: tool: support running each suite/test separately")
Fixes: 723c8258c8fe ("kunit: tool: Add command line interface to filter and report attributes")
Assisted-by: LLM
Signed-off-by: Simon Sudarushkin <simonsudarushkin@gmail.com>
---
Tested with kunit.py on arm64 (QEMU with KVM): a bad --filter now prints
both executor errors and exits with 1 for --list_tests and
--run_isolated, while normal listing, --list_suites, --list_tests_attr
and --run_isolated=suite behave as before. In run_checks.py,
kunit_tool_test.py and mypy pass; the UML smoke test could not be run,
as UML does not build on this arm64 host (it fails the same way
without this patch).
---
 tools/testing/kunit/kunit.py           | 57 +++++++++++++++++++++-------------
 tools/testing/kunit/kunit_tool_test.py | 18 +++++++++++
 2 files changed, 54 insertions(+), 21 deletions(-)

diff --git a/tools/testing/kunit/kunit.py b/tools/testing/kunit/kunit.py
index 91d234ac3b579..6db09144d7cfc 100755
--- a/tools/testing/kunit/kunit.py
+++ b/tools/testing/kunit/kunit.py
@@ -109,8 +109,12 @@ def config_and_build_tests(linux: kunit_kernel.LinuxSourceTree,
 
 	return build_tests(linux, request)
 
-def _list_tests(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest) -> List[str]:
-	args = ['kunit.action=list']
+class ListError(Exception):
+	"""Represents an error from the kernel while listing tests."""
+
+
+def _run_list_action(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest, action: str) -> List[str]:
+	args = ['kunit.action=' + action]
 
 	if request.kernel_args:
 		args.extend(request.kernel_args)
@@ -121,31 +125,34 @@ def _list_tests(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest)
 			   filter=request.filter,
 			   filter_action=request.filter_action,
 			   build_dir=request.build_dir)
-	lines = kunit_parser.extract_tap_lines(output)
+	stream = kunit_parser.extract_tap_lines(output)
+	lines = []  # type: List[str]
+	errors = []  # type: List[str]
+	while stream:
+		line = stream.pop()
+		match = kunit_parser.EXECUTOR_ERROR.search(line)
+		if match:
+			errors.append(match.group(0).strip())
+		else:
+			lines.append(line)
+
+	# The executor reports a bad filter or action instead of listing.
+	if errors:
+		raise ListError('\n'.join(errors))
+	if not lines:
+		raise ListError('Could not find any KTAP output. Did any KUnit tests run?')
+
 	# Hack! Drop the dummy TAP version header that the executor prints out.
-	lines.pop()
+	return lines[1:]
+
+def _list_tests(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest) -> List[str]:
+	lines = _run_list_action(linux, request, 'list')
 
 	# Filter out any extraneous non-test output that might have gotten mixed in.
 	return [l for l in lines if re.match(r'^[^\s.]+\.[^\s.]+$', l)]
 
 def _list_tests_attr(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest) -> Iterable[str]:
-	args = ['kunit.action=list_attr']
-
-	if request.kernel_args:
-		args.extend(request.kernel_args)
-
-	output = linux.run_kernel(args=args,
-			   timeout=request.timeout,
-			   filter_glob=request.filter_glob,
-			   filter=request.filter,
-			   filter_action=request.filter_action,
-			   build_dir=request.build_dir)
-	lines = kunit_parser.extract_tap_lines(output)
-	# Hack! Drop the dummy TAP version header that the executor prints out.
-	lines.pop()
-
-	# Filter out any extraneous non-test output that might have gotten mixed in.
-	return lines
+	return _run_list_action(linux, request, 'list_attr')
 
 def _suites_from_test_list(tests: List[str]) -> List[str]:
 	"""Extracts all the suites from an ordered list of tests."""
@@ -160,6 +167,14 @@ def _suites_from_test_list(tests: List[str]) -> List[str]:
 	return suites
 
 def exec_tests(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest) -> KunitResult:
+	try:
+		return _exec_tests(linux, request)
+	except ListError as e:
+		for line in str(e).splitlines():
+			stdout.print_with_timestamp(stdout.red('[ERROR] ') + line)
+		return KunitResult(status=KunitStatus.TEST_FAILURE, elapsed_time=0.0)
+
+def _exec_tests(linux: kunit_kernel.LinuxSourceTree, request: KunitExecRequest) -> KunitResult:
 	filter_globs = [request.filter_glob]
 	if request.list_tests:
 		output = _list_tests(linux, request)
diff --git a/tools/testing/kunit/kunit_tool_test.py b/tools/testing/kunit/kunit_tool_test.py
index 85ae21754bdf9..d0cb3340a328d 100755
--- a/tools/testing/kunit/kunit_tool_test.py
+++ b/tools/testing/kunit/kunit_tool_test.py
@@ -991,6 +991,24 @@ class KUnitMainTest(unittest.TestCase):
 				     kunit.KunitExecRequest(None, None, None, False, False, '.kunit', 300, 'suite*', '', None, None, 'suite', False, False, False))
 		self.assertEqual(got, want)
 
+	def test_list_tests_executor_error(self):
+		self.linux_source_mock.run_kernel.return_value = [
+			'[    0.100000] kunit executor: attribute not found: nosuchattr=1',
+			'[    0.100000] kunit executor: error filtering suites: -22']
+
+		with self.assertRaises(SystemExit) as e:
+			kunit.main(['exec', '--list_tests'])
+		self.assertEqual(e.exception.code, 1)
+		self.print_mock.assert_any_call(StrContains('attribute not found: nosuchattr=1'))
+
+	def test_list_tests_no_output(self):
+		self.linux_source_mock.run_kernel.return_value = []
+
+		with self.assertRaises(SystemExit) as e:
+			kunit.main(['exec', '--list_suites'])
+		self.assertEqual(e.exception.code, 1)
+		self.print_mock.assert_any_call(StrContains('Could not find any KTAP output'))
+
 	@mock.patch.object(kunit, '_list_tests')
 	def test_run_isolated_by_suite(self, mock_tests):
 		mock_tests.return_value = ['suite.test1', 'suite.test2', 'suite2.test1']

---
base-commit: e38f53f0482468efd04397f66bda4648b70ac9fa
change-id: 20260929-kunit-list-errors-63c1b3066812

Best regards,
--  
Simon Sudarushkin <simonsudarushkin@gmail.com>

