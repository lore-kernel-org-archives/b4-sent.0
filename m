From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Wed, 14 Feb 2024 22:01:26 +0000
Subject: [PATCH BlueZ 3/4] build: drop %.rules make rule
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240214-hook-fixup-v1-3-0e158ffea140@gmail.com>
References: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
In-Reply-To: <20240214-hook-fixup-v1-0-0e158ffea140@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707948093; l=1176;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=IVYTUizQHoCmhehLtiA9Zi1WMPZ5FTKhQFWT9gvpdBU=;
 b=461SVuM4K0438sRUXtx6E81zgpURXT7OCxk7ZdNSzOd1QiFwNhLfdVra27u3wtgTctzs5vXpn
 qTg2Hpru26ZB1W/+BYmCa10tnA7BH/vsCW+udLIvGwkB70RCzr2dkoh
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's a single file, so we can drop the makefile rule and rename it
accordingly.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 Makefile.am                               | 8 +-------
 tools/{hid2hci.rules => 97-hid2hci.rules} | 0
 2 files changed, 1 insertion(+), 7 deletions(-)

diff --git a/Makefile.am b/Makefile.am
index e67551761..b0845e707 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -435,11 +435,9 @@ if HID2HCI
 rulesdir = $(UDEV_DIR)/rules.d
 
 rules_DATA = tools/97-hid2hci.rules
-
-CLEANFILES += $(rules_DATA)
 endif
 
-EXTRA_DIST += tools/hid2hci.rules
+EXTRA_DIST += tools/97-hid2hci.rules
 
 if TEST
 testdir = $(pkglibdir)/test
@@ -764,10 +762,6 @@ endif
 src/builtin.h: src/genbuiltin $(builtin_sources)
 	$(AM_V_GEN)$(srcdir)/src/genbuiltin $(builtin_modules) > $@
 
-tools/%.rules:
-	$(AM_V_at)$(MKDIR_P) tools
-	$(AM_V_GEN)cp $(srcdir)/$(subst 97-,,$@) $@
-
 $(lib_libbluetooth_la_OBJECTS): $(local_headers)
 
 lib/bluetooth/%.h: lib/%.h
diff --git a/tools/hid2hci.rules b/tools/97-hid2hci.rules
similarity index 100%
rename from tools/hid2hci.rules
rename to tools/97-hid2hci.rules

-- 
2.43.1

