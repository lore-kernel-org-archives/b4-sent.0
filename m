From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:36:58 +0200
Subject: [PATCH RFC WIP 03/13] Makefile: replace ansible-playbook local
 calls with helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-3-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=8474;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=JbFv+A56RZCS70HzZ5ITgvB8Xq2HJ12JTGcOtoFKkMo=;
 b=wjjxh3N20fzp5zo5lqxc0iQim0/TNmTukKkqRuP3WKisKAoDjGBQUuaLY+qNAgFgRAUkS0PX0
 23TazXQRC5XBZgrtGx93ipvZ/qTBc0nneuful2m9CAJFD0dAudmkW0J
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace remaining of the ansible-playbook --connection=local calls with
the run_ansible_playbook_local helper. These are users providing extra
arguments such as --tags or additional --extra-vars.

This also fixes double use of @$(Q) for the ansible-playbooks using
that.

No functional changes.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.build_qemu                      | 24 ++++++++++++------------
 Makefile.kdevops                         | 23 ++++++++++-------------
 scripts/ansible.Makefile                 |  9 +++++++++
 scripts/dynamic-pci-kconfig.Makefile     |  8 +++-----
 scripts/guestfs.Makefile                 |  5 +----
 scripts/install-menuconfig-deps.Makefile |  9 ++++-----
 workflows/fstests/Makefile               | 10 ++++------
 workflows/linux/Makefile                 |  8 +++-----
 8 files changed, 46 insertions(+), 50 deletions(-)

diff --git a/Makefile.build_qemu b/Makefile.build_qemu
index 874e8a63..e3bd41ba 100644
--- a/Makefile.build_qemu
+++ b/Makefile.build_qemu
@@ -25,24 +25,24 @@ qemu: $(KDEVOPS_EXTRA_VARS)
 PHONY += qemu
 
 qemu-install: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		--extra-vars=@./extra_vars.yaml --tags vars,install
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml, \
+		--tags vars,install)
+
 PHONY += qemu-install
 
 qemu-configure: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		--extra-vars=@./extra_vars.yaml --tags vars,configure
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml, \
+		--tags vars,configure)
+
 PHONY += qemu-configure
 
 qemu-build: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		--extra-vars=@./extra_vars.yaml --tags vars,build
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml, \
+		--tags vars,build)
+
 PHONY += qemu-build
 
 
diff --git a/Makefile.kdevops b/Makefile.kdevops
index 647c87f0..649cb729 100644
--- a/Makefile.kdevops
+++ b/Makefile.kdevops
@@ -17,17 +17,15 @@ kdevops_vagrant_install_vagrant:
 	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant.yml)
 
 kdevops_install_libvirt:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml -e "skip_configuration=True" \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local,
+		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml, \
+		--extra-vars "skip_configuration=True")
 
 kdevops_configure_libvirt:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml -e "skip_install=True" \
-		-e 'running_user=$(USER)' \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml, \
+		--extra-vars "skip_install=True" \
+		--extra-vars "running_user=$(USER)")
 
 kdevops_vagrant_deps: \
 		kdevops_vagrant_install_vagrant \
@@ -44,10 +42,9 @@ PHONY += kdevops_vagrant_boxes
 KDEVOPS_VAGRANT_WORK += kdevops_vagrant_boxes
 
 kdevops_verify_libvirt_user:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml -e "only_verify_user=True" \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_user.yml, \
+		--extra-vars "only_verify_user=True")
 
 PHONY += kdevops_verify_libvirt_user
 KDEVOPS_VAGRANT_WORK += kdevops_verify_libvirt_user
diff --git a/scripts/ansible.Makefile b/scripts/ansible.Makefile
index d07b50c1..46a318d6 100644
--- a/scripts/ansible.Makefile
+++ b/scripts/ansible.Makefile
@@ -7,3 +7,12 @@ run_ansible_playbook_local = \
 		--connection=local \
 		$(1) \
 		$(if $(2),$(2))
