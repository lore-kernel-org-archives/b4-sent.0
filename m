From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] interconnect: qcom: Add the Molokai interconnect
 providers
Date: Sat, 28 Nov 2026 00:35:52 +0530
Message-Id: <20261128-molokai-icc-v2-0-7806842d166b@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNyw6CMBBFf4XM2ppO5enK/zAsahlkVBjTIpEQ/
 l3AuHB5knPPnSCQZwpwjCbwNHBg6RYwuwhcY7srKa4WBqNNimgy1cpD7pYVO6fwgLF1lS6KJId
 l8fRU83urncsvh9flRq5fE6vRcOjFj9vdgKv3K+d/5QGVVjYhzJK41nlanUbbiOydtFDO8/wBS
 1UXvrgAAAA=
X-Change-ID: 20261127-molokai-icc-1314acd09958
To: Georgi Djakov <djakov@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Abel Vesa <abel.vesa@oss.qualcomm.com>, linux-arm-msm@vger.kernel.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795806352; l=3168;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=OLY8f5RTTQRtYbj7FHrGwVS/UNeuccZVvC2l7+O5rZo=;
 b=SOG3hH0S+ubC5Vw2XwK5K8aZedCtRBe7ctvfFALmoPiygSz23zInbTqpjpO9bpIWFnFGwqxzA
 2uF52Nlpc0EClItGhM1JU5vxxSEZMwCt6lBIUpryy+Rihz8JyzatJyC
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Molokai (SM8845) is derived from Kaanapali, but its NoCs are not the
same: the aggregate NoC is split into aggre1 and aggre2, the MMSS NoC
config and service ports are split into HF and SF halves, many QoS
ports moved, and QUP4, SDCC4, SP, QPACE and a few config slaves are
gone. This series adds the binding and a Molokai driver.

It replaces "interconnect: qcom: Don't read back BCMs without an RPMh
address" [1], where Konrad asked to fix the driver instead. Molokai used
the Kaanapali driver, which votes on the QPC0 BCM that the Molokai
command DB does not have; the read back of that BCM hung RPMh. The
Molokai driver has no QPC0, and it programs the Molokai QoS offsets
instead of the Kaanapali ones.

The topology and QoS settings come from the Molokai driver in
Motorola's downstream kernel. The upstream Kaanapali driver matches the
downstream Kaanapali one node for node, so the driver is the Kaanapali
one with the downstream Kaanapali to Molokai differences applied.

The binding header includes the Kaanapali one and only adds the new
MMSS nodes: molokai.dtsi builds on kaanapali.dtsi and inherits its
interconnect paths, and a header with its own numbering would redefine
the same macros with other values. If a standalone header is preferred,
molokai.dtsi would have to override every inherited interconnect path,
or stop building on kaanapali.dtsi; I can rework it that way.

Tested on the Motorola Signature with molokai.dtsi switched to these
providers (Molokai SoC series v5 [2]) and the generic
read back fix reverted: all 14 providers probe, there are no RPMh
timeouts, and the display, GPU, touchscreen and audio work with QoS
programming enabled.

[1] https://lore.kernel.org/all/20261123-icc-bcm-readback-v2-1-bacee81398e5@yahoo.com/
[2] https://lore.kernel.org/all/20261128-molokai-soc-v5-0-144801dfad7f@yahoo.com/

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

Signed-off-by: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
---
Changes in v2:
- Route the crypto engine through the A2NOC slave instead of A1NOC: it
  sits on aggre2, the downstream A1NOC link was left over from Kaanapali
  (Sashiko). Tested: the SCM crypto path now goes through
  qnm_aggre2_noc.
- Cover: point to v5 of the Molokai SoC series.
- Link to v1: https://patch.msgid.link/20261128-molokai-icc-v1-0-a5e1754f086d@yahoo.com

---
Venkat Yadlapati (2):
      dt-bindings: interconnect: qcom: Add Molokai RPMh NoC
      interconnect: qcom: Add Molokai interconnect provider driver

 .../bindings/interconnect/qcom,molokai-rpmh.yaml   |  144 ++
 drivers/interconnect/qcom/Kconfig                  |   11 +
 drivers/interconnect/qcom/Makefile                 |    2 +
 drivers/interconnect/qcom/molokai.c                | 1753 ++++++++++++++++++++
 .../dt-bindings/interconnect/qcom,molokai-rpmh.h   |   26 +
 5 files changed, 1936 insertions(+)
---
base-commit: e5aad2bdbbee783611d32599f89cea3f12f9593d
change-id: 20261127-molokai-icc-1314acd09958

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

