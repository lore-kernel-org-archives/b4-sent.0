From: Daniil Matus <matus.daniil@gmail.com>
Date: Thu, 26 Nov 2026 18:34:27 +0300
Subject: [PATCH RESEND v2] kunit: tool: Preserve suite ancestry in JUnit
 test identities
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-kunit-junit-classname-resend-v2-1-9b64a461fd86@gmail.com>
X-B4-Tracking: v=1; b=H4sIAIJRCGsC/y2OwW7CMBBEfwXtua6wKaGphNQIgioOSKGHHioOj
 lkSA7FTb8ClKP/e2O1lpHmzeto7EDqNBC+jOzi8atLWDEU8jEDV0lTI9H7oIMYi4Vwk7HQxumP
 HmOosiYxskDkkNHs2TcaSH1KphOIwKFqHB/0d9Z+wzd/zzRJ2f5wu5RFVF9zhspSErHTSqDqgf
 1+gYa01ddbd4pdXHm2LbI3ZCtupr7pt++azjcWv9ekjnzzf5ulPUaQ4a2zh2cTlT7Ny7lf+tZH
 6/FjFVLaBXd/3v/FwwncBAQAA
X-Change-ID: 20261126-kunit-junit-classname-resend-560a1f9ac2c1
In-Reply-To: <CAJeAFep5wgtRpHwANoeqJkWE38y=9zQQ9e7moQw-3rE47b=wFw@mail.gmail.com>
References: <CAJeAFep5wgtRpHwANoeqJkWE38y=9zQQ9e7moQw-3rE47b=wFw@mail.gmail.com>
To: David Gow <david@davidgow.net>, 
 Brendan Higgins <brendan.higgins@linux.dev>
Cc: =?utf-8?q?Thomas_Wei=C3=9Fschuh?= <thomas.weissschuh@linutronix.de>, 
 Rae Moar <raemoar63@gmail.com>, kunit-dev@googlegroups.com, 
 Shuah Khan <skhan@linuxfoundation.org>, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795707284; l=4395;
 i=matus.daniil@gmail.com; s=kunit-20261126; h=from:subject:message-id;
 bh=guR65c33Yy6aOn8l/8tEcwaApr1EtihpO6MCIUvqnig=;
 b=OAlOK6QD2zDRU86EtZTjHU+7BGEvLys9zTcQJMeqtmHEgE/MucNHt/p6naj4j4nQ+mI/tn+9S
 lfggROcFKXgDuv/TKWgdJS+fHPcCgcuS4sZ8uMXchaANYix+YCXs2RJ
X-Developer-Key: i=matus.daniil@gmail.com; a=ed25519;
 pk=fz9V2/QhKszS4ZwqnIRXMj1O2LdUSQGVUgqGmMdZk0o=
X-Endpoint-Received: by B4 Relay for matus.daniil@gmail.com/kunit-20261126 with auth_id=1654
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Daniil Matus <matus.daniil@mail.ru>

JUnit testcases currently carry only a name. A parameterized KUnit test
becomes a nested testsuite named after the test function. Reusing that
function in several outer suites therefore produces the same immediate
suite name and parameter name in each of them.

For example, cs_dsp_test_run_stop_callbacks is registered in four cs_dsp
callback suites with the same "all ops" parameter. GitLab identifies cases
by suite name, classname and testcase name. Without a classname, these
distinct cases have identical keys in the imported report.

Set classname to the dot-separated ancestor suite names, including the
parser's main root. Preserve the existing suite hierarchy, testcase names,
statuses and logs. Add a regression using the existing nested log fixture,
whose seven testcases otherwise have only five distinct identity tuples.

Validation: all 92 kunit_tool_test.py tests pass. The new regression fails
on the unmodified generator. Comparing all 24 log fixtures shows no XML
changes other than the added classname attributes.

