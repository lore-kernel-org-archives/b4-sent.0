From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:37:01 +0200
Subject: [PATCH RFC WIP 06/13] Makefile: extend use
 run_ansible_playbook_hosts helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-6-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=7076;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=a5LEO2dpsCmI3zkE5UDWtgIfoyjNS2h6EZvllRBI1OY=;
 b=/mSiw751e5pNNnhDkEx7TNmWeWv4yYWAinn5THQfVYvdTzo2oLp1h/MvTIR9Ykl1sm2FWTCIZ
 qFK2G8cIT9VDIHd9H5q0Ou28xkcLFORr5uO6Xe9ZzUx/hk7WitpNNUl
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the new helper where it's possible, with extra custom ansible
arguments.

No functional changes.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.btrfs_progs       |  7 +++--
 scripts/devconfig.Makefile | 18 ++++++-----
 workflows/linux/Makefile   | 77 ++++++++++++++++++++++++++--------------------
 3 files changed, 58 insertions(+), 44 deletions(-)

diff --git a/Makefile.btrfs_progs b/Makefile.btrfs_progs
index a66877b2..c5083763 100644
--- a/Makefile.btrfs_progs
+++ b/Makefile.btrfs_progs
@@ -5,9 +5,10 @@ BTRFS_PROGS_SETUP_ARGS += btrfs_progs_build=True
 
 PHONY += btrfs-progs
 btrfs-progs: $(KDEVOPS_NODES)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/btrfs-progs.yml \
-		--extra-vars=$(BTRFS_PROGS_SETUP_ARGS) $(LIMIT_HOSTS)
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/btrfs-progs.yml, \
+		--extra-vars=$(BTRFS_PROGS_SETUP_ARGS) \
+		$(LIMIT_HOSTS))
 
 btrfs-progs-help-menu:
 	@echo "btrfs-progs options:"
diff --git a/scripts/devconfig.Makefile b/scripts/devconfig.Makefile
index bdff0885..b2870c1c 100644
--- a/scripts/devconfig.Makefile
+++ b/scripts/devconfig.Makefile
@@ -56,12 +56,12 @@ extend-extra-args-devconfig:
 
 PHONY += devconfig
 devconfig: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i $(KDEVOPS_HOSTFILE) \
-		-l all,nfsd \
-		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml \
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml, \
+		--limit all,nfsd \
 		--extra-vars="$(BOOTLINUX_ARGS)" \
 		--extra-vars '{ kdevops_cli_install: True }' \
-		$(LIMIT_HOSTS)
+		$(LIMIT_HOSTS))
 
 devconfig-generic-help-menu:
 	@echo "devconfig          - Ensures generic system setup and is up to date"
@@ -71,10 +71,12 @@ HELP_TARGETS+=devconfig-generic-help-menu
 ifeq (y,$(CONFIG_SYSCTL_TUNING))
 PHONY += sysctl-tunings
 sysctl-tunings: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i $(KDEVOPS_HOSTFILE) \
-		-l all,nfsd \
-		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS) --tags vars,sysctl
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml, \
+		--limit all,nfsd \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		--tags vars,sysctl \
+		$(LIMIT_HOSTS))
 
 devconfig-help-menu:
 	@echo "Target node configuration options"
diff --git a/workflows/linux/Makefile b/workflows/linux/Makefile
index d4a87b62..2be041fd 100644
--- a/workflows/linux/Makefile
+++ b/workflows/linux/Makefile
@@ -91,44 +91,48 @@ LINUX_HELP_EXTRA :=
 PHONY += linux
 linux: $(KDEVOPS_NODES)
 	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux-local.yml)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS))
 
 PHONY += linux-mount
 linux-mount:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
 		--tags vars,9p_mount \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)
+		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS))
 
 PHONY += linux-deploy
 linux-deploy:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
 		--tags vars,build-linux,install-linux,manual-update-grub,saved,vars,reboot \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS))
 
 PHONY += linux-install
 linux-install:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
 		--tags vars,build-linux,install-linux \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS))
 
 PHONY += linux-uninstall
 linux-uninstall:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--tags uninstall-linux,vars \
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--tags uninstall-linux,vars, \
 		--extra-vars '{ "uninstall_kernel_enable": "True", $(DYNAMIC_RUNTIME_VARS) }' \
-		$(LIMIT_HOSTS)
+		$(LIMIT_HOSTS))
 
 linux-clone-clients: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS) \
-		--tags vars,deps,clone
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS) \
+		--tags vars,deps,clone)
 
 PHONY += linux-clone-9p
 linux-clone-9p: $(KDEVOPS_NODES)
@@ -142,29 +146,36 @@ linux-clone: $(KDEVOPS_NODES) $(LINUX_CLONE_DEFAULT_TYPE)
 
 PHONY += linux-grub-setup
 linux-grub-setup:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS) --tags manual-update-grub,saved,vars
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS) \
+		 --tags manual-update-grub,saved,vars)
 
 PHONY += linux-reboot
 linux-reboot:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS) --tags vars,reboot
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS) \
+		--tags vars,reboot)
 
 PHONY += uname
 uname:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS) --tags uname,vars
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS) \
+		--tags uname,vars)
 
 ifeq (y,$(CONFIG_KDEVOPS_WORKFLOW_ENABLE_CXL))
 PHONY += linux-cxl
 linux-cxl: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -i \
-		$(KDEVOPS_HOSTFILE) $(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		--tags 'vars,cxl-build,cxl-install'                             \
-		--extra-vars="$(BOOTLINUX_ARGS)" $(LIMIT_HOSTS)
+	$(call run_ansible_playbook_hosts, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
+		--tags 'vars,cxl-build,cxl-install' \
+		--extra-vars="$(BOOTLINUX_ARGS)" \
+		$(LIMIT_HOSTS))
 
 PHONY += linux-help-cxl
 linux-help-cxl:

-- 
2.39.2

