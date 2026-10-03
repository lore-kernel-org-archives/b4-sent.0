From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH 0/4] power: supply: qcom_smbx: report charger state changes
Date: Sat, 03 Oct 2026 16:45:20 -0300
Message-Id: <20261003-qcom-smbx-chg-state-change-v1-0-fffaef446932@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y3MQQqDMBBA0avIrB2IphX1KtJFMh11CmqbSYsg3
 t20dfng8zdQDsIKbbZB4I+oLHNCkWdAo5sHRrknQ2nKqjDG4ouWCXXyK9I4oEYXGc/SXiw1vq7
 JXRnS4Bm4l/U3725/69s/mOL3CPt+AKYQKOZ+AAAA
X-Change-ID: 20261003-qcom-smbx-chg-state-change-343c9b88ca5e
To: Casey Connolly <casey.connolly@linaro.org>, 
 Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Robin Snyders <robin@snyders.xyz>, David Heidelberg <david@ixit.cz>, 
 phone-devel@vger.kernel.org, Richard Acayan <mailingradian@gmail.com>, 
 linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791056720; l=1384;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=69Be8OqRG4uKfxINxNYsSa/2mzLTbGi6UrvJIKEBERY=;
 b=j4P4kueOKJEBhvIsJc/2rxdyAGEI7E4Ka7+E9uKMI2OOnzqEgmhPotkz5rVxPbjcB40uVf+b4
 gxaUleMiQwsBqQTPFn2tRCu9M2WQkCb27yTqsiunx7X4HXDzle85/AD
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

qcom_smbx does not handle the charger's chg-state-change interrupt, so
a charge completing is not notified and consumers can keep a stale
status. Allow the interrupt in the binding, handle it in the driver,
and describe it for PM660 and PMI8998.

Tested on a Motorola Moto X4 (PM660) with the sdm660-mainline 7.2.3
tree: each charging-state change is notified and the battery status
follows. The PMI8998 patch is untested on hardware.

Robin Snyders' pending SMB5 series touches the same binding and
driver; whichever lands second needs a rebase.

---
Fabricio Akio (4):
      dt-bindings: power: supply: qcom,pmi8998-charger: add chg-state-change
      power: supply: qcom_smbx: report charger state changes
      arm64: dts: qcom: pm660: Add the charger state change interrupt
      arm64: dts: qcom: pmi8998: Add the charger state change interrupt

 .../power/supply/qcom,pmi8998-charger.yaml         |  5 ++++-
 arch/arm64/boot/dts/qcom/pm660.dtsi                |  9 ++++++--
 arch/arm64/boot/dts/qcom/pmi8998.dtsi              |  6 ++++--
 drivers/power/supply/qcom_smbx.c                   | 24 ++++++++++++++++++++++
 4 files changed, 39 insertions(+), 5 deletions(-)
---
base-commit: 9f24d789f03b22941b905ded43cb5ff8eea9ce62
change-id: 20261003-qcom-smbx-chg-state-change-343c9b88ca5e

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

