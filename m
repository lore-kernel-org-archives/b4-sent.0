From: Daniel Gomez <da.gomez@samsung.com>
Date: Tue, 27 Aug 2024 21:36:57 +0200
Subject: [PATCH RFC WIP 02/13] scripts/ansible.Makefile: add run helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240827-ansible-cleanups-v1-2-2828a816de5e@samsung.com>
References: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
In-Reply-To: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=11186;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=mioDewkOP47iRs64PK+WrqMidE9GqL0lY4dXcntVbhE=;
 b=/S8B33eE6hZCkNZfz3gC4M92EFrm6vFT1lteNWzqPE7UmTegodNqX15l4o1yvHVkfyIpv5nW5
 beGDhgNdaB5AkJ5ygfDctxxrzEEu8ksP3o8i1336QUmTgFHWcda6Q6H
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add run_ansible_playbook_local helper. This allows to centralize
ansible-playbook calls and extend the helper/helpers with extra
functionality.

This change allows to overwrite the KDEVOPS_EXTRA_VARS variable for the
users of run_ansible_playbook_local helper.

If KDEVOPS_EXTRA_VARS is not overwritten by the user when running make,
there are no functional changes.

Note that we don't need to specify anymore ansible_python_interpreter as
it's part of the extra_vars.yml file.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile                          | 12 ++++--------
 Makefile.build_qemu               |  6 ++----
 Makefile.hypervisor-tunings       |  6 ++----
 Makefile.kdevops                  | 22 ++++++----------------
 Makefile.linux-mirror             |  6 ++----
 Makefile.postfix                  |  6 ++----
 scripts/ansible.Makefile          |  9 +++++++++
 scripts/guestfs.Makefile          |  5 +----
 scripts/journal-server.Makefile   |  5 +----
 scripts/systemd-timesync.Makefile |  5 +----
 scripts/terraform.Makefile        |  5 +----
 scripts/vagrant.Makefile          | 11 +++--------
 12 files changed, 34 insertions(+), 64 deletions(-)

diff --git a/Makefile b/Makefile
index 8e2e805c..8e16ff5b 100644
--- a/Makefile
+++ b/Makefile
@@ -60,6 +60,8 @@ ANSIBLE_EXTRA_ARGS_SEPARATED :=
 ANSIBLE_EXTRA_ARGS_DIRECT :=
 include Makefile.extra_vars
 
+include scripts/ansible.Makefile
+
 ANSIBLE_EXTRA_ARGS += ansible_python_interpreter='$(CONFIG_KDEVOPS_PYTHON_INTERPRETER)'
 
 LIMIT_HOSTS :=
@@ -219,17 +221,11 @@ endif
 
 DEFAULT_DEPS += $(KDEVOPS_HOSTS)
 $(KDEVOPS_HOSTS): .config $(KDEVOPS_HOSTS_TEMPLATE)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/gen_hosts.yml \
-		--extra-vars=@./extra_vars.yaml
+		$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/gen_hosts.yml)
 
 DEFAULT_DEPS += $(KDEVOPS_NODES)
 $(KDEVOPS_NODES) $(KDEVOPS_VAGRANT): .config $(KDEVOPS_NODES_TEMPLATE)
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/gen_nodes.yml \
-		--extra-vars=@./extra_vars.yaml
+		$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/gen_nodes.yml)
 
 DEFAULT_DEPS += $(LOCALHOST_SETUP_WORK)
 
diff --git a/Makefile.build_qemu b/Makefile.build_qemu
index 05cfb2f3..874e8a63 100644
--- a/Makefile.build_qemu
+++ b/Makefile.build_qemu
@@ -20,10 +20,8 @@ QEMU_BUILD_SETUP_ARGS += qemu_target="ppc64-softmmu"
 endif
 
 qemu: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/build_qemu.yml)
+
 PHONY += qemu
 
 qemu-install: $(KDEVOPS_EXTRA_VARS)
