From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/5] NFC support for five Qualcomm SDM845 phones
Date: Fri, 03 Apr 2026 15:58:45 +0200
Message-Id: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJXHz2kC/1XMQQ6CMBCF4auQrq1pB0rEFfcwLqDMyCSmkBYbl
 HB3Cxtl+V7yf4sI6BmDuGaL8Bg58ODSyE+ZsH3jHii5S1uAAqO1vsjB4fh8BenISqsUkrYdNVU
 rUjF6JJ537XZPu+cwDf6941Fv7+aUKgc4OFFLJQ0BkCkKUgg1zzyd7UdsSoT/sjiWkMockZQBW
 7W2/JXrun4BT7IzEN4AAAA=
X-Change-ID: 20251118-oneplus-nfc-c00ef1cdfa9b
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1943; i=david@ixit.cz;
 h=from:subject:message-id; bh=dXC2Ls22VsTuntAg533+4rpSlzX0Ms0eP5VcFmrXtfk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8eakJsX6gGd+ScB5FPM+p/JQi2wBwOsMnUt/
 Y+mx1bVEZCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmgAKCRBgAj/E00kg
 cvw2EACQpcKTZBTFP8x4aSpZdX/7zbcUPaMqqAgc1LEA1RcNxdW/5+v8cSHgTE69USU73OadJiR
 YBvX6FjhraJ+XpV0J9QJVAntl4yaUJUX/N7pHYo0DTGsvAa1xkTVNO7XIoDWm8OYBxB1c5cfiDh
 HP1bDeVfCet7LBkAGF41xLFYX478bo3PXUTWgPEp+EUpsHQ/mmpGbt+H3Br8w2M7vqcELo1r3FC
 kpyzezb7jQfsQSRXxbAZEE3JHqSnO/CVxBohOw1q5E1ncaubymGFMHwXOvU3MEa/MY4XUqd+62F
 lrV0Le1/DB+3Xp16aIhu5AC1igPEeLPLKV/2G225RAaJleEwOQOkbDa2pNPoa01hBH3M7L+Z+A1
 VFMi31buq9YJJXqid2bmT+s7uwEq3waDXSpV8qksH0Ysw6G7yIucbg/LaGCCsR0N5cilcKb0Axn
 mniYlTwKKSfmFTmWSkuMc5lvQiRR056g98KOHYxRBDc1BziFmR87P0QW4hg6wWSJaSSx5cCybdJ
 tJfDy+5EbkS1aK3kQZXGVfDFbgbHBpjMB0nbnGT/WExn7/jemnAIjD7TrPDBFPd9wuU3mUx4OeN
 nAzVrPuFC9trE09Ac5jp3St6IqwhhjeXzAUTVNt28/cP170+VPKRo7CD5PPpPHBebxUGR8Gu1Ah
 XgRMuOG02rDEUGA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- OnePlus 6 / 6T
 - Pixel 3 / 3 XL
 - SHIFT 6MQ

Verified with NFC card using neard:

systemctl enable --now neard
nfctool --device nfc0 -1
nfctool -d nfc0 -p
gdbus introspect --system --dest org.neard --object-path /org/neard/nfc0/tag0/record0

or use gNFC:
  https://gitlab.gnome.org/dh/gnfc/

successfully detecting and reading a tag.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Added Pixel 3 / 3 XL support.
- Lower drive-strength from <6>, to <2> which downstream kernel uses.
- Took full ownership of OnePlus 6 NFC patch as original author prefer to keep annonymous. (Krzysztof)
- Enable sleep states (pinctrl).
- Link to v2: https://lore.kernel.org/r/20260324-oneplus-nfc-v2-0-3eef052c9bc6@ixit.cz

Changes in v2:
- Use interrupts-extended. (Konrad)
- Dropped QUESTION prefix, as it's verified this settings work.
- Added compatible for OnePlus 6 based on schematics.
- Corrected axolotl NFC compatible based on information from Alexander (SHIFT).
- Link to v1: https://lore.kernel.org/r/20260322-oneplus-nfc-v1-0-5f22f544f0e2@ixit.cz

---
David Heidelberg (5):
      dt-bindings: nfc: nxp,nci: Document PN557 compatible
      arm64: dts: qcom: sdm845-oneplus: Enable NFC
      arm64: dts: qcom: sdm845-shift-axolotl: Correct touchscreen sleep state
      arm64: dts: qcom: sdm845-shift-axolotl: Enable NFC
      arm64: dts: qcom: sdm845-google-common: Enable NFC

 .../devicetree/bindings/net/nfc/nxp,nci.yaml       |  1 +
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 31 ++++++++++++
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 57 ++++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 54 +++++++++++++++++++-
 4 files changed, 142 insertions(+), 1 deletion(-)
---
base-commit: cc13002a9f984d37906e9476f3e532a8cdd126f5
change-id: 20251118-oneplus-nfc-c00ef1cdfa9b

Best regards,
-- 
David Heidelberg <david@ixit.cz>

