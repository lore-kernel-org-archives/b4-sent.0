From: Yang Xiwen <forbidden405@outlook.com>
Date: Fri, 23 Feb 2024 11:49:46 +0800
Subject: [PATCH 1/2] dt-bindings: simple-pm-bus: Add optional resets
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240223-b4-bus-v1-1-2803c3ac4673@outlook.com>
References: <20240223-b4-bus-v1-0-2803c3ac4673@outlook.com>
In-Reply-To: <20240223-b4-bus-v1-0-2803c3ac4673@outlook.com>
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Geert Uytterhoeven <geert+renesas@glider.be>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708660187; l=1458;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=eDExkZ8ch9F2IC6H0Bh6sbmnrZwqE83QU/hncSN1udA=;
 b=Ix+IGJnk37tLr6KiqN56bHt+twAmHGwLNjd3rCsPg1w/s3+c1zqNBQAm4VYR5tNYNB3gGUKd4
 lH6Meg3a0efD6SNUtc6v4IvRoM3GZA/sMRdx2ufsfbT63ahePugNiRL
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For some on-soc buses, it is also needed to deassert the resets before
access. Document it in the binding.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 Documentation/devicetree/bindings/bus/simple-pm-bus.yaml | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/Documentation/devicetree/bindings/bus/simple-pm-bus.yaml b/Documentation/devicetree/bindings/bus/simple-pm-bus.yaml
index 182134d7a6a3..430638104980 100644
--- a/Documentation/devicetree/bindings/bus/simple-pm-bus.yaml
+++ b/Documentation/devicetree/bindings/bus/simple-pm-bus.yaml
@@ -14,8 +14,9 @@ description: |
   driver, as it's typically initialized by the boot loader.
 
   However, its bus controller is part of a PM domain, or under the control
-  of a functional clock.  Hence, the bus controller's PM domain and/or
-  clock must be enabled for child devices connected to the bus (either
+  of a functional clock, and it might have a reset control signal.  Hence,
+  the bus controller's PM domain and/or clock must be enabled, reset control
+  signal must be deasserted for child devices connected to the bus (either
   on-SoC or externally) to function.
 
   While "simple-pm-bus" follows the "simple-bus" set of properties, as
@@ -49,6 +50,8 @@ properties:
     # Required if clocks is absent, optional otherwise
     minItems: 1
 
+  resets: true
+
 required:
   - compatible
   - '#address-cells'

-- 
2.43.0