diff --git a/Makefile.hypervisor-tunings b/Makefile.hypervisor-tunings
index 3f2f45a0..0dd79ed8 100644
--- a/Makefile.hypervisor-tunings
+++ b/Makefile.hypervisor-tunings
@@ -14,10 +14,8 @@ HYPERVISOR_TUNING_ARGS += hypervisor_tunning_zswap_max_pool_percent=$(ZSWAP_MAX_
 endif
 
 kdevops_hypervisor_tunning: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/hypervisor-tuning.yml \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/hyperfisor-tuning.yml)
+
 PHONY += kdevops_hypervisor_tunning
 
 ANSIBLE_EXTRA_ARGS += $(HYPERVISOR_TUNING_ARGS)
diff --git a/Makefile.kdevops b/Makefile.kdevops
index ac83bd82..647c87f0 100644
--- a/Makefile.kdevops
+++ b/Makefile.kdevops
@@ -9,17 +9,12 @@ kdevops_all: kdevops_deps
 PHONY := kdevops_all
 
 kdevops_terraform_deps:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install_terraform.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_terraform.yml)
+
 PHONY += kdevops_terraform_deps
 
 kdevops_vagrant_install_vagrant:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant.yml)
 
 kdevops_install_libvirt:
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
@@ -43,10 +38,8 @@ PHONY += kdevops_vagrant_deps
 KDEVOPS_VAGRANT_WORK := kdevops_vagrant_deps
 
 kdevops_vagrant_boxes:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant_boxes.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_vagrant_boxes.yml)
+
 PHONY += kdevops_vagrant_boxes
 KDEVOPS_VAGRANT_WORK += kdevops_vagrant_boxes
 
@@ -60,10 +53,7 @@ PHONY += kdevops_verify_libvirt_user
 KDEVOPS_VAGRANT_WORK += kdevops_verify_libvirt_user
 
 kdevops_libvirt_storage_pool_create:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/libvirt_storage_pool_create.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/libvirt_storage_pool_create.yml)
 
 PHONY += kdevops_libvirt_storage_pool_create
 KDEVOPS_VAGRANT_WORK += kdevops_libvirt_storage_pool_create
diff --git a/Makefile.linux-mirror b/Makefile.linux-mirror
index 8e8794d2..dce44365 100644
--- a/Makefile.linux-mirror
+++ b/Makefile.linux-mirror
@@ -11,10 +11,8 @@ LINUX_MIRROR_ARGS += mirror_torvalds_url='$(subst ",,$(CONFIG_MIRROR_TORVALDS_UR
 MIRROR_CODE      := $(TOPDIR)/playbooks/roles/linux-mirror/linux-mirror-systemd/
 
 kdevops_linux_mirror: $(KDEVOPS_EXTRA_VARS)
-	$(Q)ansible-playbook --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/linux-mirror.yml \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/linux_mirror.yml)
+
 PHONY += kdevops_linux_mirror
 
 mirror: $(KDEVOPS_EXTRA_VARS) kdevops_linux_mirror
diff --git a/Makefile.postfix b/Makefile.postfix
index e5d1776d..5332366c 100644
--- a/Makefile.postfix
+++ b/Makefile.postfix
@@ -7,10 +7,8 @@ POSTFIX_SETUP_ARGS += postfix_relay_host_setup=True
 POSTFIX_SETUP_ARGS += postfix_relay_host=$(POSTFIX_RELAY_HOST)
 
 kdevops_postfix_setup_relay: $(KDEVOPS_EXTRA_VARS)
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/postfix_relay_host.yml \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/postfix_relay_host.yml)
+
 PHONY += kdevos_postfix_setup_relay
 ANSIBLE_EXTRA_ARGS += $(POSTFIX_SETUP_ARGS)
 LOCALHOST_SETUP_WORK += kdevops_postfix_setup_relay
