From: EMCP333 <emcp@enser.io>
Subject: [PATCH 0/3] media: qcom: camss: Interconnect votes for SDM845
Date: Sun, 22 Nov 2026 05:13:23 +0000
Message-Id: <20261122-b4-camss-sdm845-icc-v1-0-0671ef770fd0@enser.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPN5AmsC/yXMwQ6CMBAE0F8he3bV1irEXzEc2u0qa0IlXSUkh
 H+31eObzMwKyllY4dqskHkWlVcqMLsGaPDpwSixGOzRXoyxFoND8qMqahw7d0YhQhMdxY5OTKa
 Fspwy32X5vd76v/UTnkzvelUbwStjyD7RUKPKw9zuHWaysG1f+uk2bZcAAAA=
X-Change-ID: 20261122-b4-camss-sdm845-icc-1d4cd8c3ec17
To: Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>
Cc: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324405; l=1830;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=0eKhIZ+ChtKI73qyKB4ZI4olHiQz7Q9wrSL2FmVT5UU=;
 b=/jIJzyp9G4JmqAhPZ393/BkZFtZPUci/21USxarhIHV2aEb6kzwHmXVbg00OrikYxV7dz66z1
 J83cxfN9EFyAwqbrmz/kcDcguCUvsJlSZWfb678acfiVWdgKqWzV/qv
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CAMSS on SDM845 declares no interconnect paths, so it never votes for
memory bandwidth and runs on whatever the display happens to hold. With
the display off, capture stalls: on a OnePlus 6T, 8 of 10 1080p
captures stopped after 0-1 frames, against 10 of 10 complete with the
display on.

Patch 1 allows the four paths in the binding, patch 2 gives the driver
a bandwidth table for SDM845, and patch 3 adds the paths to sdm845.dtsi.

Patches 1 and 2 are for the media tree and patch 3 for the Qualcomm
tree. The driver gets a NULL path, and so no votes, from a device tree
without the paths, so patch 2 is safe on its own; patch 3 needs patch
1 for dtbs_check.

Tested on the phone with the postmarketOS sdm845 kernel (6.18): with
the display off, 10 of 10 1080p captures of 100 frames complete, and
the camnoc HF ports vote while streaming and not when idle. On
v7.4-rc2, dt_binding_check and dtbs_check are clean and camss builds
with W=1 and no warnings.

The same three commits also ran on v7.4-rc3: with the display off, 10
of 10 captures of 100 frames, no camss errors, and the camss bandwidth
requests go from zero to non-zero while streaming and back to zero
after.

---
EMCP333 (3):
      dt-bindings: media: qcom,sdm845-camss: Add interconnects
      media: qcom: camss: Vote interconnect bandwidth on SDM845
      arm64: dts: qcom: sdm845: Add CAMSS interconnects

 .../bindings/media/qcom,sdm845-camss.yaml          | 20 +++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845.dtsi               | 10 +++++++++
 drivers/media/platform/qcom/camss/camss.c          | 26 ++++++++++++++++++++++
 3 files changed, 56 insertions(+)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-camss-sdm845-icc-1d4cd8c3ec17

Best regards,
--  
EMCP333 <emcp@enser.io>

