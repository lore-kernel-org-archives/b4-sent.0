From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/2] SM8450 QoL changes (dts)
Date: Sat, 11 Jul 2026 23:12:26 -0400
Message-Id: <20260711-sm8450-qol-dts-v2-0-5eb2e86468c5@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02Nyw6CMBBFf4XM2jFtESis/A/DAuggNUKxU4mG8
 O/y2Lg8ybnnzsDkLTEU0QyeJsvWDSuoUwRNVw13QmtWBiVUKjIpkXt9SQS+3BNNYNR5nFRpnSd
 aZLCORk+t/ezBW3kwv+sHNWGrbEZnOTj/3R8nuXlHPFXqPz5JFBhnpIi0aXNTXUfvghvOPUG5L
 MsPOvRxHboAAAA=
X-Change-ID: 20260711-sm8450-qol-dts-8935a6b95807
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783825961; l=861;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=NH/8HgVWQ4D5/65p5rKmhBa0mt3P4wWICYWvIbf6n9A=;
 b=Fs+4F+B99IB18w/SxUmpLUkDUw6GNdE7FGLU93COwPWF5+MIDi1oBj63322RPohbuDddO626J
 RW2imcYr+KfDc4a7qXa3oV9jLR7/WOYV2tyl77ecVv9wQt7mANPnM47
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches focus on correcting some details on the DTS for the SM8450
SoC.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Split series in subseries (dispcc, dts, qmp, smmu)
- Add mode-switch patch
- Drop applied patches
- Drop GPU operating points patch (existing map seems to be OK)
- Link to v1: https://patch.msgid.link/20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me

---
Esteban Urrutia (2):
      arm64: dts: qcom: sm8450: Remove unneeded reserved memory nodes
      arm64: dts: qcom: sm8450: Add mode-switch property to qmpphy

 arch/arm64/boot/dts/qcom/sm8450.dtsi | 16 +---------------
 1 file changed, 1 insertion(+), 15 deletions(-)
---
base-commit: 96615101b3caf73612f80a217abb9a0da0effbc7
change-id: 20260711-sm8450-qol-dts-8935a6b95807

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

