From: Andrew Gigena <mail@andrewgigena.dev>
Subject: [PATCH v3 0/3] arm64: dts: qcom: sm8150: Add standalone ICE node
 for UFS
Date: Wed, 11 Nov 2026 04:17:48 +0000
Message-Id: <20261111-sm8150-ice-rfc-v3-0-f9d5a806fc95@andrewgigena.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33NzQ7CIBAE4FcxnMUs9IfqyfcwHsqybTGRGqioa
 fruQr2qx0lmvplZIG8psMNmZp6iDXZ0KRTbDcOhdT1xa1JmEmQtBJQ8XBtRAbdI3HfIQZdaIhQ
 VNcDS6Oaps88VPJ0/Odz1hXDKSm4MNkyjf62PUeTeTzwKDrxShdI1SkKEY+uMp0dve3LtzlBk+
 SPK/4pMiqn3SmskkKr5oizL8gZT9hPeCwEAAA==
X-Change-ID: 20261104-sm8150-ice-rfc-0b4b2c035e80
To: Abel Vesa <abelvesa@kernel.org>, 
 Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>, Bart Van Assche <bvanassche@acm.org>, 
 Bean Huo <beanhuo@micron.com>, Stanley Jhu <stanleyjhu@google.com>, 
 Bjorn Andersson <andersson@kernel.org>, Andy Gross <agross@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-crypto@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-scsi@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794370671; l=1616;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=NHGynmgOiipnILRN3zymO9/V/g0czzvFXIX8dUVTA7I=;
 b=EobBK5mlbAGMRTZuxz4hOl8C39fcDlZ4QOSoLYV0HNQre/Zg1i9DwCqxNZ5pjw0hp5SqaGOeC
 9OWrgWkOK7tBbpHuOXLqPlQLLuYUMG3ZS5NFUZ56ouzykTgCnAYUWm+
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi everyone,

This series adds standalone ICE support to SM8150 (Snapdragon 855),
matching newer Qualcomm platforms.

Patch 1 documents the sm8150 ICE compatible.
Patch 2 moves sm8150-ufshc to the standalone-ICE UFS binding.
Patch 3 converts the UFS node to use a dedicated ICE node.

Tested on a Google Pixel 4 (google-flame): AES-256-XTS advertised,
ext4 encryption supported, ICE self-test passes.

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>

Changes in v3:
- Split bindings into two commits (compatible + standalone-ICE move).
- Drop author Tested-by from DTS patch.
- Link to v2: https://patch.msgid.link/20261104-sm8150-ice-rfc-v2-0-d697bbce0278@andrewgigena.dev

Changes in v2:
- Move sm8150-ufshc to the standalone-ICE binding.
- Keep the ICE compatible sorted.
- Link to v1: https://patch.msgid.link/20261104-sm8150-ice-rfc-v1-0-5737b6c2ecc0@andrewgigena.dev

---
Andrew Gigena (3):
      dt-bindings: crypto: ice: document sm8150 compatible
      dt-bindings: ufs: qcom: classify sm8150-ufshc as standalone ICE
      arm64: dts: qcom: sm8150: use standalone ICE for UFS

 .../bindings/crypto/qcom,inline-crypto-engine.yaml |  1 +
 .../devicetree/bindings/ufs/qcom,sc7180-ufshc.yaml |  2 ++
 .../devicetree/bindings/ufs/qcom,ufs.yaml          | 11 ++++------
 arch/arm64/boot/dts/qcom/sm8150.dtsi               | 25 ++++++++++++++--------
 4 files changed, 23 insertions(+), 16 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-sm8150-ice-rfc-0b4b2c035e80

Best regards,
--  
Andrew Gigena <mail@andrewgigena.dev>

