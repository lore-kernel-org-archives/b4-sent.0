From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH v3 0/3] arm64: dts: qcom: x1e80100-hp-x14: add
 usb-1-ss1-sbu-mux
Date: Tue, 10 Jun 2025 19:25:38 +0200
Message-Id: <20250610-hp-x14-v3-0-35d5b50efae0@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJJqSGgC/3XOTQ7CIBCG4asY1mIGSqu48h7GBX+VSZrSQCXVp
 neXNrrT5ftl8mRmklxEl8h5N5PoMiYMfYlqvyPGq/7uKNrShAOvQYCkfqATExRaZk+NNrqRkpT
 jIboWpw263kp7TGOIz83NbF0/BIMvkRkFqoWrjeJ15Yy8hM4m40PoUugeY/kkHTS+yOpl/tvgx
 bBVI5g4glCg/hrLsrwBkQJkce0AAAA=
X-Change-ID: 20250409-hp-x14-0f1d86bcb699
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1749576339; l=1600;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=tF8XhYd/zphv9FFb9CjA8PI63MvoFCSonZ/lwafrBzk=;
 b=cGo+fNh3F4SqVGlTj+EZCHgyUM2pP7V+Zi0yY/OdweAwkTCKuoS2CafOqCLXfFr3arZ4pX9pP
 GM4ykBwAzupC5jaZxMiV+jE9uXnARhoAIaKqrJBokZag8NSbyyJ4nbA
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The usb_1_1 port doesn't have the PS8830 repeater, but apparently some
MUX for DP altmode control. After a suggestion from sgerhold on
'#aarch64-laptops' I added gpio-sbu-mux nodes from the x1e80100-QCP
tree, and this appears to work well. It is still guesswork, but
working guesswork.

Added and rewired for usb_1_1

Also, did some more changes as tested here:

- remove unused i2c buses
- amend order of nodes.

The series is based on [1] from Johan.

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Changes in v3:
- rebased to next-20250610 in preparation for X1P42100 variant support
- Link to v2: https://lore.kernel.org/r/20250410-hp-x14-v2-0-d36414704a0a@oldschoolsolutions.biz

Changes in v2:
- removed overlapping patches with [1] and [2] - thanks Johan
- Link to v1: https://lore.kernel.org/r/20250410-hp-x14-v1-0-b4e5ca253ec9@oldschoolsolutions.biz

[1] https://lore.kernel.org/lkml/20250328084154.16759-1-johan+linaro@kernel.org/
[2] https://lore.kernel.org/r/20250319160509.1812805-1-juerg.haefliger@canonical.com

---
Jens Glathe (3):
      arm64: dts: qcom: x1e80100-hp-x14: add usb-1-ss1-sbu-mux
      arm64: dts: qcom: x1e80100-hp-x14: remove unused i2c buses
      arm64: dts: qcom: x1e80100-hp-x14: amend order of nodes

 .../boot/dts/qcom/x1e80100-hp-omnibook-x14.dts     | 98 ++++++++++++++--------
 1 file changed, 62 insertions(+), 36 deletions(-)
---
base-commit: b27cc623e01be9de1580eaa913508b237a7a9673
change-id: 20250409-hp-x14-0f1d86bcb699

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

