From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/3] Initial QMP USB PHY support for SM8475
Date: Wed, 15 Jul 2026 03:06:53 -0400
Message-Id: <20260715-sm8475-bup-usbss-v2-0-2d8def39b190@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OwQ6CMBBEf4Xs2TW0VIqe/A/DweIiNZFityUaw
 r9bwKPHl8y8mQmYvCWGUzaBp9GydX0Cucug6a79ndDeEoPMZZlroZCfldIHNHHAyIYZqawKdVS
 6aEuCVBs8tfa9Ki/1xhzNg5qweJZEZzk4/1k3R7Hk/upHgTkaWWlhSBpFzXnwLrh+/ySo583s6
 RXT5/Cbm+cvKsStF9EAAAA=
X-Change-ID: 20260714-sm8475-bup-usbss-e68349473f6e
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784099250; l=1426;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=t27yyUkbtJ63OblVXNLeuoM4AskzDQ+ORg37wek6PuI=;
 b=uPsi2rUF9M6thEvBqtonyXw0DDhZ28DRs8306mJSSJr6aU7F+JMjb6FUMycE6xaK/Hh8it/ja
 66CgB/sqH9QD/64RCz05pjGvrNtrUnMJcF89KalVmF0uJ3Aun3u4LJ5
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on the following patch:
[1] https://lore.kernel.org/all/20260711-sm8450-qol-qmp-v2-2-d14353bd6ff4@proton.me/

This series adds support for the QMP USB PHY found in the SM8475 SoC.
The initialization sequence varies noticeably when compared to the one used
in the SM8450 SoC, hence the need to add support for this PHY.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Split series in subseries (pcie, usbss)
  - Sorry, it should have been like this from the start!
- Add notice about base commit
  - Reason why calibrate_dp_phy is not present
- Modify referenced swing and pre-emphasis tables
- Move v1 PLL tables to SM8475 support patch
  - Warnings are generated at build time otherwise
- Link to v1: https://patch.msgid.link/20260714-sm8475-bup-v1-0-b2871be2b4ec@proton.me

---
Esteban Urrutia (3):
      dt-bindings: phy: qcom,sc8280xp-qmp-usb43dp-phy: Add SM8475 QMP PHY
      phy: qcom: qmp-combo: Specify PLL version in qmp_v6_dp_serdes_tbl structs
      phy: qcom: qmp-combo: Add SM8475 support

 .../phy/qcom,sc8280xp-qmp-usb43dp-phy.yaml         |   1 +
 drivers/phy/qualcomm/phy-qcom-qmp-combo.c          | 259 +++++++++++++++++----
 2 files changed, 215 insertions(+), 45 deletions(-)
---
base-commit: 43d250aa1ba24a4124162b7310a7010ff6a141be
change-id: 20260714-sm8475-bup-usbss-e68349473f6e

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

