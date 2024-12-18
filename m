From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 00/12] kdevops: Various fixes
Date: Wed, 18 Dec 2024 11:29:54 +0100
Message-Id: <20241218-jag-bringup_fixes-v1-0-0bf2e07c640c@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACKkYmcC/x3LQQqAIBBA0avIrBtoBiHoKhGhNtm0sFCKILp70
 vLx+Q8UySoFevNAlkuL7qmCGgNhdSkK6lwN3LIlpg43F9FnTfE8pkVvKchWFvLBMpGD+h1Z/lC
 3YXzfD92yW1xjAAAA
To: kdevops@lists.linux.dev
Cc: Joel Granados <joel.granados@kernel.org>, da.gomez@samsung.com
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=2259;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=osn+tf2J1/rv3p+LR5X9rn6FBuri2hBkCrAErFzy/q0=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGdipCpfQhfBp71ToxvNInQOJ77g2aUhNE2Od
 j7L51N26a+ehIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnYqQqAAoJELqXzVK3
 lkFPKaYL/22mFiDdHnvu41pC6nNYIxYxn01GxfHNTsrDnrMeIaOiANwi+tKVfddLWFZw1BpJBCL
 v0QHkU5Bxtw3Ser4n+QOZ+f5pyQvmHINeNWBpf/xR5aoig/hq9zeJ3d3jhMdLlLRlRI6XhHbB8x
 qqHzf5CiVXwT4NCeJd0KOnXFEGP1JGFBEKIpbdC+IECye6AjFIbMTfe3JkYPirM89U4n6/cbE8a
 jI1hkRfi+fxPqRAKaek3lAuyRrUotyLBrbWQOFGkQY/yc9qq958vyTIrMIY7xeRsm7ef3ty7QWD
 IXRyr0diIsubpC3AziVvqgMj7Kw4ibX4xO+wl/KanUmn6giWLzO4nVY+WUktecRhNr2LHOhBGsZ
 qkBA5ykY9+9mGnrkkkPwSg06f0G0jm+EKoTccN3oI/NHzg0sgoLZGhd9D3Nk/Jtleo9pByEzB1y
 NOdDiSQjWHHf9BXlQDf9iSfRwIRIW/XxS4+CPuKbRdUKXIkKA5UBZgh7jkcwmPgVyMzzdeIoqw5
 V0=
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

