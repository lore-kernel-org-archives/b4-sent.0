From: Florian Schmaus <flo@geekplace.eu>
Date: Wed, 15 Jul 2026 12:51:17 +0200
Subject: [PATCH] selftests: do not preserve ownership when installing files
 with rsync
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260715-kselftest-rsync-right-v1-1-8df6c7734389@geekplace.eu>
X-B4-Tracking: v=1; b=H4sIACRmV2oC/yXMQQrCMBBG4auUWTuQFGLVq4iLNv5pRyXKTCpK6
 d2NuvwW7y1kUIHRoVlI8RSTe67wm4bi1OcRLOdqal27dZ0PfDXcUoEVVnvnyCrjVLgP3ZAcdsH
 vHdX2oUjy+n2Pp79tHi6I5Tujdf0AyTWPxHkAAAA=
X-Change-ID: 20260715-kselftest-rsync-right-a57bf0e85190
To: Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, Andrii Nakryiko <andrii@kernel.org>, 
 Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, Jiri Olsa <jolsa@kernel.org>, 
 Emil Tsalapatis <emil@etsalapatis.com>, Shuah Khan <shuah@kernel.org>, 
 Thomas Gleixner <tglx@kernel.org>, Ingo Molnar <mingo@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Darren Hart <dvhart@infradead.org>, 
 Davidlohr Bueso <dave@stgolabs.net>, 
 =?utf-8?q?Andr=C3=A9_Almeida?= <andrealmeid@igalia.com>
Cc: bpf@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Florian Schmaus <flo@geekplace.eu>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5468; i=flo@geekplace.eu;
 h=from:subject:message-id; bh=kprIu4Ky9iJXUA+IM60eGgnLUoGB91S6ZfNND3RnBrU=;
 b=owGbwMvMwMWoZLn8xddWhSDG02pJDFnhaaqFvB+0pp7L/2n8cF3C4rTH8/6vPLDUet7y6pWVn
 5K2FExy7mRcz8LAyMUwU0yRZXop63wrxTsPs5/8XgcziJUJZIq0SAMDELAw8OUm5pUa6RjpmWob
 6hkCGTpG8RA5PQaNzOLi0tQi3bSCIoe8/JLEksz8vGK9/ILUvIL0Ar20zLSSjIz8ouJUoBF6eak
 llubmpgamlm7GjkaGLs6uhmZOriZuTo6uRkbGlo7mrhZuphamRgamRgxcnAIw1+yqZf/Dd2zSYw
 V2+0beqOUruF/XK88wFnIpebZLplCP/cPa/xF+6zmD5gmt5fstGJfEvcTVhIHtchqznHCpW8mF6
 Rf/ZHyc/iHH8O7m65/9L558uIbFfIpWosvXuCuncsMUdPyi73ceWOm2S+RFplNpgECEidfyZSvu
 rFdlcCjatJXJTsAvQuynyfX2iLsWH9I4ft1cudIndP1FnmOzy+bx7DwmvqRqvu7hfrWsWwJ6S5T
 P3Q2aVB6qzMzc2MIYfsFAPvdzw0FtX42mH7FTX97f8N8l+UX+iZNZb27lGDc+q2eJ+LbjyE+DG8
 nlZyqlZ4gtu9Nvbvj9gOfjnbc2Kl2+82Gzo2fNs8l/X/ff8J9ge6EHAA==
X-Developer-Key: i=flo@geekplace.eu; a=openpgp;
 fpr=1357B01865B2503C18453D208CAC2A9678548E35
