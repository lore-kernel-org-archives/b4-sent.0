From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Tue, 03 Nov 2026 21:14:36 +1100
Subject: [PATCH 01/13] dt-bindings: arm: pmu: Add Apple M3/M4/A18 Pro SoC
 CPU PMU compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-m3-plus-pmu-events-v1-1-a8eb6c1139fe@gmail.com>
References: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
In-Reply-To: <20261103-m3-plus-pmu-events-v1-0-a8eb6c1139fe@gmail.com>
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1255;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=j1e1lB3ujOCOFCosr6O6hKLnB66STlyve85ZT8PSD4A=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYsl5uEf7beptPf2reQX42teRrIqnXGV+rKHW+2WD95
 M8CI8E3YRM7SlkYxLgYZMUUWfRN07QnszVcKl3mugVmDisTyBAGLk4BmIjRDIa/Mn3Hsma/busv
 rHm2fonITqUT0WwHjx979ufPqf0K+3f26jH8D82afVrOTfDehyv7Dyp/tRZJ+fpWvkdJs+rven2
 VpefmMQAAsJ5OFQ==
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatibles for all current M3, M4 and A18 Pro SoC PMU
variants. Note that the M4+ are split out by chip codenames, instead of
name for the types of cores, as they no longer have individual names for
the performance and efficiency cores.

Signed-off-by: Myria Sarvay <myrialsarvay@gmail.com>
---
 Documentation/devicetree/bindings/arm/pmu.yaml | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/pmu.yaml b/Documentation/devicetree/bindings/arm/pmu.yaml
index f47baaefcdac..c27f06e82de1 100644
--- a/Documentation/devicetree/bindings/arm/pmu.yaml
+++ b/Documentation/devicetree/bindings/arm/pmu.yaml
@@ -22,8 +22,16 @@ properties:
           - apm,potenza-pmu
           - apple,avalanche-pmu
           - apple,blizzard-pmu
+          - apple,brava-e-pmu
+          - apple,brava-p-pmu
+          - apple,donan-e-pmu
+          - apple,donan-p-pmu
+          - apple,everest-pmu
           - apple,firestorm-pmu
           - apple,icestorm-pmu
+          - apple,sawtooth-pmu
+          - apple,tahiti-e-pmu
+          - apple,tahiti-p-pmu
           - arm,armv8-pmuv3 # Only for s/w models
           - arm,arm1136-pmu
           - arm,arm1176-pmu

-- 
2.56.0

