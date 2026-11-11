From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:10:59 +0100
Subject: [PATCH 4/6] dt-bindings: memory: tegra: Add Tegra114 EMC channel
 registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-4-54d9e1bceb6a@tsv-stahl-riesa.de>
References: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
In-Reply-To: <20261111-upstream-emc-t114-v1-0-54d9e1bceb6a@tsv-stahl-riesa.de>
To: Krzysztof Kozlowski <krzk@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-tegra@vger.kernel.org, 
 Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=1977;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=tz+fHsI6+R+ZQDMJkf+fY1vAhYfa/ty8mFdbV8R9O0g=;
 b=YyxjzpRtK/HlZCwJv6QLcW/Wo8upl+4LXgotBpg0azVCxg+51zLtpZjvmnOEVU2V7FwtgvlRZ
 PiOkMSojs0gC9vSoknAY3WBjzEQ0FR7BQVk9toRl6GD1v0gdziWZamo
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Tegra114 EMC has two channels of 32 bits. Besides the register
block that writes to both channels, each channel has its own block,
EMC0 at 0x7001a000 and EMC1 at 0x7001a800 (Tegra 4 TRM address map).

Some settings have to differ between the channels: for pad
auto-calibration, channel 0 is the master and channel 1 is the slave
(EMC_AUTO_CAL_CONFIG bit 27, AUTO_CAL_SLAVE_MODE), which cannot be
programmed through the broadcast block. Allow the two channel blocks as
second and third reg entries for Tegra114: a device tree has either
only the broadcast block, as the existing ones do, or all three. The
meaning follows from the position, so no reg-names are needed. Tegra124
keeps a single entry.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 .../bindings/memory-controllers/nvidia,tegra124-emc.yaml      | 11 ++++++++++-
 1 file changed, 10 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra124-emc.yaml b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra124-emc.yaml
index 8e0c67d671f9..c9335483ba85 100644
--- a/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra124-emc.yaml
+++ b/Documentation/devicetree/bindings/memory-controllers/nvidia,tegra124-emc.yaml
@@ -25,7 +25,13 @@ properties:
           - const: nvidia,tegra124-emc
 
   reg:
-    maxItems: 1
+    oneOf:
+      - items:
+          - description: EMC registers, writes go to all channels
+      - items:
+          - description: EMC registers, writes go to all channels
+          - description: EMC channel 0 registers
+          - description: EMC channel 1 registers
 
   clocks:
     items:
@@ -218,6 +224,9 @@ allOf:
             enum:
               - nvidia,tegra124-emc
     then:
+      properties:
+        reg:
+          maxItems: 1
       patternProperties:
         "^emc-timings-[0-9]+$":
           patternProperties:

-- 
2.56.0

