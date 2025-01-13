From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RESEND 00/12] kdevops: Various fixes
Date: Mon, 13 Jan 2025 12:52:58 +0100
Message-Id: <20250113-jag-bringup_fixes-v1-0-fb28030b1f26@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, mcgrof@kernel.org, 
 da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2259;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=osn+tf2J1/rv3p+LR5X9rn6FBuri2hBkCrAErFzy/q0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGeE/qHbTrEebk3ddDfMK7CFRx4ZDODU/Kuic
 wbk6+sGiQirRYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnhP6hAAoJELqXzVK3
 lkFPCh4L/RRerX18LG6eiNzQbTf4N8sgCu1op5CCSLAEDDPS31G+oZqjEXJ2iiSqj5gQ1BOZD1p
 JwYVT4v677u/9aADk3uP2aogmYcTku3F59crtjtfWQKNv/voJIoa8N+MgJCkLqEJfhEhPMW4Bdl
 CEF4WhXEBS1Nw2xQ/MYxccjk9X8YWsPXaYxOVbXgl3GvaNAlvWLffXd+7avw4MScuJH+2sooeim
 kMtE9vYe4tgB1EduzzqYQp1TJryY5lMMSiT+6G4flwPGtKvIlAo1M/d2Rg93EWv/3XnPnw7yCcA
 tnz6JKzK0DXrP/imturlNiZ3UqNuc0wN8OCaN1LVAFzNGsMxe/R/yfElPSCtsnFWpL7TC0StvEj
 WK94GIY1ra0zuutwohvz9wDIQx9PxsGroJT1oAPl9hNWUDgaCDfPhIMFZKqyJYKWBwvMuJuRT8x
 b+ZtzBw+4nGkXCH4CGa728grUTZvL49xEj6/N3gwawOxq/e9Las+2V39dl4cur3TmZ+5O2d2tX8
 hg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are fixes that I used when doing a 'make bringup' on a debian
13 without libvirt. They seem unrelated because I changed things that
prevented me from moving forward. Get back to me if I need to separate
these in some way.

Summary of changes (more information in commit messages):
* Adjust the heuristic on becomming sudo
* Prefer -K ansible argument for getting the sudo password
* Use full paths when using tasks from other roles
* Call libvirt configuration tasks when doing the bringup

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (12):
      Kconfig: Add error path in conf_value_to_yaml
      scripts: Adjust heuristic to see if current user can sudo
      ansible: libvirt_user: Install additional pkgs for debian
      Makefile: Add virsh and libvirtd to minimum dependencies
      ansible: Add build-deps tag
      ansible: Use full paths when importing tasks
      ansible: Run sudo by using the '-K' ansible arg
      ansible: Install libvirt deps and enable user
      ansible: Reduce long ansible messages for readability
      bringup: Use full path when creating custom_source file
      scripts: Return the full default path of the pool path
      ansible: Set running_user explicitly to the USER var of the script

 Makefile.min_deps                                  |  2 ++
 playbooks/roles/bringup_guestfs/tasks/main.yml     | 32 ++++++++++++++++------
 .../libvirt_user/tasks/enable-user/debian/main.yml |  7 +++--
 .../roles/libvirt_user/tasks/enable-user/main.yml  | 12 +++++---
 .../tasks/install-deps/debian/main.yml             |  2 ++
 .../roles/libvirt_user/tasks/install-deps/main.yml | 15 +++++++---
 scripts/bringup_guestfs.sh                         |  3 +-
 scripts/get_libvirsh_pool_path.sh                  |  2 +-
 scripts/guestfs.Makefile                           |  5 ++--
 scripts/kconfig/confdata.c                         | 16 +++++------
 scripts/libvirt_pool.sh                            | 25 ++++++++++++++---
 11 files changed, 86 insertions(+), 35 deletions(-)
---
base-commit: b9e7570e72dac2df62d2ba80b01e3ff534316517
change-id: 20241217-jag-bringup_fixes-24ef1bc4211a

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

