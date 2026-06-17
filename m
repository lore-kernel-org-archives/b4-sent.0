From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Subject: [PATCH v5 0/5] Changes in v5:
Date: Wed, 17 Jun 2026 12:26:12 +0300
Message-Id: <20260617-ufs_tool2-v5-0-1cf099f71111@mobileye.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADVoMmoC/23NQQ6CMBQE0KuYrq1pP7W0rryHMQbKr9QANRSIh
 HB3KW6IYTnJvJmJBGwdBnI5TKTFwQXnmyWcjwdiyqx5InXFkgkwkEyylPY2PDrvK6Ccm0ToRGp
 mBFn67xat+6xbt/svhz5/oeniQGyULnS+HdezAWJvb3cAyqhNtbUgs5wrc6197ioc8WR8TeL0k
 Gyx2uJkwZm2XHFUEkDvYLHBnG+xiFgUmKrcgGD/eJ7nL5T8kqoxAQAA
X-Change-ID: 20260607-ufs_tool2-11c3493690c4
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3793;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=n7imxsJ48h5XwII+Zs5b3opfXpHbUYLzmBcsuNUX748=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqMmg9zlEw9fg3poIZz98qVoPdNQlqARrk1/AHv
 uPA3QfHF6GJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCajJoPQAKCRCfmumUluiO
 OTcyD/9NJ3uI6KJ6JKtkgLTfmuzi5jvcjpheLJj4XAJ9Y/NK459Lb7JX1jVAJW/T2/LzdEsCXWs
 666iwEMuS+AWNqPNj+Yb8etf1NiNb6dnH2puKBK1JiBiS3fJsyiuOvJIXghYVXLtrmRcyR2Gi2F
 ZuUC7YOBDJyzOzi39bG4hR948k7TIjUaDmFjchFwjgkdEWkWn+O6tOyeVQdS4pN6XHgvWpnQ6ij
 72cSqRVeL41xRV/vCB/g38kZ2W7vJEti2e9DTnYxMwVc0kPUVTHGFrTwyD4d4FvR6pTFLsRcksw
 zX231gUu5LbgI/u1DcoPRZl3uN6fimsCbeHqox4Nij+5SNWbhL2g8/7s1JUtrTLTJ5iBVAeQKS7
 U6LXmxWMKa0VuPgKydHFORn8yhvjk12TSh7q7cT289Q9VLJ8qjW4ipRDi6/jl44lBxmTdHH7xna
 LRiQgpd0JbOATX49A2VNZiXTdOgN9QQF6CFCxm6LmYpT0mVpidWuwEB6yMi+cDiF1DAs/0ZuWWB
 8RIOxE9C/ScaZ8alWXY0R6Ww9XG3FfdoK8rAJ7pplde6U+x0PzTtUcl4PJb736RIVr2hQXIQf+S
 1lpX8ck1fUYypK6y26lsuGzy0m7IvtLrZ5dfYWlr4x7ZUccwRk5poDVfn2EmptyvYFD/7p3acL6
 WukpRqev4VYfUmg==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to Tom's remarks
- Improve the help structure and content.
- Mark functions as static.
- Remove documentation of exported functions 
- As asked, addded a kernel doc to:
   ufshcd_query_desc_idn_geometry, ufshcd_query_desc_idn_config,
   ufshcd_query_desc_idn_device, ufshcd_query_desc_idn_unit,
   ufshcd_print_idn_geometry_desc, ufshcd_print_device_descriptor
   ufshcd_print_unit_descriptor, ufshcd_query_desc_idn_power
   ufshcd_print_ufs_power_params, ufshcd_query_user_flag
- Add command get_lun
- Add command clear_lun
- Add command provision
- Removed float use in the code, it breaks arm compilation.
- Add wmb. wmb is not implemented in x86, brakes the UFS compilation in
  x86.
- Test: ./tools/buildman/buildman mips64el arm x86_64 -a UFS -a CMD_UFS -a SCSI -a CMDLINE
	Passed 94 boards, but consumed too much time and could not continue.
- I stil fail to run on gitab ci, My adminitratos do not know how to
  help me, i have no runners.
- github does not work as well, no runners. I do not have Azure acount.

- Link to v4: https://patch.msgid.link/20260611-ufs_tool2-v4-0-a4de78bc2409@mobileye.com

Changes in v4:
Apply Tom's remarks.
- move exported functions from drivers/ufs/ufs.h to include/ufs.h
- document the above exported functions in kernel-doc style.
- Fix commit title: "extend the current command line..."
- rework rst file, verified the html version.
- Run pull request in CI. 

- Link to v3: https://patch.msgid.link/20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com

Changes in v3:
- remove set_dev_desc command. DeviceDescriptor is not writable 
- Beautify the rst document
- Link to v2: https://patch.msgid.link/20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com

ufs: Exted cmd line

The UFS command provides utilities for querying, displaying, and modifying
UFS device configuration and descriptor information. It is commonly used to
configure UFS logical units (LUNs) in U-Boot, allowing storage devices to be
provisioned and reconfigured as needed.

Features:

* Display Device, Geometry, Unit, Configuration, and Power Descriptors
* Display LUN configuration and calculated capacities
* Modify fields in Device, Configuration, and Unit Descriptors
* Query common UFS runtime flags
* Commit configuration changes or clear all LUN configurations
* Decode and format descriptor contents for easier debugging
* Provision and configure UFS logical units

Changes in v2:

* Add HBA ID support
* Move ufs_tool.c to cmd/ufs.c
* Add myself as reviewer
* Rename patch subject to  "ufs: document the UFS command"

To: u-boot@lists.denx.de
Cc:      Neil Armstrong <neil.armstrong@linaro.org>
Cc:      Bhupesh Sharma <bhupesh.linux@gmail.com>
Cc:      Neha Malcom Francis <n-francis@ti.com>
Cc:      Tawfik Bayouk  <tawfik.bayouk@mobileye.com>
Cc:      Vladimir Kondratiev  <vladimir.Kondratiev@mobileye.com>

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
Raz Ben Yehuda (5):
      MAINTAINERS: Add myself to the list of UFS maintainers
      ufs: Expose selected UFS functions
      ufs: document the UFS command
      ufs: extend the current command-line interface
      ufs: wmb is not implemented in x86.

 MAINTAINERS               |    3 +
 arch/x86/include/asm/io.h |    2 +
 cmd/ufs.c                 | 1612 ++++++++++++++++++++++++++++++++++++++++++++-
 doc/usage/cmd/ufs.rst     |  499 ++++++++++++++
 drivers/ufs/ufs-uclass.c  |   18 +-
 drivers/ufs/ufs.h         |   52 --
 include/ufs.h             |  421 ++++++++++++
 7 files changed, 2536 insertions(+), 71 deletions(-)
---
base-commit: 0c035ff60c1e8caee7fccd2673ce75380dee825b
change-id: 20260607-ufs_tool2-11c3493690c4

Best regards,
--  
Raz Ben Yehuda <raz.benyehuda@mobileye.com>