+
+run_ansible_playbook_local_noq = \
+	ansible-playbook \
+		$(ANSIBLE_VERBOSE) \
+		--inventory localhost, \
+		--extra-vars=@./$(KDEVOPS_EXTRA_VARS) \
+		--connection=local \
+		$(1) \
+		$(if $(2),$(2))
diff --git a/scripts/dynamic-pci-kconfig.Makefile b/scripts/dynamic-pci-kconfig.Makefile
index 0878f267..90503135 100644
--- a/scripts/dynamic-pci-kconfig.Makefile
+++ b/scripts/dynamic-pci-kconfig.Makefile
@@ -42,11 +42,9 @@ endif # CONFIG_KDEVOPS_LIBVIRT_PCIE_PASSTHROUGH
 HELP_TARGETS += dynamic-kconfig-pci-help
 
 dynamic_pcipassthrough_kconfig:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		playbooks/gen-pci-kconfig.yml \
-		--extra-vars '{ $(PCIE_RUNTIME_VARS) }' \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/gen-pci-kconfig.yml, \
+		--extra-vars '{ $(PCIE_RUNTIME_VARS) }')
 
 dynamic-kconfig-pci-help:
 	@echo "dynconfig-pci      - enables only pci dynamically generated kconfig content"
diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index ab0b9ef3..2bc3a93f 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -64,10 +64,7 @@ libvirt_pcie_passthrough_permissions:
 
 $(KDEVOPS_PROVISIONED_SSH):
 	$(Q)if [[ "$(CONFIG_KDEVOPS_SSH_CONFIG_UPDATE)" == "y" ]]; then \
-		ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-			--inventory localhost, \
-			playbooks/update_ssh_config_guestfs.yml \
-			--extra-vars=@./extra_vars.yaml ;\
+		$(call run_ansible_playbook_local_noq, $(KDEVOPS_PLAYBOOKS_DIR)/update_ssh_config_guestfs.yml); \
 		LIBVIRT_DEFAULT_URI=$(CONFIG_LIBVIRT_URI) $(TOPDIR)/scripts/update_ssh_config_guestfs.py; \
 	fi
 	$(Q)ansible $(ANSIBLE_VERBOSE) -i hosts all -e 'ansible_python_interpreter=/usr/bin/python3' -m wait_for_connection
diff --git a/scripts/install-menuconfig-deps.Makefile b/scripts/install-menuconfig-deps.Makefile
index 8b4fd217..531384f7 100644
--- a/scripts/install-menuconfig-deps.Makefile
+++ b/scripts/install-menuconfig-deps.Makefile
@@ -1,11 +1,10 @@
 # SPDX-License-Identifier: copyleft-next-0.3.1
 
 menuconfig-deps:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install-menuconfig-deps.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
-		-e 'kdevops_first_run=True'
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/install-menuconfig-deps.yml, \
+		--extra-vars "kdevops_first_run=True")
+
 PHONY += menuconfig-deps
 
 menuconfig-deps-help-menu:
diff --git a/workflows/fstests/Makefile b/workflows/fstests/Makefile
index 31db5257..4735a502 100644
--- a/workflows/fstests/Makefile
+++ b/workflows/fstests/Makefile
@@ -212,12 +212,10 @@ fstests-config: $(KDEVOPS_EXTRA_VARS)
 		$(LIMIT_HOSTS)
 
 fstests-config-debug: $(KDEVOPS_EXTRA_VARS)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		playbooks/fstests.yml \
-		-e 'fstests_debug_localhost=True' \
-		--tags vars,generate-fstests-config \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/fstests.yml, \
+		--extra-vars "fstests_debug_localhost=True" \
+		--tags vars,generate-fstests-config)
 
 fstests-dev: $(KDEVOPS_EXTRA_VARS)
 	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) \
diff --git a/workflows/linux/Makefile b/workflows/linux/Makefile
index 3014e804..db20ba99 100644
--- a/workflows/linux/Makefile
+++ b/workflows/linux/Makefile
@@ -134,12 +134,10 @@ linux-clone-clients: $(KDEVOPS_NODES)
 
 PHONY += linux-clone-9p
 linux-clone-9p: $(KDEVOPS_NODES)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3' \
+	$(call run_ansible_playbook_local, \
+		$(KDEVOPS_PLAYBOOKS_DIR)/bootlinux.yml, \
 		--extra-vars="$(BOOTLINUX_ARGS)" \
-		--tags vars,deps,clone
+		--tags vars,deps,clone)
 
 PHONY += linux-clone
 linux-clone: $(KDEVOPS_NODES) $(LINUX_CLONE_DEFAULT_TYPE)

-- 
2.39.2

