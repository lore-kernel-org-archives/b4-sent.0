From: Federico Amedeo Izzo <federico@izzo.pro>
Subject: [PATCH v4 0/2] Add regulator support to qcom-ufs driver
Date: Sat, 23 May 2026 15:04:23 +0200
Message-Id: <20260523-qcom-ufs-regulator-support-v4-0-45639533b06d@izzo.pro>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43PS07EMBAE0KuMvKZRYudjseIeiEXH7iRGMDbt2
 JqPcnfsYcGwQSxLar2qvopI7CiKp8NVMGUXnT+W0D0chFnxuBA4W7KQjRyaXrbwafwHpDkC05L
 ecfMMMYXgeYNuGAgHtOUWRQEC0+xON/zl9TvHNL2R2apYL2Yu2LYy4e8SGxKgtWBjCLAYsOwyM
 eQWWtBKjbLT2lgzP7vLxT8G9hVbXSxrzrdXsqyl/1qdZUGtIqMlUm8n84PW0VndS+pPSUED7UQ
 SdYOyH8c7ad/3L4vyQfxsAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779541471; l=2251;
 i=federico@izzo.pro; s=20251017; h=from:subject:message-id;
 bh=iGFuAXRx0a5aMTjvWY84INYa4b+EoFMclzVkqykBRBA=;
 b=Cyug6TTghLgg2J7c4C5IIB2j0tRiHW3wkE5pHYJbzrdIO5E8Gia/h4wE0DAVpiW7R5Q8Jc0eZ
 1VhitaYDZ1yCTwfi4qHCv9oP2pmBlLi3R/DOnLoVCngEEGFf9tSjGZn
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
Changes in v4:
- Improve regulator mode fix: apply current mode during enable
- Remove regulator mode code from qcom-ufs driver
- Link to v3: https://patch.msgid.link/20260523-qcom-ufs-regulator-support-v3-0-1be2a80a2577@izzo.pro

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

 drivers/power/regulator/qcom-rpmh-regulator.c | 106 ++++++++++++++------------
 drivers/ufs/ufs-qcom.c                        |  25 ++++++
 drivers/ufs/ufs-qcom.h                        |   4 +
 3 files changed, 85 insertions(+), 50 deletions(-)
---
base-commit: 744cf5d4e398c5f657e5c3eeb44d00fa5175dc85
change-id: 20260521-qcom-ufs-regulator-support-466ea6ad202a

Best regards,
--  
Federico Amedeo Izzo <federico@izzo.pro>

