From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Fri, 16 Feb 2024 23:11:08 +0000
Subject: [PATCH BlueZ v2 04/10] build: drop %.rules make rule
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240216-hook-fixup-v2-4-a6b192d1a6ad@gmail.com>
References: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
In-Reply-To: <20240216-hook-fixup-v2-0-a6b192d1a6ad@gmail.com>
To: linux-bluetooth@vger.kernel.org
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708125068; l=1456;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=UEsIY+CXqI3XPUWceLYP33aIBNlVaH7L0YL+lTKbmps=;
 b=frTCv+KyKE2uUC+/vkrALuwfcbAYu6WVyB01rUlxWmdIvbryX+PkdSFNkCOwij/XiffbmSXWf
 ++ssiyBQkY0AI+L7VPcNmz51LXJtOURVA+rbTJUpElgxstT8AGsumVw
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's a single file, so we can drop the makefile rule and rename it
accordingly.
---
 .gitignore                                | 2 +-
 Makefile.am                               | 8 +-------
 tools/{hid2hci.rules => 97-hid2hci.rules} | 0
 3 files changed, 2 insertions(+), 8 deletions(-)

diff --git a/.gitignore b/.gitignore
index c5d7f90ab..a5954658a 100644
--- a/.gitignore
+++ b/.gitignore
@@ -37,7 +37,7 @@ lib/bluez.pc
 lib/bluetooth
 src/builtin.h
 src/bluetoothd
-tools/97-hid2hci.rules
+tools/hid2hci.rules
 
 profiles/cups/bluetooth
 profiles/iap/iapd
diff --git a/Makefile.am b/Makefile.am
index 5717c3dac..2d43493aa 100644
--- a/Makefile.am
+++ b/Makefile.am
@@ -429,11 +429,9 @@ if HID2HCI
 rulesdir = $(UDEV_DIR)/rules.d
 
 rules_DATA = tools/97-hid2hci.rules
-
-CLEANFILES += $(rules_DATA)
 endif
 
-EXTRA_DIST += tools/hid2hci.rules
+EXTRA_DIST += tools/97-hid2hci.rules
 
 if TEST
 testdir = $(pkglibdir)/test
@@ -758,10 +756,6 @@ endif
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

