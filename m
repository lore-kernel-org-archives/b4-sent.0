From: "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
Subject: [PATCH v2 0/2] kunit: tool: Preserve failures in parsed KTAP
 results
Date: Tue, 24 Nov 2026 11:43:50 -0500
Message-Id: <20261124-kunit-v2-v2-0-e1adbcad6b48@student.oaklandcc.edu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHQUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMT3ezSvMwS3TIj3RQDi1QzS0szCzNzIyWg8oKi1LTMCrBR0bG1tQB
 9Lc+LWgAAAA==
X-Change-ID: 20261124-kunit-v2-d08e69968672
To: Brendan Higgins <brendan.higgins@linux.dev>, 
 David Gow <david@davidgow.net>
Cc: Rae Moar <raemoar63@gmail.com>, linux-kselftest@vger.kernel.org, 
 kunit-dev@googlegroups.com, linux-kernel@vger.kernel.org, 
 "Louis H. Poulin II" <poulin.louis@student.oaklandcc.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795538631; l=1626;
 i=poulin.louis@student.oaklandcc.edu; s=20261123; h=from:subject:message-id;
 bh=FMmuGf0BvxD0W/kVIvoDe3PsvdyB9kbT8Oxfr84qE2A=;
 b=R/6HJuE+JO6Wx1KCO8BgcX6FZE6aa2X3Rvu4wlCprUZwj+kKrgu17Au3kouPr40TRp1JSvJ+Y
 4wbeMPw5Du6A0CVyEIQ0own1xh0BDIFU4GpSTjxToTP3TXJe+XqjMaS
X-Developer-Key: i=poulin.louis@student.oaklandcc.edu; a=ed25519;
 pk=LwBiuOLz0gqWTufz54rXgw2coado8UrJcWQ13DbYfxw=
X-Endpoint-Received: by B4 Relay for poulin.louis@student.oaklandcc.edu/20261123 with auth_id=1616
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The KUnit tool's saved-log parser does not consistently propagate two
failure conditions. A suite reporting not ok with only skipped children
leaves the run SKIPPED. A result with an out-of-sequence number can
still be counted as successful, so kunit.py parse may exit 0 for that
malformed log.

Patch 1 preserves the suite's reported failure in aggregate counts.
Patch 2 marks out-of-sequence result records as failed. It depends on
patch 1 for a malformed parent suite whose child tests are all skipped.

Tested: kunit_tool_test.py (100 tests, all pass) and strict checkpatch
on both patches. No live kernel run was performed.

Changes in v2:
- Resend using b4; v1 was mangled by line wrapping in the mail client
  (reported by David Gow).
- Rebase onto v7.4-rc1; no changes under tools/testing/kunit since v1.
- Patch 1: move the Fixes: tag adjacent to Signed-off-by:. No code change.
- Patch 2: no change.

v1: https://lore.kernel.org/r/CAGQButum4PYb4A%2Bhmqg-bJZbf4L3KkH6rT9tn-0_NTs3xLhGYw@mail.gmail.com

Signed-off-by: Louis H. Poulin II <poulin.louis@student.oaklandcc.edu>
---
Louis H. Poulin II (2):
      kunit: tool: Count failed suites with only skipped tests
      kunit: tool: Fail on out-of-sequence test numbers

 tools/testing/kunit/kunit_parser.py    | 15 +++---
 tools/testing/kunit/kunit_tool_test.py | 92 ++++++++++++++++++++++++++++++++--
 2 files changed, 98 insertions(+), 9 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261124-kunit-v2-d08e69968672

Best regards,
-- 
Louis H. Poulin II <poulin.louis@student.oaklandcc.edu>

