From: Myria Sarvay <myrialsarvay@gmail.com>
Subject: [PATCH 00/13] drivers/perf: apple_m1: Add M3/M4/A18 Pro Support
Date: Tue, 03 Nov 2026 21:14:35 +1100
Message-Id: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/y2NWw6CMBQFt0L6bZO+ad2K4aOPq9ZYwD6ICWHvo
 vg5yZw5KyqQIxR07laUYYklTuMO9NQhf7fjDXAMOyNGmCKGGZw4np+t4Dk1DAuMtWAQhBLrhKB
 con04Z7jG9y96GQ4uzT3A12/pb2R4tf2tHhpytgD2U0qxnjvrnWEyWGF0r6AXThPlfRDa9pLqw
 ALnSoMMaNi2DwaYU23CAAAA
X-Change-ID: 20260929-m3-plus-pmu-events-e4010ab44135
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>, Nick Chan <towinchenmi@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2375;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=sBJetOAUcs63xW7bNzY0oakU4G0NRaHuxPFAqWDArRM=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uET52a55/klOs9oXDF5qf2wV9WX5qpv+asleL3
 aZMZTloadPbUcrCIMbFICumyKJvmqY9ma3hUuky1y0wc1iZQIYwcHEKwEQCNzP8r670vBTLtyVN
 3XHPpJ9TxHakH68IW/2tvNnpsp9BnwjLRkaG873dGrdOWK1kO9A58Urb2f4Xn+5efD7/et1bjdQ
 DaRcWMgEAU69Pcw==
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
Myria Sarvay (12):
      dt-bindings: arm: pmu: Add Apple M3/M4/A18 Pro SoC CPU PMU compatibles
      drivers/perf: apple_m1: Remove unused variables
      drivers/perf: apple_m1: Support per-implementation event size
      drivers/perf: apple_m1: Use macros for per-implementation init functions
      drivers/perf: apple_m1: Add Apple M3 Series Support
      drivers/perf: apple_m1: Add Apple M4 Series Support
      drivers/perf: apple_m1: Add Apple A18 Support
      arm64: dts: apple: t603x: Add PMU Device Nodes
      arm64: dts: apple: t8122: Add PMU Device Nodes
      arm64: dts: apple: t604x: Add PMU Device Nodes
      arm64: dts: apple: t8132: Add PMU Device Nodes
      arm64: dts: apple: t8140: Add PMU Device Nodes

Nick Chan (1):
      drivers/perf: apple_m1: Support per-implementation event tables

 Documentation/devicetree/bindings/arm/pmu.yaml |   8 +
 arch/arm64/boot/dts/apple/t6030.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t6031-base.dtsi      |  12 +
 arch/arm64/boot/dts/apple/t6041.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8122.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8132.dtsi           |  12 +
 arch/arm64/boot/dts/apple/t8140.dtsi           |  12 +
 drivers/perf/apple_m1_cpu_pmu.c                | 664 ++++++++++++++++++++++---
 8 files changed, 662 insertions(+), 82 deletions(-)
---
base-commit: acb925da49876e74b806ccd48a7518d2d3368e5d
change-id: 20260929-m3-plus-pmu-events-e4010ab44135

Best regards,
--  
Myria Sarvay <myrialsarvay@gmail.com>