X-Endpoint-Received: by B4 Relay for flo@geekplace.eu/default with auth_id=792
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When kselftests are built and installed using "make install" or
integrated into other build systems (such as Yocto's "devtool
modify"), the source tree might be owned by a non-root developer user.

Because the installation scripts use "rsync -a", which implies -o and
-g, the installed test binaries and scripts are explicitly assigned
the UID/GID of the source tree owner instead of the user running the
install command. This results in UID leaks into the root filesystem.

Fix this by explicitly adding --no-owner --no-group to all rsync
invocations across the selftests Makefiles so that the installed files
are owned by the installing user (typically root).

Signed-off-by: Florian Schmaus <flo@geekplace.eu>
---
 tools/testing/selftests/bpf/Makefile     | 6 +++---
 tools/testing/selftests/futex/Makefile   | 2 +-
 tools/testing/selftests/lib.mk           | 8 ++++----
 tools/testing/selftests/sparc64/Makefile | 2 +-
 4 files changed, 9 insertions(+), 9 deletions(-)

diff --git a/tools/testing/selftests/bpf/Makefile b/tools/testing/selftests/bpf/Makefile
index b642ee489ea6..1ff923eab76b 100644
--- a/tools/testing/selftests/bpf/Makefile
+++ b/tools/testing/selftests/bpf/Makefile
@@ -781,7 +781,7 @@ $(TRUNNER_LIB_OBJS): $(TRUNNER_OUTPUT)/%.o:$(TOOLSDIR)/lib/%.c
 $(TRUNNER_BINARY)-extras: $(TRUNNER_EXTRA_FILES) | $(TRUNNER_OUTPUT)
 ifneq ($2:$(OUTPUT),:$(shell pwd))
 	$$(call msg,EXT-COPY,$(TRUNNER_BINARY),$(TRUNNER_EXTRA_FILES))
-	$(Q)rsync -aq $(if $(PERMISSIVE),--ignore-missing-args) $$^ $(TRUNNER_OUTPUT)/
+	$(Q)rsync -aq --no-owner --no-group $(if $(PERMISSIVE),--ignore-missing-args) $$^ $(TRUNNER_OUTPUT)/
 endif
 
 # some X.test.o files have runtime dependencies on Y.bpf.o files
@@ -1048,7 +1048,7 @@ EXTRA_CLEAN := $(SCRATCH_DIR) $(HOST_SCRATCH_DIR)			\
 ifneq ($(PERMISSIVE),)
 override define INSTALL_SINGLE_RULE
 	$(if $(INSTALL_LIST),@mkdir -p $(INSTALL_PATH))
-	$(if $(INSTALL_LIST),rsync -a --copy-unsafe-links --ignore-missing-args $(INSTALL_LIST) $(INSTALL_PATH)/)
+	$(if $(INSTALL_LIST),rsync -a --no-owner --no-group --copy-unsafe-links --ignore-missing-args $(INSTALL_LIST) $(INSTALL_PATH)/)
 endef
 endif
 
@@ -1057,7 +1057,7 @@ override define INSTALL_RULE
 	$(DEFAULT_INSTALL_RULE)
 	@for DIR in $(TEST_INST_SUBDIRS); do				  \
 		mkdir -p $(INSTALL_PATH)/$$DIR;				  \
-		rsync -a $(if $(PERMISSIVE),--ignore-missing-args)	  \
+		rsync -a --no-owner --no-group $(if $(PERMISSIVE),--ignore-missing-args)	  \
 			$(OUTPUT)/$$DIR/*.bpf.o				  \
 			$(INSTALL_PATH)/$$DIR;				  \
 	done
diff --git a/tools/testing/selftests/futex/Makefile b/tools/testing/selftests/futex/Makefile
index 78ab2cd111f6..c59f40b837e8 100644
--- a/tools/testing/selftests/futex/Makefile
+++ b/tools/testing/selftests/futex/Makefile
@@ -11,7 +11,7 @@ all:
 		mkdir $$BUILD_TARGET  -p;	\
 		$(MAKE) OUTPUT=$$BUILD_TARGET -C $$DIR $@;\
 		if [ -e $$DIR/$(TEST_PROGS) ]; then \
-			rsync -a $$DIR/$(TEST_PROGS) $$BUILD_TARGET/; \
+			rsync -a --no-owner --no-group $$DIR/$(TEST_PROGS) $$BUILD_TARGET/; \
 		fi \
 	done
 
diff --git a/tools/testing/selftests/lib.mk b/tools/testing/selftests/lib.mk
index f02cc8a2e4ae..aedcee1c04c6 100644
--- a/tools/testing/selftests/lib.mk
+++ b/tools/testing/selftests/lib.mk
@@ -122,14 +122,14 @@ define INSTALL_INCLUDES
 			fi; \
 			relative_files="$$relative_files $$relative_dir/$$entry_name"; \
 		done; \
-		cd $(SRC_PATH) && rsync -aR $$relative_files $(OBJ_PATH)/ \
+		cd $(SRC_PATH) && rsync -aR --no-owner --no-group $$relative_files $(OBJ_PATH)/ \
 	)
 endef
 
 run_tests: all
 ifdef building_out_of_srctree
 	@if [ "X$(TEST_PROGS)$(TEST_PROGS_EXTENDED)$(TEST_FILES)$(TEST_GEN_MODS_DIR)" != "X" ]; then \
-		rsync -aq --copy-unsafe-links $(TEST_PROGS) $(TEST_PROGS_EXTENDED) $(TEST_FILES) $(TEST_GEN_MODS_DIR) $(OUTPUT); \
+		rsync -aq --no-owner --no-group --copy-unsafe-links $(TEST_PROGS) $(TEST_PROGS_EXTENDED) $(TEST_FILES) $(TEST_GEN_MODS_DIR) $(OUTPUT); \
 	fi
 	@$(INSTALL_INCLUDES)
 	@if [ "X$(TEST_PROGS)" != "X" ]; then \
@@ -150,12 +150,12 @@ clean_mods_dir:
 
 define INSTALL_SINGLE_RULE
 	$(if $(INSTALL_LIST),@mkdir -p $(INSTALL_PATH))
-	$(if $(INSTALL_LIST),rsync -a --copy-unsafe-links $(INSTALL_LIST) $(INSTALL_PATH)/)
+	$(if $(INSTALL_LIST),rsync -a --no-owner --no-group --copy-unsafe-links $(INSTALL_LIST) $(INSTALL_PATH)/)
 endef
 
 define INSTALL_MODS_RULE
 	$(if $(INSTALL_LIST),@mkdir -p $(INSTALL_PATH)/$(INSTALL_LIST))
-	$(if $(INSTALL_LIST),rsync -a --copy-unsafe-links $(INSTALL_LIST)/*.ko $(INSTALL_PATH)/$(INSTALL_LIST))
+	$(if $(INSTALL_LIST),rsync -a --no-owner --no-group --copy-unsafe-links $(INSTALL_LIST)/*.ko $(INSTALL_PATH)/$(INSTALL_LIST))
 endef
 
 define INSTALL_RULE
diff --git a/tools/testing/selftests/sparc64/Makefile b/tools/testing/selftests/sparc64/Makefile
index 88f7be76f962..001b68e6354b 100644
--- a/tools/testing/selftests/sparc64/Makefile
+++ b/tools/testing/selftests/sparc64/Makefile
@@ -25,7 +25,7 @@ all:
 		#SUBDIR test prog name should be in the form: SUBDIR_test.sh \
 		TEST=$$DIR"_test.sh"; \
 		if [ -e $$DIR/$$TEST ]; then \
-			rsync -a $$DIR/$$TEST $$BUILD_TARGET/; \
+			rsync -a --no-owner --no-group $$DIR/$$TEST $$BUILD_TARGET/; \
 		fi \
 	done
 

---
base-commit: 3b029c035b34bbc693405ddf759f0e9b920c27f1
change-id: 20260715-kselftest-rsync-right-a57bf0e85190

Best regards,
--  
Florian Schmaus <flo@geekplace.eu>

