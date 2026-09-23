From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:08 +0400
Subject: [PATCH ath-next 02/16] dt-bindings: net: wireless: ath11k: Add
 bindings for IPQ5018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-2-86729521a75c@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=26029;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=dwazGgTGl3nBGZ/RveaF17QPykvP/UUXWu672qGRCJw=;
 b=4m5wHIpLginPQMIjSmLLu4rIwxDrFAMW0hymXr3zs3QfzxeQuZTNMwur2kducDS+pPbHFJCGm
 4XSm9IPeymmDvtqYAnV1WPTsl5YztsaUSPzLQX8QR41IE3zW6yH9IMc
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Although support was added for IPQ5018, the bindings are missing, so
let's add them.

WiFi on IPQ5018 boards come in one of the following configurations:
1. IPQ5018 (standalone) + optional 5G/6G WiFi card (such as QCN9074)
2. IPQ5018 (MPD) + one or two 5G/6G QCN6122 WiFi chips where QCN6122
   is an IPQ5018-specific companion chip.

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

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 .../bindings/net/wireless/qcom,ath11k.yaml         | 423 ++++++++++++++++++++-
 1 file changed, 410 insertions(+), 13 deletions(-)

diff --git a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
index a846cd704b19..621ad6d4ddad 100644
--- a/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
+++ b/Documentation/devicetree/bindings/net/wireless/qcom,ath11k.yaml
@@ -29,8 +29,13 @@ properties:
     minItems: 32
     maxItems: 52
 
+  interrupts-extended:
+    minItems: 56
+    maxItems: 56
+
   interrupt-names:
-    maxItems: 52
+    minItems: 32
+    maxItems: 56
 
   qcom,rproc:
     $ref: /schemas/types.yaml#/definitions/phandle
@@ -56,11 +61,15 @@ properties:
 
   memory-region:
     minItems: 1
-    maxItems: 2
+    maxItems: 3
     description:
       phandle to a node describing reserved memory (System RAM memory)
       used by ath11k firmware (see bindings/reserved-memory/reserved-memory.txt)
 
+  memory-region-names:
+    minItems: 1
+    maxItems: 3
+
   iommus:
     minItems: 1
     maxItems: 2
@@ -78,20 +87,11 @@ properties:
   qcom,smem-states:
     $ref: /schemas/types.yaml#/definitions/phandle-array
     description: State bits used by the AP to signal the WLAN Q6.
-    items:
-      - description: Signal bits used to enable/disable low power mode
-          on WCN6750 in the case of WoW (Wake on Wireless).
-        items:
-          - description: Phandle to the Shared Memory Point 2 Point device
-              handling the communication with a remote processor
-          - description: Single bit index to toggle in the value sent to
-              the remote processor
-            maximum: 32
+    minItems: 1
+    maxItems: 3
 
   qcom,smem-state-names:
     description: The names of the state bits used for SMP2P output.
-    items:
-      - const: wlan-smp2p-out
 
 required:
   - compatible
@@ -103,6 +103,242 @@ additionalProperties: false
 
 allOf:
   - $ref: ieee80211.yaml#
