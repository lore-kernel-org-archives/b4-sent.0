From: Federico Amedeo Izzo <federico@izzo.pro>
Subject: [PATCH v3 0/2] Add regulator support to qcom-ufs driver
Date: Sat, 23 May 2026 12:25:50 +0200
Message-Id: <20260523-qcom-ufs-regulator-support-v3-0-1be2a80a2577@izzo.pro>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43PSw7CMAwE0KugrDGi6YeKFfdAXaSx2wYBCU4T8
 VHvTloWiB3Lkaw345fwxIa82K9egikab+w1hXy9EnpQ157AYMpCbmW1LWUGN20vEDoPTH04q9E
 y+OCc5RGKqiJVKUy3SiTAMXXmvuDH5pN9aE+kx1mcLzpO2Dgwqd8SdAEUIqB3DnoNyCYSQ8wgg
 zrPd7Koa426O5jn024c2xkbjE9rHssrUc6lf62OMqGYk66lohJb/UWbaZreAI8SSCIBAAA=
X-Change-ID: 20260521-qcom-ufs-regulator-support-466ea6ad202a
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779531961; l=2012;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=BNeNAsIEjtakdZGKY2bfmyt0EsEyor0COka868FsyO8=;
 b=6eX9ICsNI+Hre8MSZtguERN9xpFukKkSB+RgkhVAlSrZ3HdpcxBBIm9m3JX9APpNh+ZywD1rR
 dA0o1YLv1F9ClilcbhVs+ZxvNAfCtsXXkzuywD8JuxBqZtil0nXilOX
X-Developer-Key: i=federico@izzo.pro; a=ed25519;
 pk=XfmNfpH48k8jLbId5NKrp0yoKoFb/uLjr97qIxBImBw=
X-Endpoint-Received: by B4 Relay for federico@izzo.pro/20251017 with auth_id=544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series enables UFS support on SC7280 devices with UFS3.1.
SC7280 devices with UFS2.2 were already working.

The root cause was ABL leaving vcc-supply regulator disabled on UFS3.1
devices, and enabled on UFS2.2 devices that worked fine without
regulator support.

Signed-off-by: Federico Amedeo Izzo <federico@izzo.pro>
---
Changes in v3:
- Fix bug causing HPM mode not being applied. Removed LPM/HPM hack
- Read regulator mode from dts property instead of hardcoding it
- Link to v2: https://patch.msgid.link/20260521-qcom-ufs-regulator-support-v2-1-d3ec82ae5dbc@izzo.pro

Changes in v2:
- Add vccq2-supply for UFS2.2 devices without internal eLDO regulator
- Fix wrong topic
- Link to v1: https://patch.msgid.link/20260521-dpu-add-dspp-gc-driver-v1-1-83372488cdcf@izzo.pro

To: Sumit Garg <sumit.garg@kernel.org>
To: u-boot-qcom@groups.io
To: u-boot@lists.denx.de
Cc: Jaehoon Chung <jh80.chung@samsung.com>
Cc: Peng Fan <peng.fan@nxp.com>
Cc: Casey Connolly <casey.connolly@linaro.org>
Cc: Neil Armstrong <neil.armstrong@linaro.org>
Cc: Tom Rini <trini@konsulko.com>
Cc: Luca Weiss <luca.weiss@fairphone.com>
Cc: Aswin Murugan <aswin.murugan@oss.qualcomm.com>
Cc: Federico Amedeo Izzo <federico@izzo.pro>
Cc: Bhupesh Sharma <bhupesh.linux@gmail.com>
Cc: Neha Malcom Francis <n-francis@ti.com>
Cc: Julien Stephan <jstephan@baylibre.com>
Cc: Marek Vasut <marek.vasut+renesas@mailbox.org>

---
Federico Amedeo Izzo (2):
      regulator: qcom-rpmh-regulator: fix regulator mode mismatch
      ufs: qcom: add ufs host regulator support

 drivers/power/regulator/qcom-rpmh-regulator.c |  3 +--
 drivers/ufs/ufs-qcom.c                        | 33 +++++++++++++++++++++++++++
 drivers/ufs/ufs-qcom.h                        |  4 ++++
 3 files changed, 38 insertions(+), 2 deletions(-)
---
base-commit: 744cf5d4e398c5f657e5c3eeb44d00fa5175dc85
change-id: 20260521-qcom-ufs-regulator-support-466ea6ad202a

Best regards,
--  
Federico Amedeo Izzo <federico@izzo.pro>

