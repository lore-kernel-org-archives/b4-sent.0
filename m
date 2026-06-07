From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Subject: [PATCH v2 0/5] ufs: Exted cmd line
Date: Sun, 07 Jun 2026 18:45:30 +0300
Message-Id: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABqSJWoC/yXM0QpAMBSA4VfRubaa0cSrSGIOjmTaGSl5d8PlV
 3//BYyOkKGMLnB4EJNdA1QcgZnadURBfTAoqbTUMhf7wI23dlEiSUyaFakupMkg9JvDgc7vVdW
 /ee9mNP4dwH0/tWUcNm0AAAA=
X-Change-ID: 20260607-ufs_tool2-11c3493690c4
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Michal Simek <michal.simek@amd.com>, Julien Stephan <jstephan@baylibre.com>, 
 Udit Kumar <u-kumar1@ti.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Dinesh Maniyam <dinesh.maniyam@altera.com>, 
 Heiko Schocher <hs@nabladev.com>, Simon Glass <sjg@chromium.org>, 
 briansune <briansune@gmail.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1685;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=0YZa3XgrAxE3m6lpx/T7mJEs/9QPTvZVXgxLoQZ8F+E=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJZIsmgGnF7xuKRorEvGAhY7S6BI+mICzICgM+
 9QiqjDBeVWJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiWSLAAKCRCfmumUluiO
 OUskEACMLRVhWHAeO3rrjY1LXmHNjlsJmJ4+mGPeaURsPKYMnjCugelCHNSlcvH6mD3ihx4G2L1
 nTbO1DQg9sZUiSDSAutpK31nobPaLA0O9+09w/3MX80/+VS1skilWuJ1db78ai29jrXnFl+HHpH
 QCeWEuljjV7GbxvKZhKW7/sVMoNxNkKdn05iZ6ngwFxEACaemy8s5A06mUmeYHaH+N19kMTXJqE
 psE7G2TDznD/8KHw+Hp2qCUPxx4JE45JE1Azjny7J4zefhy+qL5jAO7cuWr/U4rNDs6wfPBQEVb
 AXVHDlqA23UDMXWqU7t7+UjO5wkuN2vL5T94cA2uU4BvCbTEp3YhvRlkTTyVdNqfLNocK0i2liI
 3xzV3mqyqMzB6Zb748utb3qg36wcuOULZagnWXWwjUBTHKGvTIKHk04e/1KptDgyxMHz1Ro/iNc
 6tYZ5gkigA+2vCPQjC9lp38HRNdn/FBxkKHALE+dOH2m4sMf2coYElnlEoW5TR6C7OH7Zdpr209
 hjEtCKCBu2GY11Xfkfu40iuoykgo/id1VHn/q4RryFQj+nnmtYLtA915WgCEOnXQdSeGPw8Jqlq
 qZ8BL9kUpjH2q9zAB1rUt9Pvf+JHt1KmtK4wPpXoU23Ht9Me01Xz0+oI36GEKJIUbs6ZqZPKKa+
 AeVYnjXo/7Fz0gA==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

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
 cmd/ufs.c                | 1309 +++++++++++++++++++++++++++++++++++++++++++++-
 doc/usage/cmd/ufs.rst    |  226 ++++++++
 drivers/ufs/ufs-uclass.c |   18 +-
 drivers/ufs/ufs.h        |   16 +
 include/ufs.h            |  374 ++++++++++++-
 7 files changed, 1929 insertions(+), 18 deletions(-)
---
base-commit: 0c035ff60c1e8caee7fccd2673ce75380dee825b
change-id: 20260607-ufs_tool2-11c3493690c4

Best regards,
--  
Raz Ben Yehuda <raz.benyehuda@mobileye.com>

