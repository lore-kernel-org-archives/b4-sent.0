From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Wed, 11 Nov 2026 11:11:01 +0100
Subject: [PATCH 6/6] ARM: tegra: Add EMC channel registers on Tegra114
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-upstream-emc-t114-v1-6-54d9e1bceb6a@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794391862; l=937;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=T59sEe/f17u37JLlvAN3pI/wxW5PHR4RdVn2Jyt/Ljk=;
 b=4smoglDsXKDNvXsQ2jiYAlIYolcSJZmo8yABt6+cC9hXJz4IJwIgUZKUOmq+54NcT1p4IutRi
 WmznIROMpvsArDTaPtH46uaxf+peeJojMUQ4TaOKUa6fN0YQlCFxU3V
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe the EMC0 and EMC1 register blocks next to the broadcast
registers, so that the EMC driver can program the pad auto-calibration
of each channel.

Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 arch/arm/boot/dts/nvidia/tegra114.dtsi | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/arm/boot/dts/nvidia/tegra114.dtsi b/arch/arm/boot/dts/nvidia/tegra114.dtsi
index a5958f3a965b..cf3d98274b36 100644
--- a/arch/arm/boot/dts/nvidia/tegra114.dtsi
+++ b/arch/arm/boot/dts/nvidia/tegra114.dtsi
@@ -804,7 +804,8 @@ mc: memory-controller@70019000 {
 
 	emc: external-memory-controller@7001b000 {
 		compatible = "nvidia,tegra114-emc";
-		reg = <0x7001b000 0x800>;
+		reg = <0x7001b000 0x800>, <0x7001a000 0x800>,
+		      <0x7001a800 0x800>;
 		interrupts = <GIC_SPI 78 IRQ_TYPE_LEVEL_HIGH>;
 		clocks = <&tegra_car TEGRA114_CLK_EMC>;
 		clock-names = "emc";

-- 
2.56.0

