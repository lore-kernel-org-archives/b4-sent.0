From: Myria Sarvay <myrialsarvay@gmail.com>
Subject: [PATCH v2 00/15] drivers/perf: apple_m1: Add M3/M4/A18 Pro Support
Date: Sat, 07 Nov 2026 21:48:47 +1100
Message-Id: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22OwW6DMBBEfwXtOUtsIGng1P+IcjBmE7bC4HoNS
 hXx7zWkxx5HmnnzXiAUmASa7AWBFhaexhSKQwa2N+ODkLuUoVDFWdVFja5EP8yC3s1IC41RkCq
 llWmrSpcnSEMf6M7PHXq9vbPM7RfZuJH+GoG+5/QW3zVojRDayTmOTWbE9Hw03g+EMtljF/EjP
 8HG6lniFH5230Xv001Na1X+p7ZoVGgu1J6t1mV9p8+HMzzk6Qlu67r+AiN3E50AAQAA
X-Change-ID: 20260929-m3-plus-pmu-events-e4010ab44135
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3496;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=SHSP4+Stn2d9XSzlQdogEo8YrxiUT8uylUSvN+wOoCI=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zSfdpLNzJfKRKZJNE+hfGgrCygEpxle3J67uK/
 7k73Do21aWjlIVBjItBVkyRRd80TXsyW8Ol0mWuW2DmsDKBDGHg4hSAiUS7MzLcfhf/ziKT5dqX
 C4lL1OPmOjzxSD17eO/v32bu/2ayz2ayZWRYvn5vsnlHj6Tr2qWfGhfV/j3Nv6V6RsCkK3+fJNx
 7FdLOAwA9M0sY
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the CPU PMU in the new M3, M4 and A18 SoCs
presed in apple devices. These PMUs have new encodings for events, along
with larger codes for these events. All of these events are as Apple
describes them in the various kpep files found under /usr/share/kpep on
macOS 27. More events may exist, but we have no idea of their affinity,
or what they actually count, so we don't include them here.

These patches have been tested on my own M2 (t8133-j413) and M3
(t6031-j514c) devices, as well as by Yuvan on their M4 (t8132-j713)
device.

If possible, the device tree changes should probably go through
apple-soc, as this is where the recently picked up M4 Pro/Max dts are.

Tested-by: Yuvan Shen <yuvanshen09@gmail.com> # on t8132-j713
Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
Changes in v2:
- Remove extra cell in t6041 pmu interrupt specifications
- Add affinities for t603* and t8140 aic interrupts
- Make the a18 interrupts use the m4 function definitions directly
- Remove dead pmceid defines
- All changes address the sashiko feedback
- Link to v1: https://patch.msgid.link/20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com

To: Will Deacon <will@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Marc Zyngier <maz@kernel.org>
To: Sven Peter <sven@kernel.org>
To: Janne Grunau <j@jannau.net>
To: Neal Gompa <neal@gompa.dev>
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-perf-users@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: asahi@lists.linux.dev

---
Myria Sarvay (14):
      dt-bindings: arm: pmu: Add Apple M3/M4/A18 Pro SoC CPU PMU compatibles
      drivers/perf: apple_m1: Remove unused variables
      drivers/perf: apple_m1: Support per-implementation event size
      drivers/perf: apple_m1: Use macros for per-implementation init functions
      drivers/perf: apple_m1: Add Apple M3 Series Support
      drivers/perf: apple_m1: Add Apple M4 Series Support
      drivers/perf: apple_m1: Add Apple A18 Support
      arm64: dts: apple: t603*: Add core interrupt affinities
      arm64: dts: apple: t8140: Add core interrupt affinities
      arm64: dts: apple: t603x: Add PMU Device Nodes
      arm64: dts: apple: t8122: Add PMU Device Nodes
      arm64: dts: apple: t604x: Add PMU Device Nodes
      arm64: dts: apple: t8132: Add PMU Device Nodes
      arm64: dts: apple: t8140: Add PMU Device Nodes

Nick Chan (1):
      drivers/perf: apple_m1: Support per-implementation event tables

 Documentation/devicetree/bindings/arm/pmu.yaml |   8 +
 arch/arm64/boot/dts/apple/t6030.dtsi           |  26 +
 arch/arm64/boot/dts/apple/t6031-base.dtsi      |  12 +
 arch/arm64/boot/dts/apple/t6031.dtsi           |  18 +
 arch/arm64/boot/dts/apple/t6032.dtsi           |  20 +
 arch/arm64/boot/dts/apple/t6041.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8122.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8132.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8140.dtsi           |  25 +
 drivers/perf/apple_m1_cpu_pmu.c                | 654 +++++++++++++++++++++----
 10 files changed, 717 insertions(+), 82 deletions(-)
---
base-commit: 84a1163b0a3ec0acdda113d4c920ed72955dd6e8
change-id: 20260929-m3-plus-pmu-events-e4010ab44135

Best regards,
--  
Myria Sarvay <myrialsarvay@gmail.com>

