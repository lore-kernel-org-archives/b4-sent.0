From: Peter Hutterer <peter.hutterer@who-t.net>
Date: Mon, 22 Dec 2025 09:43:35 +1000
Subject: [PATCH v2 2/4] selftests/hid: require hidtools 0.12
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-wip-hid-pressurepad-v2-2-054ac9689bb7@who-t.net>
References: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
In-Reply-To: <20251222-wip-hid-pressurepad-v2-0-054ac9689bb7@who-t.net>
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>, 
 Shuah Khan <shuah@kernel.org>
Cc: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 linux-input@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vadim Klishko <vadim@cirque.com>, 
 Peter Hutterer <peter.hutterer@who-t.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766360621; l=1582;
 i=peter.hutterer@who-t.net; s=20251222; h=from:subject:message-id;
 bh=fQfZ3bxD/S+hRVj/cWNhZRvET046tgfhHw/kZkeYAeY=;
 b=Irf3O3Ipe4uzQyaldbyIlJrFDIdATLmhxOxoFK34R4jPutdlLj+xqvfUayd2FfGJSlaVrs57k
 3T3JnOS2PzlCswCpdK9yGzd1KHN3kAWnapvEox5b8+UOSC/cCFFxij+
X-Developer-Key: i=peter.hutterer@who-t.net; a=ed25519;
 pk=QoL66HDbFudb9Xt36p2XxsSohZSHVHesRR9c0pI28a4=
X-Endpoint-Received: by B4 Relay for peter.hutterer@who-t.net/20251222 with auth_id=582
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Not all our tests really require it but since it's likely pip-installed
anyway it's trivial to require the new version, just in case we want to
start cleaning up other bits.

Signed-off-by: Peter Hutterer <peter.hutterer@who-t.net>
---
 tools/testing/selftests/hid/tests/conftest.py | 14 ++++++++++++++
 1 file changed, 14 insertions(+)

diff --git a/tools/testing/selftests/hid/tests/conftest.py b/tools/testing/selftests/hid/tests/conftest.py
index 1361ec981db6f79a58cf91e8732dcd7c05c47d38..985a535324b2fbe322e754e561d7af6898345b27 100644
--- a/tools/testing/selftests/hid/tests/conftest.py
+++ b/tools/testing/selftests/hid/tests/conftest.py
@@ -5,6 +5,7 @@
 # Copyright (c) 2017 Benjamin Tissoires <benjamin.tissoires@gmail.com>
 # Copyright (c) 2017 Red Hat, Inc.
 
+from packaging.version import Version
 import platform
 import pytest
 import re
@@ -14,6 +15,19 @@ from .base import HIDTestUdevRule
 from pathlib import Path
 
 
+@pytest.fixture(autouse=True)
+def hidtools_version_check():
+    HIDTOOLS_VERSION = "0.12"
+    try:
+        import hidtools
+
+        version = hidtools.__version__  # type: ignore
+        if Version(version) < Version(HIDTOOLS_VERSION):
+            pytest.skip(reason=f"have hidtools {version}, require >={HIDTOOLS_VERSION}")
+    except Exception:
+        pytest.skip(reason=f"hidtools >={HIDTOOLS_VERSION} required")
+
+
 # See the comment in HIDTestUdevRule, this doesn't set up but it will clean
 # up once the last test exited.
 @pytest.fixture(autouse=True, scope="session")

-- 
2.51.1

