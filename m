From: Andrew Gigena <mail@andrewgigena.dev>
Subject: [PATCH v2 0/2] arm64: dts: qcom: sm8150: Add standalone ICE node
 for UFS
Date: Wed, 04 Nov 2026 18:38:11 +0000
Message-Id: <20261104-sm8150-ice-rfc-v2-0-d697bbce0278@andrewgigena.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6CMBBFf4XM2pppecaV/2FY0GGAMbGQFquG8
 O8Crl2e5NxzFwjshQNckgU8Rwkyug3MKQEaGtezknZjMGgKrTFT4VHpHJUQK9+RQptZQ5jmXCF
 so8lzJ+8jeKt/HJ72zjTvld0YJMyj/xyPUe/e33jUClVepqUtyDARXhvXen710rNrzi1HqNd1/
 QKM9s3yxQAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793817503; l=1778;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=EYYDw/tfOLuPl22DSLCCU8f7CgFbqXXJ5pXhEipb5G4=;
 b=kp8or87NIVZSizcmjfJxMsBDmwAMDFADyUHX9ZpCifKsu+M7gWCsUUg5i0rRWaJA7hvSsYkTO
 z3gr7fGK/u5B0+6JLErzPTeCyQeCPRJ4PtjayE0fw+pZ4f5Cl1xrNX2
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi everyone,

This small series brings the Qualcomm Inline Crypto Engine (ICE) to the
SM8150 (Snapdragon 855) platform, following the same standalone-node style
already used on SM8250 and newer SoCs.

The first patch documents the new qcom,sm8150-inline-crypto-engine
compatible and moves qcom,sm8150-ufshc to the standalone-ICE UFS binding.
The second patch converts the UFS node to reference a dedicated ICE node
instead of embedding the registers directly.

I've tested this on a Google Pixel 4 (google-flame) and everything works:
/sys/block/sda/queue/crypto now advertises AES-256-XTS and ext4 reports
encryption as "supported". The ICE self-test completes cleanly during boot.

Happy to adjust anything or add more details if needed. Thanks for reviewing!

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>

Changes in v2:
- Move qcom,sm8150-ufshc from the legacy embedded-ICE UFS binding to
  the standalone-ICE UFS binding.
- Keep the SM8150 ICE compatible sorted in the existing list.
- Link to v1: https://patch.msgid.link/20261104-sm8150-ice-rfc-v1-0-5737b6c2ecc0@andrewgigena.dev

---
Andrew Gigena (2):
      dt-bindings: crypto: ice: Document sm8150 inline crypto engine
      arm64: dts: qcom: sm8150: Use standalone ICE node for UFS

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

