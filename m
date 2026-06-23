From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/8] SM8450 QoL changes
Date: Mon, 22 Jun 2026 20:54:21 -0400
Message-Id: <20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWphhJXEQutwYjfDiIRd1csv
 8V7FzA6QoY8uMDhQUzz5BGFAdiumloUVHuDkkpLrZTgMYsTKdZ5ELHWJrMyRZM04IPFYUPnNyv
 K37ybHu32HuC+HzkbH81uAAAA
X-Change-ID: 20260622-sm8450-qol-466b8c07eb5f
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782176157; l=1425;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=DgffpdNrpO4f30+mY00g4wrghfu/SZlNcAxvkajL6hQ=;
 b=gFLyTHxjNg2I3HnPktYj69R6MvSgxJuhGJ/tYw8SEqkz4RWr8vehEn4T+CkGytzjGdsyULS9v
 BgkbT9flofAAaFaldrhHGib+wDlo8bIoqvJYPnqZcKrJ3mdtsChDkI3
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello. This is my first attempt at contributing to the Linux kernel.

I've been mainlining an SM8475 based device for quite some time now and
I feel now's the proper time to start submitting patches.
I'm starting with the smallest part which are mostly modifications
regarding the current support for the SM8450 SoC.

Regards,
Esteban

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (8):
      clk: qcom: dispcc-sm8450: Fix mdss clocks
      arm64: dts: qcom: sm8450: Remove unneeded reserved memory nodes
      arm64: dts: qcom: sm8450: Modify GPU operating points
      arm64: dts: qcom: sm8450: Add missing PCM_OUT port
      iommu/arm-smmu-qcom: Add SM8450 MDSS compatible
      phy: qcom: qmp-combo: Drop qmp_v4_calibrate_dp_phy
      phy: qcom: qmp-combo: Correct pre-emphasis table for QMP v4 DP PHYs
      arm64: defconfig: Add SM8450 camcc

 arch/arm64/boot/dts/qcom/sm8450.dtsi       | 50 ++++++------------------------
 arch/arm64/configs/defconfig               |  1 +
 drivers/clk/qcom/dispcc-sm8450.c           |  6 ++--
 drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c |  1 +
 drivers/phy/qualcomm/phy-qcom-qmp-combo.c  | 33 +-------------------
 5 files changed, 16 insertions(+), 75 deletions(-)
---
base-commit: 948efecf22e49aa4bf55bb73ec79a0ddcfd38571
change-id: 20260622-sm8450-qol-466b8c07eb5f

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

