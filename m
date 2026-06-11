From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Subject: [PATCH v4 0/4] (no cover subject)
Date: Thu, 11 Jun 2026 10:49:34 +0300
Message-Id: <20260611-ufs_tool2-v4-0-a4de78bc2409@mobileye.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAI5oKmoC/22N3wqCMBxGX0V23WJ/ZG5d9R4Roeu3XKiLTUciv
 nub3Uh0eeA751tQAG8hoFOxIA/RBuuGBOWhQLqthwdge0+MGGGCCFLhyYTb6FzHMKWal4oLRXS
 J0v7lwdj31rpcvxym5gl6zIG8aG0YnZ+3s8jy7l83MkywqZQxTNQNlfrcu8Z2MMNRux7ldOR7W
 e5lnuRaGSopSMGY+pHXdf0AXKqDo/QAAAA=
X-Change-ID: 20260607-ufs_tool2-11c3493690c4
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2576;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=jTOeOZvHuDLHfcDG89k/VxW/YkfHlJFsAbzuJFbr1OY=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqKmiTLVrDIxnOenrSSycPvHKnCRlIEnPoWkOD/
 oSQP9asiZaJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaipokwAKCRCfmumUluiO
 OUHtEACYIfcV6utxAZadS9+LcJNEpyK095S/RiygE2tsKQ2jJUL5OT3zkq5VeO9kNqLA7nPqx0N
 bzWBC99fpwt70cKj+7Rt/T3ZeLff+1KOtEmNsg2EnRg2xlwwS8rIblx1tJDk7pTUQF1T5So2Hna
 sZTwkymqrXgquw4u69KkH6kloIPtCYxVDLZKywiE0XgcN9yQOwipitWaBfaVycrTEIvg6tloNz+
 flGM4nne8XSjandA5J11vqNDJ40jUDQfvObHiapK3T+tu+PpBR73SWS7ScIPavHhH0dohj4LNMJ
 s2XWG6AWC7oRpkYkowffwx6ZMfyo5Dbf2QxRcIUDzB3/p85C/nt/+vkokow1tHTZpEzWPed/j86
 JRgoo7W45l8KUELHYLw8bNPB1QcpOOkjDW7ozSZfZnsWW86lN7SSB14g/WpyLuZleAt0f9kxdVn
 0ny5opAvFVJgRE/A5bah9GO6QwlEzYj4QKmNanSy4KoG7jrzhwNSDoywCGedls9WTW0d8JEUbCl
 LFdUHdbwkmzedZ3EaqUFbDRykxHg6nV92WcesyX5jnoC9xPQSbei9XvLAa00JBAsfvzo4DDWmcC
 PV+KMQpsRwrpH4MzQOMikWeI3Lf0HVD8zn/bE2yDtNS0nsUwrLoXrHDdMcQmeAgwky6jZI64pLm
 gvr4IzWkL6+V1rw==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changes in v4:
Apply Tim's remarks.
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
Raz Ben Yehuda (4):
      MAINTAINERS: Add myself to the list of UFS maintainers
      ufs: Expose selected UFS functions
      ufs: extend the current command-line interface
      ufs: document the UFS command

 MAINTAINERS              |    3 +
 cmd/ufs.c                | 1264 +++++++++++++++++++++++++++++++++++++++++++++-
 doc/usage/cmd/ufs.rst    |  462 +++++++++++++++++
 drivers/ufs/ufs-uclass.c |   18 +-
 drivers/ufs/ufs.h        |   52 --
 include/ufs.h            |  603 +++++++++++++++++++++-
 6 files changed, 2332 insertions(+), 70 deletions(-)
---
base-commit: 0c035ff60c1e8caee7fccd2673ce75380dee825b
change-id: 20260607-ufs_tool2-11c3493690c4

Best regards,
--  
Raz Ben Yehuda <raz.benyehuda@mobileye.com>

