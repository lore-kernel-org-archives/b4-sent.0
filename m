From: Myria Sarvay <myrialsarvay@gmail.com>
Date: Sat, 07 Nov 2026 21:48:48 +1100
Subject: [PATCH v2 01/15] dt-bindings: arm: pmu: Add Apple M3/M4/A18 Pro
 SoC CPU PMU compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-m3-plus-pmu-events-v2-1-acf1e78da039@gmail.com>
References: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
In-Reply-To: <20261107-m3-plus-pmu-events-v2-0-acf1e78da039@gmail.com>
To: Will Deacon <will@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Marc Zyngier <maz@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-perf-users@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, Yuvan Shen <yuvanshen09@gmail.com>, 
 Myria Sarvay <myrialsarvay@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1325;
 i=myrialsarvay@gmail.com; h=from:subject:message-id;
 bh=/RhkmR+AowbpjqK6Gl7/U5BQw712i9wzEL0R+lg9Y7Q=;
 b=owJ4nJvAy8zAJRbk4iixYu2/l4yn1ZIYst4zSZ+Uebk/7p3ZeceHSsa//lU9z43fcJ1v292fi
 31YrE7y3FTvKGVhEONikBVTZNE3TdOezNZwqXSZ6xaYOaxMIEMYuDgFYCKp9xgZTnyaxXP8GO+k
 iD271BdNqpgx5dXxeoNPZ09HPn21w1KzUICR4fDV1VnRzjoLj7RtML0YtM07WoBbKjnk+/T5be8
 5065WMwIAEOlMFQ==
X-Developer-Key: i=myrialsarvay@gmail.com; a=openpgp;
 fpr=2F35662B930680D275A645B452444118A8ADFEE9
X-Endpoint-Received: by B4 Relay for myrialsarvay@gmail.com/default with auth_id=1027
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the compatibles for all current M3, M4 and A18 Pro SoC PMU
variants. Note that the M4+ are split out by chip codenames, instead of
name for the types of cores, as they no longer have individual names for
the performance and efficiency cores.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
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
2.55.0

