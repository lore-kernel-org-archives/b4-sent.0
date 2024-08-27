From: Daniel Gomez <da.gomez@samsung.com>
Subject: [PATCH RFC WIP 00/13] kdevops: ansible cleanups
Date: Tue, 27 Aug 2024 21:36:55 +0200
Message-Id: <20240827-ansible-cleanups-v1-0-2828a816de5e@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANcqzmYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCyNz3cS84syknFTd5JzUxLzSgmJdQxOjlFRj07S0xFRLJaC2gqLUtMw
 KsJHRSkFuzgrhngFKsbW1AGvUEeNrAAAA
To: kdevops@lists.linux.dev, Luis Chamberlain <mcgrof@kernel.org>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, gost.dev@samsung.com, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724787418; l=4115;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=FXTqn8I7kYT7/p8mzUbwMUUrG+MPqinmyVToDpRNn0w=;
 b=fCCQ+j2Y5OODxXnNLnFpqhR6ElbnzYlpA5PTBA+7bZk1tMFFGVQ2nYLTQQ00jbua4DDaiSkVc
 e62FB1wcy+dCYFfr2xYufxSOqz92/PrkbzXXD5dljsh6RURVCaks/Nc
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series is a WIP and RFC.

I'm doing some ansible-playbook related cleanups in kdevops with
the ultimate goal of adding support for running kdevops in a sandbox
[1]. While doing that, I've realized the assumptions we do in some
places such as inventory file (location and name) or hosts file,
the kconfig .config file location, the ssh configuration, etc. The
sandbox should allow a user of kdevops to run different configurations
(.config, hosts, ssh configs...) using the same kdevops project repo,
but in different sandbox directories (e.g. kdevops/sandboxdir1/configs,
kdevops/sandbox2/ configs, etc) and switch in between.

The core of this work is to centralize the place were we call/run
Ansible, in one single Makefile, that allows us to control the command
being executed. One of the features I'd like to have support for is to
run in dry-run mode or use the --list-tasks options from Ansible, which
gives you an overview of the tasks that the playbook is going to run.

What do you think? Is this effort going in the right direction? Do you
recommend splitting patches in a different way? Hopefully it make sense,
and patches are self-explained but let me know questions or concerns.

How much testing would this change require? I'm not a user of all
kdevops features and workflows, so either having a CI or people testing
following patches for the workflows affected by this change (all?) would
be needed. One idea could be to break this in different workflows with
appropiate testing while adding the core functionality at first.

Looking forward for your feedback.

[1] https://github.com/dkruces/kdevops/commit/c4ae4984e88cfb0d4beb9b0356346a7daf802191

Daniel

To: kdevops@lists.linux.dev
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: Daniel Gomez (Samsung) <d+samsung@kruces.com>
Cc: gost.dev@samsung.com

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
Daniel Gomez (13):
      Makefile: add ansible_python_interpreter to ANSIBLE_EXTRA_ARGS
      scripts/ansible.Makefile: add run helper
      Makefile: replace ansible-playbook local calls with helper
      linux: Makefile: use helper for bootlinux-local
      Makefile: add run_ansible_playbook_hosts helper
      Makefile: extend use run_ansible_playbook_hosts helper
      Makefile.kdevops: add run helper fix
      Makefile.kdevops: allow to use verbose make options
      scripts: refs: remove Q overwrite
      scripts: add ansible helper with hosts and extravars
      ansible.Makefile: enhance ansible verbosity
      ansible.cfg: add output when a task is started
      ansible.cfg: switch stdout_callback to dense

 Makefile                                 | 20 +++----
 Makefile.btrfs_progs                     |  7 +--
 Makefile.build_qemu                      | 34 +++++-------
 Makefile.hypervisor-tunings              |  7 +--
 Makefile.kdevops                         | 57 ++++++++++----------
 Makefile.linux-mirror                    |  7 +--
 Makefile.postfix                         |  7 +--
 ansible.cfg                              |  4 +-
 scripts/ansible.Makefile                 | 62 ++++++++++++++++++++++
 scripts/devconfig.Makefile               | 18 ++++---
 scripts/dynamic-pci-kconfig.Makefile     |  8 ++-
 scripts/guestfs.Makefile                 | 11 +---
 scripts/install-menuconfig-deps.Makefile |  9 ++--
 scripts/journal-server.Makefile          |  5 +-
 scripts/kconfig/Makefile                 |  5 +-
 scripts/provision.Makefile               |  3 +-
 scripts/refs.Makefile                    |  2 -
 scripts/systemd-timesync.Makefile        |  5 +-
 scripts/terraform.Makefile               |  6 +--
 scripts/vagrant.Makefile                 | 14 ++---
 workflows/fstests/Makefile               | 11 ++--
 workflows/linux/Makefile                 | 89 +++++++++++++++++---------------
 22 files changed, 204 insertions(+), 187 deletions(-)
---
base-commit: 0e49930f930708da2553905a9462908f39858ae6
change-id: 20240827-ansible-cleanups-142de35ffae9

Best regards,
-- 
Daniel Gomez <da.gomez@samsung.com>

