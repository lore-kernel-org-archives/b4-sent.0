From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:16 +0400
Subject: [PATCH ath-next 10/16] dt-bindings: net: wireless: ath11k: Add
 bindings for QCN6122
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-10-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=9542;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=AMmUM3ppUAEMYWiKIHUzMgENqvh58tpVmet+RfpQRGA=;
 b=KddqHTm2dhPWaE2pvLI3lphALP/XjHvwb66YiQi0ATFRsAwBVw1o7rW8eU8f7RMsko7i5Qy4G
 VPH400sOf2dBPijM66rmtkG3yrwzaGbdnlvpuaVMpkxXkPSWR3QMIsr
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add bindings for QCN6122, which is a companion chip to IPQ5018. The
QCN6122 is a 5G/6G WiFi chip that is used in conjunction with the
IPQ5018 SoC in a multi-PD (MPD) configuration.

WiFi on IPQ5018 boards come in one of the following configurations:
1. IPQ5018 (standalone) + optional 5G/6G WiFi card (such as QCN9074)
2. IPQ5018 (MPD) + one or two 5G/6G QCN6122 WiFi chips.

IPQ5018 implements the multi-PD architecture as follows:

                     +-----------------------------+
                     |     Q6 Remote Processor     |
                     |            RootPD           |
                     +--------------+--------------+
                                    |
                                    |
                                    |
              +---------------------+---------------------+
              |                     |                     |
        +-----v-----+         +-----v-----+         +-----v-----+
        |  UserPD1  |         |  UserPD2  |         |  UserPD3  |
        |  IPQ5018  |         | QCN6122 #1|         | QCN6122 #2|
        |  (Radio)  |         |  (Radio)  |         |  (Radio)  |
        +-----------+         +-----------+         +-----------+

The rootPD is responsible for managing the lifecycle of the UserPD and
shared resources and providing SSR notifiers. There are different
firmware blobs that include either the rootPD and userPD binaries for
IPQ5018-only which auto-spawns the userPD for IPQ5018 WiFi, or for
IPQ5018 and QCN6122 for which the userPDs for each radio must be spawned
by the ath11k driver.

SMP2P is used for signaling between the host and the Q6 remote processor
to manage the lifecycle of the userPDs, so add the required interrupts
and smem-states for incoming and outgoing interrupts in the case of the
IPQ5018 + QCN6122 MPD configuration. Otherwise, the SMP2P interrupts and
smem-states are not required for the IPQ5018-only configuration.

In addition, document the memory regions needed for loading the BDF and
M3 firmware as well as for assigning the M3 dump memory block.

It's worth noting that QCN6122 does not have its own Q6 firmware blobs.
Instead, the firmware segments for QCN6122 are included in the IPQ5018
MPD firmware blob(s). In addition, the QCN6122 M3 firmware which does
come separately is loaded into the Q6 memory carveout of IPQ5018, hence
the need for a dedicated "m3-region" reserved memory region.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../bindings/net/wireless/qcom,ath11k.yaml         | 144 ++++++++++++++++++++-
 1 file changed, 142 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
index 621ad6d4ddad..10102b5ea8c8 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
@@ -20,6 +20,7 @@ properties:
       - qcom,ipq5018-wifi
       - qcom,ipq6018-wifi
       - qcom,ipq8074-wifi
+      - qcom,qcn6122-wifi
       - qcom,wcn6750-wifi
 
   reg:
@@ -30,11 +31,11 @@ properties:
     maxItems: 52
 
   interrupts-extended:
-    minItems: 56
+    minItems: 17
     maxItems: 56
 
   interrupt-names:
-    minItems: 32
+    minItems: 17
     maxItems: 56
 
   qcom,rproc:
