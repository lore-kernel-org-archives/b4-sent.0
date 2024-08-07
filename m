From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH 0/3] Fix kdevops startup
Date: Wed, 07 Aug 2024 12:40:41 +0200
Message-Id: <20240807-fix-startup-kdevops-v1-0-87af646e1237@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAClPs2YC/x2MWwqAIBAArxL73YKakXSV6KPHVkuQ4lYE4d2TP
 gdm5gWhyCTQFi9EulnYHxl0WcC0DcdKyHNmMMpY5VSDCz8o5xDPK+A+0+2DoFtqqt3YVNpYyGW
 IlLX/2vUpff87+8dlAAAA
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723027254; l=11501;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=iPjvdDb6fhrIe/DDyzlD5/7D7BkVAnlj89iMECfMiLc=;
 b=4gmzfCWyZkYOiCW57SbuNQjBdJj8a3WNU1zBcTNTAFOUfwbF1NMoOdYB44yjU+cY33nE/dd8U
 OKPjy7d8DX0BjnhBEIm+imcWFobmd6M70QyNLTyXbgbauBlGLBWUAmo
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series solves the startup issues found when kdevops is first
run in a new machine. Mainly when Ansible is not installed but you
have sudo and make available.

Here the errors I found:

  make kdevops-deps
  make: *** No rule to make target 'kdevops-deps'.  Stop.

  make dynconfig-pci
  /bin/bash: line 1: ansible-playbook: command not found
  make[1]: *** [scripts/dynamic-pci-kconfig.Makefile:45: dynamic_pcipassthrough_kconfig] Error 127
  make: *** [scripts/dynamic-pci-kconfig.Makefile:63: dynconfig-pci] Error 2

The changes below have been tested on Debian GNU/Linux trixie/sid. The
packages for Red Hat and SUSE have not been verified. A double-check on
those would be appreciated.

Besides fixing missing a minor target issue, I've added
kdevops-install-deps target to solve basic dependencies. Here the
workflow suggested:

  make kdevops-deps # Warn the user missing dependencies and how to solve it
  make kdevops-install-deps # Installs Ansible full package with pipx
  make kdevops-deps # Makes sure menuconfig dependencies are met,
                    # libvirt, etc. (this already tests Ansible dependencies)
  make dynconfig-pci # Run a simple test that runs Ansible and menuconfig

Note that running kdevops-deps, then finding missing dependencies and
automatically install Ansible would be possible if preferred more an
auto-solve solution. Pipx [1] is used for installing Ansible full
package to get a more uptodate version than the one your distro
supports.

[1] https://docs.ansible.com/ansible/latest/installation_guide/
intro_installation.html#installing-and-upgrading-ansible-with-pipx

And explicitly, the last patch also adds install-ansible-full and
update-ansible-full target to manually handle Ansible installations
via pipx.

Note that we need the full version of Ansible, not the minimal one
(ansible-core). The latter is insufficient for kdevops as it depends on
plugins only available in the full installation, such as the callback
plugin configured in ansible.cfg (e.g., stdout_callback=debug).