Fixes: e9e05c72752f ("kunit: tool: Add (primitive) support for outputting JUnit XML")
Signed-off-by: Daniil Matus <matus.daniil@mail.ru>
---
The first posting wrapped several diff lines in transit. This resend uses
b4 as David suggested. The code and commit message are unchanged.
---
 tools/testing/kunit/kunit_junit.py     | 10 +++++++---
 tools/testing/kunit/kunit_tool_test.py | 14 ++++++++++++++
 2 files changed, 21 insertions(+), 3 deletions(-)

diff --git a/tools/testing/kunit/kunit_junit.py b/tools/testing/kunit/kunit_junit.py
index 362207035..d5730aebe 100644
--- a/tools/testing/kunit/kunit_junit.py
+++ b/tools/testing/kunit/kunit_junit.py
@@ -10,7 +10,8 @@ from kunit_parser import Test, TestStatus
 from typing import Optional
 
 # Get a string representing a tes suite (including subtests) in JUnit XML
-def get_test_suite(test: Test, parent: Optional[ET.Element]) -> ET.Element:
+def get_test_suite(test: Test, parent: Optional[ET.Element], name_prefix: str = '') -> ET.Element:
+	classname = f'{name_prefix}.{test.name}' if name_prefix else test.name
 	suite_attrs = {
 		'name': test.name,
 		'tests': str(test.counts.total()),
@@ -26,9 +27,12 @@ def get_test_suite(test: Test, parent: Optional[ET.Element]) -> ET.Element:
 
 	for subtest in test.subtests:
 		if subtest.subtests:
-			get_test_suite(subtest, test_suite_element)
+			get_test_suite(subtest, test_suite_element, classname)
 			continue
-		test_case_element = ET.SubElement(test_suite_element, 'testcase', {'name': subtest.name})
+		test_case_element = ET.SubElement(test_suite_element, 'testcase', {
+			'name': subtest.name,
+			'classname': classname,
+		})
 		if subtest.status == TestStatus.FAILURE:
 			ET.SubElement(test_case_element, 'failure', {}).text = 'Test Failed'
 		elif subtest.status == TestStatus.SKIPPED:
diff --git a/tools/testing/kunit/kunit_tool_test.py b/tools/testing/kunit/kunit_tool_test.py
index 85ae21754..d37354c70 100755
--- a/tools/testing/kunit/kunit_tool_test.py
+++ b/tools/testing/kunit/kunit_tool_test.py
@@ -18,6 +18,7 @@ import os
 import signal
 import subprocess
 import sys
+import xml.etree.ElementTree as ET
 from typing import Iterable
 
 import kunit_config
@@ -725,6 +726,19 @@ class KUnitJUnitTest(unittest.TestCase):
 		self.assertTrue("tests=\"0\"" in result)
 		self.assertFalse("testcase" in result)
 
+	def test_nested_test_classnames_junit(self):
+		result = self._junit_string('test_is_test_passed-all_passed_nested.log')
+		testcases = ET.fromstring(result).iter('testcase')
+		self.assertEqual([
+			('main.sysctl_test', 'sysctl_test_dointvec_null_tbl_data'),
+			('main.sysctl_test.example', 'example_simple_test'),
+			('main.sysctl_test.example', 'example_mock_test'),
+			('main.sysctl_test', 'sysctl_test_dointvec_table_len_is_zero'),
+			('main.sysctl_test', 'sysctl_test_dointvec_table_read_but_position_set'),
+			('main.example', 'example_simple_test'),
+			('main.example', 'example_mock_test'),
+		], [(case.get('classname'), case.get('name')) for case in testcases])
+
 
 class KUnitMainTest(unittest.TestCase):
 	def setUp(self):

---
base-commit: 97d73c8251226cf27cc6656b4c542869bb8c69fa
change-id: 20261126-kunit-junit-classname-resend-560a1f9ac2c1

Best regards,
--  
Daniil Matus <matus.daniil@gmail.com>

