From: Daniel Gomez <da.gomez@samsung.com>
Date: Wed, 07 Aug 2024 12:40:44 +0200
Subject: [PATCH 3/3] Makefile.min_deps: add kdevops-install-deps target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240807-fix-startup-kdevops-v1-3-87af646e1237@samsung.com>
References: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
In-Reply-To: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723027254; l=3539;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=O2GBxtPy5KGY4Q7/MUzB2jMTgaFzk45SjL4Gi7qCmdI=;
 b=+6ZiR+mb2I4TDPR25N4DkH4OeMd50s+QYm6Ql37OKIUC8BCSagAwxnIe0DgoVgkbxYljN1afR
 C7hKiVQPW8xBB9jvoT1DjGtwL2xwszcSwXqcw0KQMLeABkglJEATJPJ
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This ensures based packages are installed using distro package manager
method and pipx for ansible.

Use pipx over distro package manager as the ansible package provided by
distro my be outdated.

https://docs.ansible.com/ansible/latest/installation_guide/
intro_installation.html#installing-and-upgrading-ansible-with-pipx

Add targets to install and update full Ansible package using
pipx. Full Ansible package is required to run kdevops (minimal
installation lacks support for callback plugins and more).

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 Makefile.min_deps        | 43 ++++++++++++++++++++++++++++++++++++++-----
 scripts/bringup.Makefile |  4 +++-
 2 files changed, 41 insertions(+), 6 deletions(-)

diff --git a/Makefile.min_deps b/Makefile.min_deps
index a1cb99a..c281379 100644
--- a/Makefile.min_deps
+++ b/Makefile.min_deps
@@ -5,11 +5,12 @@
 # have something more elaborate, like a version check add it to its
 # own file as we do with scripts/version_check/ansible-playbook
 
-BINARY_DEPS :=
-BINARY_DEPS += sudo
-BINARY_DEPS += make
-BINARY_DEPS += nc
-BINARY_DEPS += ansible-playbook
+BINARY_DEPS := sudo make ansible-playbook pipx
+DEBIAN_PACKAGE_DEPS := sudo make netcat-traditional pipx
+SUSE_PACKAGE_DEPS := sudo make nc python-pipx
+REDHAT_PACKAGE_DEPS := sudo make ncat pipx
+PIPX_DEPS :=
+PIPX_DEPS += ansible-playbook
 ifneq (y,$(CONFIG_KDEVOPS_FIRST_RUN))
 ifeq (y,$(CONFIG_GUESTFS))
 BINARY_DEPS += virt-builder
@@ -36,8 +37,40 @@ $(BINARY_DEPS):
 	$(Q)echo Verifying $@ ...
 	$(Q)set -e ; which $@ > /dev/null || ( \
 		echo Missing dependency: $@ ;\
+		echo Run 'make kdevops-install-deps' to install missing dependencies ;\
 	false)
 
+install_package_deps:
+	@echo "Detecting Linux distribution..."
+	@if [ -f /etc/debian_version ]; then \
+		echo "Detected Debian-based distro."; \
+		sudo apt update && sudo apt install -y $(DEBIAN_PACKAGE_DEPS); \
+	elif [ -f /etc/redhat-release ]; then \
+		echo "Detected Red Hat-based distro."; \
+		sudo yum install -y $(REDHAT_PACKAGE_DEPS); \
+	elif [ -f /etc/SuSE-release ]; then \
+		echo "Detected SUSE-based distro."; \
+		sudo zypper install -y $(SUSE_PACKAGE_DEPS); \
+	else \
+		echo "Unsupported Linux distribution."; \
+		exit 1; \
+	fi
+
+pipx_install_ansible_full:
+	$(Q)pipx install --force --include-deps ansible
+
+pipx_update_ansible_full:
+	$(Q)pipx upgrade --include-injected ansible
+
+kdevops-install-deps: install_package_deps pipx_install_ansible_full
+PHONY += kdevops-install-deps
+
+install-ansible-full: pipx_install_ansible_full
+PHONY += install-ansible-full
+
+update-ansible-full: pipx_update_ansible_full
+PHONY += update-ansible-full
+
 $(KDEVOPS_DEPCHECK): $(DYNAMIC_DEPS)
 	$(Q)echo The current minimum kdevops expected dependencies are met.
 	$(Q)touch $(KDEVOPS_DEPCHECK)
diff --git a/scripts/bringup.Makefile b/scripts/bringup.Makefile
index 148547c..2917218 100644
--- a/scripts/bringup.Makefile
+++ b/scripts/bringup.Makefile
@@ -35,7 +35,9 @@ HELP_TARGETS+=bringup-help-menu
 
 bringup-setup-help-menu:
 	@echo "Generic bring up set up targets:"
-	@echo "kdevops-deps        - Installs what we need on the localhost"
+	@echo "kdevops-deps            - Installs what we need on the localhost"
+	@echo "install-ansible-full    - Force install full Ansible package with pipx"
+	@echo "update-ansible-full     - Updates full Ansible package with pipx"
 
 HELP_TARGETS += bringup-setup-help-menu
 

-- 
Git-146)