+  - if:
+      properties:
+        compatible:
+          contains:
+            enum:
+              - qcom,ipq5018-wifi
+    then:
+      properties:
+        interrupts:
+          items:
+            - description: misc-pulse1 interrupt events
+            - description: misc-latch interrupt events
+            - description: sw exception interrupt events
+            - description: watchdog interrupt events
+            - description: interrupt event for ring CE0
+            - description: interrupt event for ring CE1
+            - description: interrupt event for ring CE2
+            - description: interrupt event for ring CE3
+            - description: interrupt event for ring CE4
+            - description: interrupt event for ring CE5
+            - description: interrupt event for ring CE6
+            - description: interrupt event for ring CE7
+            - description: interrupt event for ring CE8
+            - description: interrupt event for ring CE9
+            - description: interrupt event for ring CE10
+            - description: interrupt event for ring CE11
+            - description: interrupt event for ring host2wbm-desc-feed
+            - description: interrupt event for ring host2reo-re-injection
+            - description: interrupt event for ring host2reo-command
+            - description: interrupt event for ring host2rxdma-monitor-ring3
+            - description: interrupt event for ring host2rxdma-monitor-ring2
+            - description: interrupt event for ring host2rxdma-monitor-ring1
+            - description: interrupt event for ring reo2ost-exception
+            - description: interrupt event for ring wbm2host-rx-release
+            - description: interrupt event for ring reo2host-status
+            - description: interrupt event for ring reo2host-destination-ring4
+            - description: interrupt event for ring reo2host-destination-ring3
+            - description: interrupt event for ring reo2host-destination-ring2
+            - description: interrupt event for ring reo2host-destination-ring1
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac3
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac2
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac1
+            - description: interrupt event for ring ppdu-end-interrupts-mac3
+            - description: interrupt event for ring ppdu-end-interrupts-mac2
+            - description: interrupt event for ring ppdu-end-interrupts-mac1
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac3
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac2
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac1
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac3
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac2
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac1
+            - description: interrupt event for ring rxdma2host-destination-ring-mac3
+            - description: interrupt event for ring rxdma2host-destination-ring-mac2
+            - description: interrupt event for ring rxdma2host-destination-ring-mac1
+            - description: interrupt event for ring host2tcl-input-ring4
+            - description: interrupt event for ring host2tcl-input-ring3
+            - description: interrupt event for ring host2tcl-input-ring2
+            - description: interrupt event for ring host2tcl-input-ring1
+            - description: interrupt event for ring wbm2host-tx-completions-ring3
+            - description: interrupt event for ring wbm2host-tx-completions-ring2
+            - description: interrupt event for ring wbm2host-tx-completions-ring1
+            - description: interrupt event for ring tcl2host-status-ring
+        interrupts-extended:
+          items:
+            - description: misc-pulse1 interrupt events
+            - description: misc-latch interrupt events
+            - description: sw exception interrupt events
+            - description: watchdog interrupt events
+            - description: interrupt event for ring CE0
+            - description: interrupt event for ring CE1
+            - description: interrupt event for ring CE2
+            - description: interrupt event for ring CE3
+            - description: interrupt event for ring CE4
+            - description: interrupt event for ring CE5
+            - description: interrupt event for ring CE6
+            - description: interrupt event for ring CE7
+            - description: interrupt event for ring CE8
+            - description: interrupt event for ring CE9
+            - description: interrupt event for ring CE10
+            - description: interrupt event for ring CE11
+            - description: interrupt event for ring host2wbm-desc-feed
+            - description: interrupt event for ring host2reo-re-injection
+            - description: interrupt event for ring host2reo-command
+            - description: interrupt event for ring host2rxdma-monitor-ring3
+            - description: interrupt event for ring host2rxdma-monitor-ring2
+            - description: interrupt event for ring host2rxdma-monitor-ring1
+            - description: interrupt event for ring reo2ost-exception
+            - description: interrupt event for ring wbm2host-rx-release
+            - description: interrupt event for ring reo2host-status
+            - description: interrupt event for ring reo2host-destination-ring4
+            - description: interrupt event for ring reo2host-destination-ring3
+            - description: interrupt event for ring reo2host-destination-ring2
+            - description: interrupt event for ring reo2host-destination-ring1
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac3
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac2
+            - description: interrupt event for ring rxdma2host-monitor-destination-mac1
+            - description: interrupt event for ring ppdu-end-interrupts-mac3
+            - description: interrupt event for ring ppdu-end-interrupts-mac2
+            - description: interrupt event for ring ppdu-end-interrupts-mac1
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac3
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac2
+            - description: interrupt event for ring rxdma2host-monitor-status-ring-mac1
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac3
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac2
+            - description: interrupt event for ring host2rxdma-host-buf-ring-mac1
+            - description: interrupt event for ring rxdma2host-destination-ring-mac3
+            - description: interrupt event for ring rxdma2host-destination-ring-mac2
+            - description: interrupt event for ring rxdma2host-destination-ring-mac1
+            - description: interrupt event for ring host2tcl-input-ring4
+            - description: interrupt event for ring host2tcl-input-ring3
+            - description: interrupt event for ring host2tcl-input-ring2
+            - description: interrupt event for ring host2tcl-input-ring1
+            - description: interrupt event for ring wbm2host-tx-completions-ring3
+            - description: interrupt event for ring wbm2host-tx-completions-ring2
+            - description: interrupt event for ring wbm2host-tx-completions-ring1
+            - description: interrupt event for ring tcl2host-status-ring
+            - description: Q6 firmware user PD fatal interrupt event
+            - description: Q6 firmware user PD ready interrupt event
+            - description: Q6 firmware user PD spawn interrupt event
+            - description: Q6 firmware user PD stop ack interrupt event
+        interrupt-names:
+          minItems: 52
+          items:
+            - const: misc-pulse1
+            - const: misc-latch
+            - const: sw-exception
+            - const: watchdog
+            - const: ce0
+            - const: ce1
+            - const: ce2
+            - const: ce3
+            - const: ce4
+            - const: ce5
+            - const: ce6
+            - const: ce7
+            - const: ce8
+            - const: ce9
+            - const: ce10
+            - const: ce11
+            - const: host2wbm-desc-feed
+            - const: host2reo-re-injection
+            - const: host2reo-command
+            - const: host2rxdma-monitor-ring3
+            - const: host2rxdma-monitor-ring2
+            - const: host2rxdma-monitor-ring1
+            - const: reo2ost-exception
+            - const: wbm2host-rx-release
+            - const: reo2host-status
+            - const: reo2host-destination-ring4
+            - const: reo2host-destination-ring3
+            - const: reo2host-destination-ring2
+            - const: reo2host-destination-ring1
+            - const: rxdma2host-monitor-destination-mac3
+            - const: rxdma2host-monitor-destination-mac2
+            - const: rxdma2host-monitor-destination-mac1
+            - const: ppdu-end-interrupts-mac3
+            - const: ppdu-end-interrupts-mac2
+            - const: ppdu-end-interrupts-mac1
+            - const: rxdma2host-monitor-status-ring-mac3
+            - const: rxdma2host-monitor-status-ring-mac2
+            - const: rxdma2host-monitor-status-ring-mac1
+            - const: host2rxdma-host-buf-ring-mac3
+            - const: host2rxdma-host-buf-ring-mac2
+            - const: host2rxdma-host-buf-ring-mac1
+            - const: rxdma2host-destination-ring-mac3
+            - const: rxdma2host-destination-ring-mac2
+            - const: rxdma2host-destination-ring-mac1
+            - const: host2tcl-input-ring4
+            - const: host2tcl-input-ring3
+            - const: host2tcl-input-ring2
+            - const: host2tcl-input-ring1
+            - const: wbm2host-tx-completions-ring3
+            - const: wbm2host-tx-completions-ring2
+            - const: wbm2host-tx-completions-ring1
+            - const: tcl2host-status-ring
+            - const: fatal
+            - const: ready
+            - const: spawn
+            - const: stop-ack
+        memory-region:
+          items:
+            - description: memory region for Q6 firmware
+            - description: memory region for M3 firmware
+            - description: memory region for M3 dump
+        memory-region-names:
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
+      allOf:
+        - anyOf:
+            - required:
+                - interrupts
+            - required:
+                - interrupts-extended
+        - if:
+            required:
+              - interrupts-extended
+          then:
+            properties:
+              interrupt-names:
+                minItems: 56
+            required:
+              - interrupts-extended
+              - memory-region
+              - memory-region-names
+              - qcom,smem-states
+              - qcom,smem-state-names
+          else:
+            properties:
+              interrupt-names:
+                minItems: 52
+                maxItems: 52
+
   - if:
       properties:
         compatible:
