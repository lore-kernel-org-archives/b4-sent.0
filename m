From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 14:27:54 +0200
Subject: [PATCH v2 3/3] test: button: add test for monitor subcommand
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-button-live-monitor-v2-3-004f47a4a7b1@protonmail.com>
References: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
In-Reply-To: <20261010-b4-button-live-monitor-v2-0-004f47a4a7b1@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, David Heidelberg <david@ixit.cz>, 
 Simon Glass <sjg@chromium.org>, Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791635299; l=1455;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=QehWb3NebKCgyG7BwGaStqQlAJLjXcbgvj4YCLBcWUM=;
 b=UwoeLB13rh8+NZNLOhOX0t2jmyLyq4aXeYxcglZbhkn8bFqITgAPF5dL5xUelM5LOBQPoJ4Qs
 V+SsivmijWsD/wRWCTAADWZTPC7OKWbFdpWnwQvRW5HsEwCOy4iJ3nJ
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Run 'button monitor 200' on sandbox and check that the output lists
button1 and button2 and that the command returns 0 after the timeout.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 test/py/tests/test_button.py | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/test/py/tests/test_button.py b/test/py/tests/test_button.py
index f3f68169e14..494c7956543 100644
--- a/test/py/tests/test_button.py
+++ b/test/py/tests/test_button.py
@@ -37,3 +37,23 @@ def test_button_return_code(ubman):
     response = ubman.run_command('button nonexistent-button; echo rc:$?')
     assert('not found' in response)
     assert('rc:1' in response)
+
+@pytest.mark.boardspec('sandbox')
+@pytest.mark.buildconfigspec('cmd_button')
+def test_button_monitor(ubman):
+    """Test the live monitor shows all buttons and exits on timeout"""
+
+    response = ubman.run_command('button monitor 200; echo rc:$?')
+    assert('Button monitor' in response)
+    assert('button1' in response)
+    assert('button2' in response)
+    assert('rc:0' in response)
+
+@pytest.mark.boardspec('sandbox')
+@pytest.mark.buildconfigspec('cmd_button')
+def test_button_monitor_bad_timeout(ubman):
+    """Test that an invalid monitor timeout is rejected"""
+
+    response = ubman.run_command('button monitor abc; echo rc:$?')
+    assert('Button monitor' not in response)
+    assert('rc:1' in response)

-- 
2.55.0

