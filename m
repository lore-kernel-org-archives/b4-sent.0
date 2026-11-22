From: Michael Reeves <michael.reeves077@gmail.com>
Date: Sun, 22 Nov 2026 00:18:22 +0000
Subject: [PATCH v2 1/5] dt-bindings: cpufreq: apple,cluster-cpufreq: Add M3
 family compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-m3-cpufreq-opp-v2-1-3c19963f55ee@gmail.com>
References: <20261122-m3-cpufreq-opp-v2-0-3c19963f55ee@gmail.com>
In-Reply-To: <20261122-m3-cpufreq-opp-v2-0-3c19963f55ee@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795306712; l=1356;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=+HvmgCEavFBOajIqGH23VOYZLXgPd/UuvSVcHqeHPKw=;
 b=z7zddloP5EtRFMXyJY5E/A9JMBGgVglJHOLM/RajrTCnZGnaUnELqAyKW6QCNFMSGGsSeOZgc
 NnaUlAcaOpdA31VcpHe18Zo1yn03btSsZQKUSUQTAf3j0IXXXcTkCNf
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible strings for the Apple M3 family cluster cpufreq
controllers:

- apple,t8122-cluster-cpufreq (M3)
- apple,t6030-cluster-cpufreq (M3 Pro)
- apple,t6031-cluster-cpufreq (M3 Max / M3 Ultra)

All three are compatible with the M2 (T8112) cluster cpufreq controller
and fall back to "apple,t8112-cluster-cpufreq".

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 .../devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml          | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml b/Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
index b51913a81791..516216cb6ad6 100644
--- a/Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
+++ b/Documentation/devicetree/bindings/cpufreq/apple,cluster-cpufreq.yaml
@@ -36,7 +36,11 @@ properties:
           - const: apple,s5l8960x-cluster-cpufreq
       - const: apple,s5l8960x-cluster-cpufreq
       - items:
-          - const: apple,t6020-cluster-cpufreq
+          - enum:
+              - apple,t6020-cluster-cpufreq
+              - apple,t6030-cluster-cpufreq
+              - apple,t6031-cluster-cpufreq
+              - apple,t8122-cluster-cpufreq
           - const: apple,t8112-cluster-cpufreq
 
   reg:

-- 
2.56.0

