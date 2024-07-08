From: Emil Velikov <emil.l.velikov@gmail.com>
Subject: [PATCH kmod v2 00/17] man: minor improvements, post the scdoc
 conversion
Date: Mon, 08 Jul 2024 14:43:08 +0100
Message-Id: <20240708-man-v2-0-a23df6ef871e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOzsi2YC/yWMyw6CMBBFf4XM2pq+qOLK/zAsCh1gEqGkNY2G9
 N+tdXlu7jkHRAyEEW7NAQETRfJbAXlqYFzsNiMjVxgkl5q3UrHVbuyilTPYChzMBOW5B5zoXSu
 PvvBC8eXDp0aT+K1/3whR/SQYZ4MzV6Od7ozq7vNq6Xke/Qp9zvkLjKTX6JYAAAA=
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720446209; l=2650;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=+Xy7sIFsLWX8oDHDml1nqxSfzsgAHAICJCGlyTYQN0s=;
 b=1M7eGaaTMBZxtlZoqGpKD2DlWHIHsOSFWf+sJ0m962CHNhPhC/HoiZjwBSbt82y7lv3WQSha7
 WThxKosKPAWDDvxtL8FJvhXawo1s2d5Cty+jNdsyIedlFRHhgUnDhmE
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello all,

Here is the remaining patches from my scdoc series, re-spinned with all
(:fingers-crossed:) the comments addressed.

The series includes:
 - patch 1-5 - trivial fixes as white space, punctuation, etc
 - patch 6-14 - expand documentation around {depmod,modprobe}.d
   handling, remove open-coded .d and .conf references
 - patch 15 - remove "maintained by" references
 - patch 16 - NEW: replace all AUTHORS sections with suggested snippet
 - patch 17 - list short and long options on separate lines

Note that make distcheck has regressed on the master branch, seemingly
due to the recent weakdep test.

---
Changes in v2:

- move extra bold annotation to correct patch - 2 -> 1
- reword the configuration directories section as suggested - 7, 11
- tweak MODPROBE_OPTIONS wording - 13
- add extra patch to rework the AUTHORS section as suggested - 16

- Link to v1: https://lore.kernel.org/r/20240611-man-v1-0-bd6864d49639@gmail.com

---
Emil Velikov (17):
      man: add some extra bold/italic annotations
      man: white space fixes
      man: misc punctuation fixes
      man: some options take an argument, mention that
      man: couple of grammar/language fixes
      man: stop removing DISTCONFDIR lines
      man: depmod.d: document the config file order handling
      man: depmod.d: factor out a CONFIGURATION FORMAT section
      man: depmod.d: rework the opening description sentence
      man: depmod: remove hard-coded /etc/depmod.d references
      man: modprobe.d: document the config file order handling
      man: modprobe.d: factor out a CONFIGURATION FORMAT section
      man: add few mentions about MODPROBE_OPTIONS
      man: modprobe: remove hard-coded /etc/modprobe.d references
      man: remove the "Maintained by" references
      man: rework AUTHORS section
      man: list options one per line

 man/Makefile.am       |   8 ++--
 man/depmod.8.scd      |  78 ++++++++++++++++++++----------------
 man/depmod.d.5.scd    |  61 +++++++++++++++++-----------
 man/insmod.8.scd      |  11 +++---
 man/kmod.8.scd        |  24 +++++++----
 man/lsmod.8.scd       |  13 +++---
 man/modinfo.8.scd     |  38 +++++++++++-------
 man/modprobe.8.scd    | 107 +++++++++++++++++++++++++++++---------------------
 man/modprobe.d.5.scd  |  61 +++++++++++++++++-----------
 man/modules.dep.5.scd |  22 ++++++-----
 man/rmmod.8.scd       |  25 +++++++-----
 11 files changed, 268 insertions(+), 180 deletions(-)
---
base-commit: fa715f8c8b78a09f47701ce1cf46e9b67a49b8d0
change-id: 20240523-man-743d6e51eb6f

Best regards,
-- 
Emil Velikov <emil.l.velikov@gmail.com>