@@ -265,6 +501,19 @@ allOf:
             - description: interrupt event for ring DP20
             - description: interrupt event for ring DP21
             - description: interrupt event for ring DP22
+        qcom,smem-states:
+          items:
+            - description: Signal bits used to enable/disable low power mode
+                on WCN6750 in the case of WoW (Wake on Wireless).
+              items:
+                - description: Phandle to the Shared Memory Point 2 Point device
+                    handling the communication with a remote processor
+                - description: Single bit index to toggle in the value sent to
+                    the remote processor
+                  maximum: 32
+        qcom,smem-state-names:
+          items:
+            - const: wlan-smp2p-out
 
 examples:
   - |
@@ -464,3 +713,151 @@ examples:
             iommus = <&apps_smmu 0x1c02 0x1>;
         };
     };
+
+  - |
+    #include <dt-bindings/interrupt-controller/arm-gic.h>
+
+    reserved-memory {
+        #address-cells = <2>;
+        #size-cells = <2>;
+
+        q6_region: q6-region@4b000000 {
+            no-map;
+            reg = <0x0 0x4b000000 0x0 0x1400000>;
+        };
+
+        m3_dump: m3-dump@4d100000 {
+            reg = <0x0 0x4d100000 0x0 0x100000>;
+            no-map;
+        };
+    };
+
+    wifi@c000000 {
+        compatible = "qcom,ipq5018-wifi";
+        reg = <0x0c000000 0x1000000>;
+
+        interrupts-extended = <&intc GIC_SPI 288 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 289 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 290 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 291 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 292 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 293 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 294 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 295 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 296 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 297 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 298 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 299 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 300 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 301 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 302 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 303 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 304 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 305 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 306 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 307 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 308 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 309 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 310 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 311 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 334 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 313 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 314 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 315 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 316 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 317 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 318 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 319 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 320 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 321 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 322 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 323 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 324 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 325 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 326 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 327 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 328 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 329 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 330 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 331 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 332 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 333 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 312 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 335 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 336 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 337 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 338 IRQ_TYPE_EDGE_RISING>,
+                              <&intc GIC_SPI 339 IRQ_TYPE_EDGE_RISING>,
+                              <&wcss_smp2p_in 8 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 9 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 12 IRQ_TYPE_NONE>,
+                              <&wcss_smp2p_in 11 IRQ_TYPE_NONE>;
+        interrupt-names = "misc-pulse1",
+                          "misc-latch",
+                          "sw-exception",
+                          "watchdog",
+                          "ce0",
+                          "ce1",
+                          "ce2",
+                          "ce3",
+                          "ce4",
+                          "ce5",
+                          "ce6",
+                          "ce7",
+                          "ce8",
+                          "ce9",
+                          "ce10",
+                          "ce11",
+                          "host2wbm-desc-feed",
+                          "host2reo-re-injection",
+                          "host2reo-command",
+                          "host2rxdma-monitor-ring3",
+                          "host2rxdma-monitor-ring2",
+                          "host2rxdma-monitor-ring1",
+                          "reo2ost-exception",
+                          "wbm2host-rx-release",
+                          "reo2host-status",
+                          "reo2host-destination-ring4",
+                          "reo2host-destination-ring3",
+                          "reo2host-destination-ring2",
+                          "reo2host-destination-ring1",
+                          "rxdma2host-monitor-destination-mac3",
+                          "rxdma2host-monitor-destination-mac2",
+                          "rxdma2host-monitor-destination-mac1",
+                          "ppdu-end-interrupts-mac3",
+                          "ppdu-end-interrupts-mac2",
+                          "ppdu-end-interrupts-mac1",
+                          "rxdma2host-monitor-status-ring-mac3",
+                          "rxdma2host-monitor-status-ring-mac2",
+                          "rxdma2host-monitor-status-ring-mac1",
+                          "host2rxdma-host-buf-ring-mac3",
+                          "host2rxdma-host-buf-ring-mac2",
+                          "host2rxdma-host-buf-ring-mac1",
+                          "rxdma2host-destination-ring-mac3",
+                          "rxdma2host-destination-ring-mac2",
+                          "rxdma2host-destination-ring-mac1",
+                          "host2tcl-input-ring4",
+                          "host2tcl-input-ring3",
+                          "host2tcl-input-ring2",
+                          "host2tcl-input-ring1",
+                          "wbm2host-tx-completions-ring3",
+                          "wbm2host-tx-completions-ring2",
+                          "wbm2host-tx-completions-ring1",
+                          "tcl2host-status-ring",
+                          "fatal",
+                          "ready",
+                          "spawn",
+                          "stop-ack";
+
+        qcom,smem-states = <&wcss_smp2p_out 8>,
+                           <&wcss_smp2p_out 9>,
+                           <&wcss_smp2p_out 10>;
+        qcom,smem-state-names = "shutdown",
+                                "stop",
+                                "spawn";
+
+        memory-region = <&q6_region>, <&q6_region>, <&m3_dump>;
+        memory-region-names = "q6-region", "m3-region", "m3-dump";
+
+        qcom,rproc = <&q6v5_wcss>;
+    };

-- 
2.53.0

