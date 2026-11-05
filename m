From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/5] SM8350 GPU: memory bandwidth vote and speed bins
Date: Thu, 05 Nov 2026 13:29:59 +0000
Message-Id: <20261105-b4-sm8350-gpu-v1-0-a7175cdd6512@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwNT3SQT3eJcC2NTA930glLd5ERLw+S0RMvERKM0JaCegqLUtMwKsHn
 RsRB+cWlSVmpyCcgQpdpaAMy1mwRxAAAA
X-Change-ID: 20261105-b4-sm8350-gpu-ca91cfa9aa2f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Sean Paul <sean@poorly.run>, 
 Akhil P Oommen <akhilpo@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 freedreno@lists.freedesktop.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793885419; l=1797;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=D8VZFoCVME1aMQHvCdWPw5lNShSOUsROxlYF0NZDL6M=;
 b=7AfKYelxwTvmG/00jufz4oiz8vWvG22SyGOJ9LXr+Wuy0s6v8uyCf5WgNVLURRlYq4RxTi+si
 N919nvXLo0wCqQSA2Hcht8v7eNmhmGAbCYXMRglaWSy3pilzS4CGbve
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two things are missing for the SM8350 GPU in mainline.

First, the GPU never votes for DDR bandwidth (patch 1). This fix stands
alone and can be taken on its own.

Second, the GPU speed bins are not read, so every part runs up to
840 MHz: parts validated only up to 738 MHz run above their rating, and
parts that support 900 MHz never get it (patches 2-5).

The frequencies, voltage levels and bandwidths all come from Qualcomm's
GPU tables for SM8350.

Patch 5 needs patch 3: without the keepout regions, reading the nvmem
file resets the SoC. Patch 4 alone changes nothing until patch 5 adds
the speed bin cell, and patch 5 without patch 4 keeps every part at
speed bin 0 (up to 840 MHz, as today).

The keepout regions in patch 3 were measured on one device (Razer Edge
5G), one 32-bit word at a time; the 0x128-0x147 one matches SC7180 and
SC7280. If Qualcomm has the documented ranges, I'm happy to use them
instead.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
Demeter Barna (5):
      arm64: dts: qcom: sm8350: Vote the GPU memory bandwidth
      dt-bindings: nvmem: qfprom: Add SM8350 compatible
      nvmem: qfprom: Add the SM8350 keepout regions
      drm/msm/adreno: Add speedbins for A660 GPU
      arm64: dts: qcom: sm8350: Add the GPU speed bins

 .../devicetree/bindings/nvmem/qcom,qfprom.yaml     |  1 +
 arch/arm64/boot/dts/qcom/sm8350.dtsi               | 47 +++++++++++++++++++++-
 drivers/gpu/drm/msm/adreno/a6xx_catalog.c          |  8 ++++
 drivers/nvmem/qfprom.c                             | 13 ++++++
 4 files changed, 68 insertions(+), 1 deletion(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261105-b4-sm8350-gpu-ca91cfa9aa2f

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

