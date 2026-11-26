From: Fabricio Akio <fabricioakio@gmail.com>
Subject: [PATCH 0/2] SDM660 ADSP: vote the DSP's rail while it boots
Date: Wed, 25 Nov 2026 23:20:33 -0300
Message-Id: <20261125-sdm660-adsp-proxy-rail-v1-0-b91784c69623@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ6CMAyA4VchPduELVkRX8V4mKxojcLSosEQ3
 p2hx+/w/wsYq7DBqVpA+SMm41DgDhV09zjcGCUVg689OecDWnoR1RiTZcw6zl/UKE8M3ISmbY8
 9UYQSZ+Ve5t/4fPnb3tcHd9N+g3XdAJYvCo16AAAA
X-Change-ID: 20261125-sdm660-adsp-proxy-rail-5e757998f66a
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>, Martin Botka <martin.botka1@gmail.com>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795659634; l=2228;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=SC6vWKcK3HXEfRgQN0qt9mObuOdi9RmiKKXpA6CHRXg=;
 b=q36PbOxzt50UA6rVsCtatmP0aF4LvZpFqnEefswkoGom6OldgPv0RlFUG9gLdviBec8fVuwh9
 eG/lhlhGp0YBX4AxKiqTbowJ6QU2mBxwVv6eLrd0cblQkCFbCQJtzOs
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On SDM630 the ADSP starts once per boot. After a stop or a crash, the
next start times out waiting for the DSP:

  qcom_q6v5_pas 15700000.remoteproc: start timed out
  remoteproc remoteproc0: can't start rproc adsp: -110

The driver votes no power domain for this compatible while the DSP
boots, and sdm630.dtsi gives the node the SoC's CX. Downstream votes the
RPM's "rwlc" resource, PM660L LDO9, as the ADSP's supply while it boots,
on SDM630 and SDM660:
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm630.dtsi#L1737
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/sdm660.dtsi#L2008
https://github.com/LineageOS/android_kernel_motorola_msm8998/blob/ce9ea8f125c7302ae9b2fec84f23a69271e957c3/arch/arm/boot/dts/qcom/msm-pm660l-rpm-regulator.dtsi#L194

Patch 1 makes the driver vote the node's "cx" power domain until
handover, as it does for MSM8998. Patch 2 points that domain at
RPMPD_SSCCX, which is "rwlc". With either patch alone the start after a
stop still times out.

With patch 1 the driver does not probe a node without the power domain,
as for the other users of msm8996_adsp_resource. The binding does not
require the property; sdm630.dtsi has had it since the node was added.

Tested on a Motorola Moto X4 (SDM630), whose board file is not in
mainline yet, on sdm660-mainline's 7.2 kernel: the ADSP stopped and
started five times, and a fatal error and a watchdog timeout injected
into the DSP both recovered. The SDM636, SDM660 and SDA660 boards are
not tested.

Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
Fabricio Akio (2):
      remoteproc: qcom: pas: Vote the SDM660 ADSP's power domain while it boots
      arm64: dts: qcom: sdm630: Power the ADSP from the SSC CX rail

 arch/arm64/boot/dts/qcom/sdm630.dtsi | 2 +-
 drivers/remoteproc/qcom_q6v5_pas.c   | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261125-sdm660-adsp-proxy-rail-5e757998f66a

Best regards,
--  
Fabricio Akio <fabricioakio@gmail.com>

