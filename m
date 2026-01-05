From: Louis Rannou <louis.rannou@non.se.com>
Subject: [PATCH 0/4] oeqa: selftest: split and create a library
Date: Mon, 05 Jan 2026 11:49:25 +0100
Message-Id: <20260105-fitimage-v1-0-e319258c4c4f@non.se.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADWXW2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQwNT3bTMkszcRKC4mYFlUrKZmWViUnKiElB5QVFqWmYF2Kjo2NpaAKh
 rYmlaAAAA
To: openembedded-core@lists.openembedded.org
Cc: Louis Rannou <louis.rannou@non.se.com>, adrian.freihofer@siemens.com, 
 pascal.eberhard@se.com
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767610172; l=1173;
 i=louis.rannou@non.se.com; s=20250630; h=from:subject:message-id;
 bh=3c4rghs/a1/J0a/fdr2Q2xPSkftzboHq5wuSJ8l4CNo=;
 b=xMmt4hmfoMdXDEonFldHx61j8hBrg4ti1iIFoKBMA/YBACajSiiQ7gsXwNIWkxd7vvQJcF8L3
 a9sAYq8ykYbDcyQ1XqC3hKul3reiID9XOowZXjQ/gJInpLiJYC5cFrG
X-Developer-Key: i=louis.rannou@non.se.com; a=ed25519;
 pk=WWYN5/DFKqyCKdv6oTYNuq0gROqwZVfNfw2OMI3tUlc=
X-Endpoint-Received: by B4 Relay for louis.rannou@non.se.com/20250630 with auth_id=446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Take some generic code from the fitimage selftest to create a library
oeqa.utils.fitimage than can be reused in other tests (such as sanity).

The first commit is a fix for missing spaces and the last is adds support
for rsa4096 signatures.

The two mains commit (2nd and 3rd) are organized to make the diff
easier. The 2nd looks at every generic functions ands remove unittest
relative code. While the 3rd makes the move from selftest to utils, keeping
the same architecture.

Signed-off-by: Louis Rannou <louis.rannou@non.se.com>
---
Louis Rannou (4):
      oeqa/selftests: fitimage: fix missing spaces
      oeqa/selftests: fitimage: prepare for split
      oeqa: fitimage: split the selftest and create a generic library
      oeqa/utils: fitimage: rsa4096 signatures

 meta/lib/oeqa/selftest/cases/fitimage.py | 864 +++---------------------------
 meta/lib/oeqa/utils/fitimage.py          | 883 +++++++++++++++++++++++++++++++
 2 files changed, 961 insertions(+), 786 deletions(-)
---
base-commit: f55407185c63c895fa3c4fdf74e6e63ea9517a20
change-id: 20260105-fitimage-609bc669abca

Best regards,
-- 
Louis Rannou <louis.rannou@non.se.com>