diff --git a/scripts/ansible.Makefile b/scripts/ansible.Makefile
new file mode 100644
index 00000000..d07b50c1
--- /dev/null
+++ b/scripts/ansible.Makefile
@@ -0,0 +1,9 @@
+# SPDX-License-Identifier: copyleft-next-0.3.1
+run_ansible_playbook_local = \
+	$(Q)ansible-playbook \
+		$(ANSIBLE_VERBOSE) \
+		--inventory localhost, \
+		--extra-vars=@./$(KDEVOPS_EXTRA_VARS) \
+		--connection=local \
+		$(1) \
+		$(if $(2),$(2))
diff --git a/scripts/guestfs.Makefile b/scripts/guestfs.Makefile
index 08785644..ab0b9ef3 100644
--- a/scripts/guestfs.Makefile
+++ b/scripts/guestfs.Makefile
@@ -60,10 +60,7 @@ KDEVOPS_PROVISION_DESTROY_METHOD	:= destroy_guestfs
 	$(Q)make linux-clone
 
 libvirt_pcie_passthrough_permissions:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		playbooks/libvirt_pcie_passthrough.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/libvirt_pcie_passthrough.yml)
 
 $(KDEVOPS_PROVISIONED_SSH):
 	$(Q)if [[ "$(CONFIG_KDEVOPS_SSH_CONFIG_UPDATE)" == "y" ]]; then \
diff --git a/scripts/journal-server.Makefile b/scripts/journal-server.Makefile
index 1d01d4cd..1371a0af 100644
--- a/scripts/journal-server.Makefile
+++ b/scripts/journal-server.Makefile
@@ -18,10 +18,7 @@ journal-client:
 		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml
 
 journal-server:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install_systemd_journal_remote.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_systemd_journal_remote.yml)
 
 journal-restart:
 	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) -l baseline,dev \
diff --git a/scripts/systemd-timesync.Makefile b/scripts/systemd-timesync.Makefile
index 11950cd9..339f5b0f 100644
--- a/scripts/systemd-timesync.Makefile
+++ b/scripts/systemd-timesync.Makefile
@@ -27,10 +27,7 @@ timesyncd-client:
 		$(KDEVOPS_PLAYBOOKS_DIR)/devconfig.yml
 
 timesyncd-server:
-	@$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/install_systemd_timesyncd.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/install_systemd_timesyncd.yml)
 
 timesyncd-status:
 	@$(Q)timedatectl status
diff --git a/scripts/terraform.Makefile b/scripts/terraform.Makefile
index aeeac595..3612ebff 100644
--- a/scripts/terraform.Makefile
+++ b/scripts/terraform.Makefile
@@ -170,7 +170,4 @@ destroy_terraform:
 	$(Q)rm -f $(KDEVOPS_PROVISIONED_DEVCONFIG)
 
 $(KDEVOPS_TFVARS): $(KDEVOPS_TFVARS_TEMPLATE) .config
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		$(KDEVOPS_PLAYBOOKS_DIR)/gen_tfvars.yml \
-		--extra-vars=@./extra_vars.yaml
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/gen_tfvars.yml)
diff --git a/scripts/vagrant.Makefile b/scripts/vagrant.Makefile
index 368c2f84..880cb370 100644
--- a/scripts/vagrant.Makefile
+++ b/scripts/vagrant.Makefile
@@ -94,17 +94,12 @@ vagrant_9p_linux_clone:
 	$(Q)make linux-clone
 
 libvirt_pcie_passthrough_permissions:
-	$(Q)ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-		--inventory localhost, \
-		playbooks/libvirt_pcie_passthrough.yml \
-		-e 'ansible_python_interpreter=/usr/bin/python3'
+	$(call run_ansible_playbook_local, $(KDEVOPS_PLAYBOOKS_DIR)/libvirt_pcie_passthrough.yml)
 
 $(KDEVOPS_PROVISIONED_SSH):
 	$(Q)if [[ "$(CONFIG_KDEVOPS_SSH_CONFIG_UPDATE)" == "y" ]]; then \
-		ansible-playbook $(ANSIBLE_VERBOSE) --connection=local \
-			--inventory localhost, \
-			playbooks/update_ssh_config_vagrant.yml \
-			-e 'ansible_python_interpreter=/usr/bin/python3' ;\
+		$(call run_ansible_playbook_local, \
+			$(KDEVOPS_PLAYBOOKS_DIR)/update_ssh_config_vagrant.yml); \
 	fi
 	$(Q)touch $(KDEVOPS_PROVISIONED_SSH)
 

-- 
2.39.2