@@ -459,6 +460,93 @@ allOf:
       required:
         - interrupt-names
 
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,qcn6122-wifi
+    then:
+      properties:
+        interrupts-extended:
+          items:
+            - description: interrupt event for ring CE1
+            - description: interrupt event for ring CE2
+            - description: interrupt event for ring CE3
+            - description: interrupt event for ring CE4
+            - description: interrupt event for ring CE5
+            - description: interrupt event for ring DP1
+            - description: interrupt event for ring DP2
+            - description: interrupt event for ring DP3
+            - description: interrupt event for ring DP4
+            - description: interrupt event for ring DP5
+            - description: interrupt event for ring DP6
+            - description: interrupt event for ring DP7
+            - description: interrupt event for ring DP8
+            - description: Q6 firmware user PD fatal interrupt event
+            - description: Q6 firmware user PD ready interrupt event
+            - description: Q6 firmware user PD spawn interrupt event
+            - description: Q6 firmware user PD stop ack interrupt event
+        interrupt-names:
+          minItems: 17
+          items:
+            - const: ce1
+            - const: ce2
+            - const: ce3
+            - const: ce4
+            - const: ce5
+            - const: dp1
+            - const: dp2
+            - const: dp3
+            - const: dp4
+            - const: dp5
+            - const: dp6
+            - const: dp7
+            - const: dp8
+            - const: fatal
+            - const: ready
+            - const: spawn
+            - const: stop-ack
+        memory-region:
+          minItems: 1
+          items:
+            - description: memory region for Q6 firmware
+            - description: memory region for M3 firmware
+            - description: memory region for M3 dump
+        memory-region-names:
+          minItems: 1
+          items:
+            - const: q6-region
+            - const: m3-region
+            - const: m3-dump
+        qcom,smem-states:
+          items:
+            - description: Signal bit used to shutdown Q6 user PD
+              items:
+                - description: Phandle to the Shared Memory Point 2 Point device
+                - description: Single bit index to toggle in the value sent to the remote processor
+                  maximum: 32
+            - description: Signal bit used to stop Q6 user PD
+              items:
+                - description: Phandle to the Shared Memory Point 2 Point device
+                - description: Single bit index to toggle in the value sent to the remote processor
+                  maximum: 32
+            - description: Signal bit used to spawn Q6 user PD
+              items:
+                - description: Phandle to the Shared Memory Point 2 Point device
+                - description: Single bit index to toggle in the value sent to the remote processor
+                  maximum: 32
+        qcom,smem-state-names:
+          items:
+            - const: shutdown
+            - const: stop
+            - const: spawn
+      required:
+        - interrupts-extended
+        - interrupt-names
+        - qcom,smem-states
+        - qcom,smem-state-names
+
   - if:
       properties:
         compatible:
@@ -861,3 +949,55 @@ examples:
 
         qcom,rproc = <&q6v5_wcss>;
     };
+
+    wifi1: wifi@b00a040 {
+        reg = <0x0b00a040 0x0>;
+        compatible = "qcom,qcn6122-wifi";
+
+        interrupts-extended = <&intc GIC_SPI 416 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 417 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 418 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 419 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 420 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 421 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 422 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 423 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 424 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 425 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 426 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 427 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 428 IRQ_TYPE_EDGE_RISING>,
+                              <&wcss_smp2p_in 16 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 17 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 20 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 19 IRQ_TYPE_NONE>;
+        interrupt-names = "ce1",
+                          "ce2",
+                          "ce3",
+                          "ce4",
+                          "ce5",
+                          "dp1",
+                          "dp2",
+                          "dp3",
+                          "dp4",
+                          "dp5",
+                          "dp6",
+                          "dp7",
+                          "dp8",
+                          "fatal",
+                          "ready",
+                          "spawn",
+                          "stop-ack";
+
+        qcom,smem-states = <&wcss_smp2p_out 16>,
+                           <&wcss_smp2p_out 17>,
+                           <&wcss_smp2p_out 18>;
+        qcom,smem-state-names = "shutdown",
+                                "stop",
+                                "spawn";
+
+        memory-region = <&q6_region_qcn6122_1>, <&q6_region_ipq5018>, <&m3_dump_qcn6122_1>;
+        memory-region-names = "q6-region", "m3-region", "m3-dump";
+
+        status = "disabled";
+    };

-- 
2.53.0

