From: Ishu Brar <patches@brar.si>
Subject: [PATCH 0/2] remoteproc: qcom: pas: Add SM7250 ADSP
Date: Fri, 16 Oct 2026 13:50:17 +0530
Message-Id: <20261016-adsp-sm7250-v1-0-2f39ac1f0496@brar.si>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDVpG0VcRSxaHYzETzqIRNxds
 fwW713AGAgZquSCgAcxLXOEShNoBzv3KMhHg5Y6V1IZYT2vgqdCGym8NaV3CrPC5hCLNWBH53e
 rm9+8uxHb7V3AfT84ty7EbwAAAA==
X-Change-ID: 20261015-adsp-sm7250-da58db1e47a6
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ishu Brar <patches@brar.si>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792138822; l=1174;
 i=patches@brar.si; h=from:subject:message-id;
 bh=OycpV4nk9Zu8OEnUs2uDOj58onhx7mT2B64LT+6j/A4=;
 b=+XwPKvXqDGjvYO9PAkCpfjbMxoc9vsdz8wDImDIYjWrsez0thPFaJyF5xrvQNOT57+N/kfj4M
 JzRuSXdCT12B4qjByU1KOcEBuUpZ1FgHUjmUrfQavv0i1mQ1ljI8j+g
X-Developer-Key: i=patches@brar.si; a=ed25519;
 pk=Ds+E23E3ntzjPzuBDyVRkOouclcNI5k75R+N42yJtCk=
X-Endpoint-Received: by B4 Relay for patches@brar.si/default with auth_id=1189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding ADSP remoteproc for Qualcomm SM7250 (Snapdragon
765/765G/768G).

The SM7250 ADSP behaves like the SM6350 one: same PAS ID, same
interrupts, same LCX/LMX power domains, same SMEM crash reason item.
So no new resource struct is needed. Patch 1 documents the compatible in
the existing SM6350 PAS binding. Patch 2 adds it to the driver, using
the SM6350 ADSP resource.

I am bringing up mainline on a OnePlus Nord (SM7250, "avicii"). With
this series the ADSP boots on that phone and I can play audio through it
and read the sensors from it.

The SoC devicetree is not part of this series; it is being sent
separately.

Signed-off-by: Ishu Brar <patches@brar.si>
---
Ishu Brar (2):
      dt-bindings: remoteproc: qcom,sm6350-pas: Document SM7250 ADSP
      remoteproc: qcom: pas: Add SM7250 ADSP support

 Documentation/devicetree/bindings/remoteproc/qcom,sm6350-pas.yaml | 3 +++
 drivers/remoteproc/qcom_q6v5_pas.c                                | 1 +
 2 files changed, 4 insertions(+)
---
base-commit: 23d0516587f896f5f16a47c97ddb41d28e6289ff
change-id: 20261015-adsp-sm7250-da58db1e47a6

Best regards,
--  
Ishu Brar <patches@brar.si>

