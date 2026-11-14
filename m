From: Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
Subject: [PATCH 0/2] docs: kdoc: print each warning once, and only for
 selected symbols
Date: Sat, 14 Nov 2026 11:44:07 +0530
Message-Id: <20261114-kdoc-dup-warnings-v1-0-265f89bc3f9c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqAIBBA4avErBtQqZSuEi0sJxsCC6UfkO6et
 PwW72VIFJkS9FWGSBcn3kOBrCuYVxs8IbtiUEJ1UsoGN7fP6M4DbxsDB59Qm3ZprFaTER2U7oi
 08PM/h/F9P+AheKtjAAAA
X-Change-ID: 20261114-kdoc-dup-warnings-785f4a72b806
To: Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794636849; l=2326;
 i=prateekshitjaiswal73@gmail.com; s=20261107; h=from:subject:message-id;
 bh=C0QJf4U5Htgu11IVU42m2nZfMKlhIuaCFFa1KyLlrkk=;
 b=IawUYJmxMUmFL3JoQP20+VPu0XF5cLr4LaidJlb4FNZAigCaq9QPv4XYldITNpYc2fVzFh2ii
 oBkzQ8YlqqlDp1cZM2DendDpjBwigGFpn8l/+2G3WzMkxbvawPCMa+W
X-Developer-Key: i=prateekshitjaiswal73@gmail.com; a=ed25519;
 pk=Z9QqjsqOUk3AvD5zQ8B+Kufufuvk9wEO7eT9m1nMJdo=
X-Endpoint-Received: by B4 Relay for prateekshitjaiswal73@gmail.com/20261107 with auth_id=1445
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kernel-doc currently prints every documented symbol's warnings twice.
With -function or -export it also warns about symbols that were not
asked for. Both come from the parser flushing warnings of entries it
mistakenly treats as discarded; patch 2 stops that.

Doing only that would uncover an older bug: the output step never
prints warnings for symbols selected with -function or -export.
Patch 1 restores those first, so nothing is lost at any point in the
series.

Testing:
- tools/unittests/run.py passes after each patch. Without patch 1,
  the new OutputFilterWarnings tests for selected and exported symbols
  fail; without patch 2, test_stored_entry fails.
- Warnings printed for intel_dkl_phy.c, before and after the series:
  -Wall: 2 and 1; -function intel_dkl_phy_read: 1 and 1;
  -function intel_dkl_phy_write: 1 and 0;
  -nosymbol intel_dkl_phy_read: 1 and 0.
- kernel-doc -none -Wall over the 10320 .c and .h files with kernel-doc
  comments: 87900 and 49625 output lines, with the same 48026 distinct
  lines.
- The two "Excess struct member" warnings for page_pool_params, which
  Documentation/networking/page_pool.rst pulls in with :identifiers:,
  are still printed, once each.

Notes:
- The new tests patch config.warning directly. MockKdocConfig.warning()
  is never called, because KdocConfig.__init__() sets self.warning as
  an instance attribute that shadows it, so the MockLogging handler
  does not see config.warning() messages. I can send a separate fix for
  that.
- Plain --yaml output never printed warnings itself, so with patch 2
  it no longer shows the warnings of stored entries. With -rst or -man
  they are still printed, once, by the embedded output formats.

---
Prateekshit Jaiswal (2):
      docs: kdoc: emit warnings for symbols selected with -function/-export
      docs: kdoc: don't print warnings of stored entries twice

 tools/lib/python/kdoc/kdoc_output.py |   1 +
 tools/lib/python/kdoc/kdoc_parser.py |   4 +-
 tools/unittests/test_kdoc_parser.py  | 126 +++++++++++++++++++++++++++++++++++
 3 files changed, 130 insertions(+), 1 deletion(-)
---
base-commit: 2138148bf44fd84d3e0a863f0e8cb3627cdcc606
change-id: 20261114-kdoc-dup-warnings-785f4a72b806

Best regards,
-- 
Prateekshit Jaiswal <prateekshitjaiswal73@gmail.com>

