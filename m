From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:06 +0200
Subject: [PATCH RFC WIP 11/13] ansible.Makefile: enhance ansible verbosity
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-11-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=2386;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=FfGMU6JK6fo20QLGd++pbO6o7Q9gioiyNgE4aUpFXsY=;
 b=h7Bo9dZ5repuUj3UhWJK9pGWJThzlaw7DI7UYJD7nlYF7yg+XbLR598ARobgRM6GLX3EmGj7N
 9xCYtdBA/DCD47Rd3CohyMse2l4OqdZimxtCgN0H2ej87B8W3syBvTx
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ansible verbosity is controlled via V=2 parameter/value. This however
has a limited configuration as it hardcodes the output of the -v,
--verbose command of ansible-playbook to level 3 (-vvv). Drop support
for V=2 mode in favor of AV=<number> where <number> indicates the level
of verbosity from 0 (empty string) to max 6 (-vvvvvv).

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile                 |  4 ----
 scripts/ansible.Makefile | 22 ++++++++++++++++++++++
 scripts/kconfig/Makefile |  5 ++---
 3 files changed, 24 insertions(+), 7 deletions(-)

diff --git a/Makefile b/Makefile
index 8e16ff5b..2b2517e0 100644
--- a/Makefile
+++ b/Makefile
@@ -44,10 +44,6 @@ export Q=@
 export NQ=echo
 endif
 
-ifneq ($(findstring 2, $(V)),)
-  export ANSIBLE_VERBOSE := '-vvv'
-endif
-
 include Makefile.min_deps
 DEFAULT_DEPS += $(KDEVOPS_DEPCHECK)
 
diff --git a/scripts/ansible.Makefile b/scripts/ansible.Makefile
index 0b049c48..4b4d7a27 100644
--- a/scripts/ansible.Makefile
+++ b/scripts/ansible.Makefile
@@ -1,4 +1,26 @@
 # SPDX-License-Identifier: copyleft-next-0.3.1
+
+# AV controls the level of verbosity (-v, --verbose) of ansible-playbook executions.
+# The number indicates the level.
+AV ?= 0
+
+_AVMAX := 6
+ifeq ($(shell test $(AV) -gt $(_AVMAX) && echo OK || echo FAIL), OK)
+    _AV := 6
+else
+    _AV := $(AV)
+endif
+
+define ANSIBLE_VERBOSE
+$(shell [ $(_AV) -gt 0 ] && printf "%0.sv" $(shell seq 1 $(_AV)))
+endef
+
+ifneq ($(_AV),0)
+export ANSIBLE_VERBOSE := "-$(ANSIBLE_VERBOSE)"
+else
+export ANSIBLE_VERBOSE :=
+endif
+
 run_ansible_playbook_local = \
 	$(Q)ansible-playbook \
 		$(ANSIBLE_VERBOSE) \
diff --git a/scripts/kconfig/Makefile b/scripts/kconfig/Makefile
index 4e6b9dbb..4752e91e 100644
--- a/scripts/kconfig/Makefile
+++ b/scripts/kconfig/Makefile
@@ -59,9 +59,8 @@ help:
 	@echo "defconfig-*        - If you have files in the defconfig directory use default config from there"
 	@echo
 	@echo "Variable options:"
-	@echo "make V=n [targets] 1: verbose build (Makefile)"
-	@echo "                   2: verbose playbooks (Ansible)"
-	@echo "                   V=1 and V=2 can be combined with V=12"
+	@echo "make V=n [targets] 1:      verbose build (Makefile)"
+	@echo "make AV=n [targets] 0-6:   verbose build (Ansible)"
 
 .PHONY: clean
 clean:

-- 
2.39.2