Here the full log output:

  make kdevops-deps
  Verifying sudo ...
  Verifying make ...
  Verifying ansible-playbook ...
  Missing dependency: ansible-playbook
  Run make kdevops-install-deps to install missing dependencies
  make: *** [Makefile.min_deps:38: ansible-playbook] Error 1

  make kdevops-install-deps
  Detecting Linux distribution...
  Detected Debian-based distro.
  Get:1 http://deb.debian.org/debian testing InRelease [169 kB]
  Get:2 http://deb.debian.org/debian testing-updates InRelease [49.6 kB]
  Get:3 http://deb.debian.org/debian testing/main Sources.diff/Index [27
  [...]
  Fetched 17.7 MB in 48s (366 kB/s)
  359 packages can be upgraded. Run 'apt list --upgradable' to see them.
  sudo is already the newest version (1.9.15p5-3+b1).
  make is already the newest version (4.3-4.1).
  netcat-traditional is already the newest version (1.10-48.1).
  The following packages were automatically installed and are no longer required:
    libpython3.11-minimal  libpython3.11-stdlib  libpython3.11t64  linux-image-6.1.0-22-amd64  python3-lib2to3
  Use 'sudo apt autoremove' to remove them.
  
  Upgrading:
    libpython3-stdlib  python3  python3-minimal  python3-pkg-resources  python3-setuptools
  
  Installing:
    pipx
  
  Installing dependencies:
    python3-argcomplete  python3-pip-whl  python3-platformdirs  python3-setuptools-whl  python3-userpath  python3-venv  python3.12-venv
  
  REMOVING:
    python3-distutils
  
  Summary:
    Upgrading: 5, Installing: 8, Removing: 1, Not Upgrading: 354
    Download size: 4,086 kB
    Space needed: 6,411 kB / 748 GB available
  
  Get:1 http://deb.debian.org/debian testing/main amd64 python3-minimal
  amd64 3.12.4-1 [26.5 kB]
  Get:2 http://deb.debian.org/debian testing/main amd64 python3 amd64
  3.12.4-1 [27.6 kB]
  [...]
  Setting up python3-argcomplete (3.4.0-2) ...
  Setting up python3-userpath (1.9.1-1) ...
  Setting up python3-pkg-resources (70.3.0-2) ...
  Setting up python3-setuptools (70.3.0-2) ...
  Setting up pipx (1.6.0-1) ...
  [...]
  No VM guests are running outdated hypervisor (qemu) binaries on this host.
    installed package ansible 10.2.0, installed using Python 3.12.4
    These apps are now globally available
      - ansible
      - ansible-community
      - ansible-config
      - ansible-connection
      - ansible-console
      - ansible-doc
      - ansible-galaxy
      - ansible-inventory
      - ansible-playbook
      - ansible-pull
      - ansible-test
      - ansible-vault
  ⚠  Note: '/home/dagomez/.local/bin' is not on your PATH environment
  variable. These apps will not be globally accessible until your PATH
  is updated. Run `pipx ensurepath` to automatically add it, or manually
  modify your PATH in your shell's config file (e.g. ~/.bashrc).
  done! ✨ 🌟 ✨

  source ~/.profile

  ansible-playbook --version
  ansible-playbook [core 2.17.2]
    config file = /home/dagomez/src/kdevops/ansible.cfg
    configured module search path = ['/home/dagomez/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    ansible python module location = /home/dagomez/.local/share/pipx/venvs/ansible/lib/python3.12/site-packages/ansible
    ansible collection location = /home/dagomez/.ansible/collections:/usr/share/ansible/collections
    executable location = /home/dagomez/.local/bin/ansible-playbook
    python version = 3.12.4 (main, Jul 15 2024, 12:17:32) [GCC 13.3.0] (/home/dagomez/.local/share/pipx/venvs/ansible/bin/python)
    jinja version = 3.1.4
    libyaml = True

  ansible-doc --type callback --list
  amazon.aws.aws_resource_actions        summarizes all "resource:actions" completed
  ansible.builtin.default                default Ansible screen output
  ansible.builtin.junit                  write playbook output to a JUnit file
  ansible.builtin.minimal                minimal Ansible screen output
  ansible.builtin.oneline                oneline Ansible screen output
  ansible.builtin.tree                   Save host events to files
  ansible.posix.cgroup_perf_recap        Profiles system activity of tasks and full execution using cgroups
  ansible.posix.debug                    formatted stdout/stderr display
  ansible.posix.json                     Ansible screen output as JSON
  ansible.posix.jsonl                    Ansible screen output as JSONL (lines in json format)
  ansible.posix.profile_roles            adds timing information to roles
  ansible.posix.profile_tasks            adds time information to tasks
  ansible.posix.skippy                   Ansible screen output that ignores skipped status
  ansible.posix.timer                    Adds time to play stats
  community.general.cgroup_memory_recap  Profiles maximum memory usage of tasks and full execution using cgroups
  community.general.context_demo         demo callback that adds play/task context
  community.general.counter_enabled      adds counters to the output items (tasks and hosts/task)
  community.general.default_without_diff The default ansible callback without diff output
  community.general.dense                minimal stdout output
  community.general.diy                  Customize the output
  community.general.elastic              Create distributed traces for each Ansible task in Elastic APM
  community.general.hipchat              post task events to hipchat
  community.general.jabber               post task events to a jabber server
  community.general.log_plays            write playbook output to log file
  community.general.loganalytics         Posts task results to Azure Log Analytics
  community.general.logdna               Sends playbook logs to LogDNA
  community.general.logentries           Sends events to Logentries
  community.general.logstash             Sends events to Logstash
  community.general.mail                 Sends failure events via email
  community.general.nrdp                 Post task results to a Nagios server through nrdp
  community.general.null                 Don't display stuff to screen
  community.general.opentelemetry        Create distributed traces with OpenTelemetry
  community.general.say                  notify using software speech synthesizer
  community.general.selective            only print certain tasks
  community.general.slack                Sends play events to a Slack channel
  community.general.splunk               Sends task result events to Splunk HTTP Event Collector
  community.general.sumologic            Sends task result events to Sumologic
  community.general.syslog_json          sends JSON events to syslog
  community.general.timestamp            Adds simple timestamp for each header
  community.general.unixy                condensed Ansible output
  community.general.yaml                 YAML-ized Ansible screen output
  community.grafana.grafana_annotations  send ansible events as annotations on charts to grafana over http api
  ovirt.ovirt.stdout                     Output the log of ansible
  theforeman.foreman.foreman             Sends events to Foreman

  make kdevops-deps
  Verifying sudo ...
  Verifying make ...
  Verifying ansible-playbook ...
  Verifying pipx ...
  
  PLAY [localhost] ********************************************************************************************************************************************************************************************************************************
  
  TASK [Gathering Facts] **************************************************************************************************************************************************************************************************************************
  ok: [localhost]
  
  TASK [install-menuconfig-deps : Install kdevops deps to run make menuconfig] 
  [...]
  Installed dependencies

  make dynconfig-pci

  PLAY [localhost] ********************************************************************************************************************************************************************************************************************************
  
  TASK [Gathering Facts] **************************************************************************************************************************************************************************************************************************
  ok: [localhost]
  
  TASK [gen_pci_kconfig : Dump pci output in machine-readible form] 
  [...]

  <menuconfig opened>
  <Ctrl-C>
  
  Your configuration changes were NOT saved.

To: kdevops@lists.linux.dev
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: Daniel Gomez (Samsung) <d+samsung@kruces.com>
Cc: gost.dev@samsung.com

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (3):
      Makefile: fix kdevops-deps missing target
      Makefile.kdevops: add extra dependencies
      Makefile.min_deps: add kdevops-install-deps target

 Makefile                 |  3 +++
 Makefile.kdevops         |  2 +-
 Makefile.min_deps        | 43 ++++++++++++++++++++++++++++++++++++++-----
 scripts/bringup.Makefile |  4 +++-
 4 files changed, 45 insertions(+), 7 deletions(-)
---
base-commit: 8e31f894270b79ab109b08fe785a2b1a9c1d8431
change-id: 20240807-fix-startup-kdevops-8f5e58b73124

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

