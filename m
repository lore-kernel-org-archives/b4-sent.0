From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Subject: [PATCH v3 0/5] (no cover subject)
Date: Mon, 08 Jun 2026 13:33:24 +0300
Message-Id: <20260608-ufs_tool2-v3-0-a9f181e86229@mobileye.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHSaJmoC/22NQQqDMBAAvyJ7bkqMEpue/EeRYtJN3aKmJCoV8
 e9N7LXHgWFmg4CeMMA128DjQoHcGKE4ZWC6dnwio0dkEFxILnnFZhvuk3O9YHluilIVUnFTQvT
 fHi19jtat+XGY9QvNlALJ6ChMzq/HbBHJ+9ddBOPMVspaIVudX0w9OE09rng2boBm3/cvw92o6
 bcAAAA=
X-Change-ID: 20260607-ufs_tool2-11c3493690c4
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Tawfik Bayouk <tawfik.bayouk@mobileye.com>, 
 Vladimir Kondratiev <vladimir.Kondratiev@mobileye.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2213;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=7fBbCj/9tXFiudNY2vw15eFxlB6lW7s58RlJd1Zt9Jg=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJpqPo2gJmhxKDBd6ca+qYarScUGR0WkETSmnn
 tSCY8jrYOuJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiaajwAKCRCfmumUluiO
 OYDkD/4ieZK9+V17TX8rOCF8cjXwuJoLT15PwVCFOxHneZF3qhvfMoWzx0IyKFk+O1h/+LHUEqz
 QRRS+bG2E9YIB9nI9EKFhrNneGGCNFY24Ns2ckP+mdLwc/2wbGt+JBKf/q1TcF1CYazM/378eBv
 sxn3jSrLkz+cgD+Ox/GR5A1HAImttmBA96DYg/KHcKbopApxQTVtTyuGoYGsKOmLRW2fjsgc2vT
 xqiKn9JHa0ZvCQ/vAmLZA2DV+LC4roIvh8SdI4DtDEcKpeFfTwE9n0RGIh9cfeWZoSunMqUPJXE
 HMHE2AFwJC3iU3+rtxqqmY/mkMZtoSN/OlrCEkoE6SGpMX2GVOWWFa7p6UG1jTgrAEzV+vbode6
 qNwqEYhfPWjHXfry5Zm5EgPgfnYP6s3hd43v+kEwP7fLB0PssTs22rBASWTS0D+L5TtLEnLlb0Z
 Q17JzJdf+pxoryodEJkzZkZ78tm5BIyoy6IufiW1afQsiLueG3eVlNFEAXySghdZ49BV6H5LYCc
 VCwm/ZHzROo8jAV5qO6mxesUzYRHBRdz7GpQ7tu1TE2PKVp9+77ibyd+oe085V9O33wgCfQtEO+
 01u7B8CKSGeGLHYnOXrLN2IgymwgBUGo6Mgb4+kvcgOvtT2+SsthXcUxKRoA8TMOcNaktLFuQT3
 SN0RGWoi4z4xVqQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
      ufs: Expose selected UFS functions
      ufs: Add flags according
      ufs: extending ufs cmd line
      ufs: document the UFS command
      MAINTAINERS: Add myself to the list of UFS maintainers

 MAINTAINERS              |    3 +
 cmd/Makefile             |    1 +
 cmd/ufs.c                | 1271 +++++++++++++++++++++++++++++++++++++++++++++-
 doc/usage/cmd/ufs.rst    |  202 ++++++++
 drivers/ufs/ufs-uclass.c |   18 +-
 drivers/ufs/ufs.h        |   16 +
 include/ufs.h            |  374 +++++++++++++-
 7 files changed, 1867 insertions(+), 18 deletions(-)
---
base-commit: 0c035ff60c1e8caee7fccd2673ce75380dee825b
change-id: 20260607-ufs_tool2-11c3493690c4

Best regards,
--  
Raz Ben Yehuda <raz.benyehuda@mobileye.com>

